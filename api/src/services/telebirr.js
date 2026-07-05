'use strict';

const crypto = require('crypto');
const https = require('https');
const { PrismaClient } = require('@prisma/client');
const { broadcastToBusiness } = require('./websocket');

const prisma = new PrismaClient();

// ── Plan prices ──────────────────────────────────────────────────────────────

const PLAN_PRICES = {
  STARTER:    { monthly: 199.00,  yearly: 1990.00,  monthsForYearly: 12 },
  BUSINESS:   { monthly: 499.00,  yearly: 4990.00,  monthsForYearly: 12 },
  ENTERPRISE: { monthly: 1200.00, yearly: 12000.00, monthsForYearly: 12 },
};

const TIER_CODES = { STARTER: 'STR', BUSINESS: 'BIZ', ENTERPRISE: 'ENT' };

// Fields excluded from signature (per TeleBirr spec)
const SIGN_EXCLUDE_FIELDS = ['sign', 'sign_type', 'header', 'refund_info', 'openType', 'raw_request', 'biz_content'];

// ═══════════════════════════════════════════════════════════════════════════════
// CRYPTO HELPERS (matching demo implementation)
// ═══════════════════════════════════════════════════════════════════════════════

/**
 * Sign a string using SHA256withRSAandMGF1 (RSA-PSS with SHA-256).
 * Matches the jsrsasign KJUR.crypto.Signature({ alg: "SHA256withRSAandMGF1" })
 * used in the official TeleBirr demo.
 */
function rsaSign(text, privateKeyPem) {
  const sign = crypto.createSign('RSA-SHA256');
  sign.update(text, 'utf8');
  return sign.sign({
    key: privateKeyPem,
    padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
    saltLength: crypto.constants.RSA_PSS_SALTLEN_DIGEST,
  }, 'base64');
}

/**
 * Verify RSA signature (for notify webhook).
 */
function rsaVerify(content, signature, publicKeyPem) {
  const verify = crypto.createVerify('RSA-SHA256');
  verify.update(content, 'utf8');
  return verify.verify({
    key: publicKeyPem,
    padding: crypto.constants.RSA_PKCS1_PSS_PADDING,
    saltLength: crypto.constants.RSA_PSS_SALTLEN_DIGEST,
  }, signature, 'base64');
}

/**
 * Sign a request object per TeleBirr spec:
 * 1. Collect all top-level fields (excluding sign/sign_type/biz_content)
 * 2. Flatten biz_content fields into the same pool (excluding same excluded keys)
 * 3. Sort field names alphabetically
 * 4. Join as key=value&key=value
 * 5. RSA-SHA256 sign the resulting string
 */
function signRequestObject(requestObject, privateKeyPem) {
  const fields = [];
  const fieldMap = {};

  // Top-level fields
  for (const key of Object.keys(requestObject)) {
    if (SIGN_EXCLUDE_FIELDS.includes(key)) continue;
    fields.push(key);
    fieldMap[key] = requestObject[key];
  }

  // biz_content fields (must participate in signature)
  if (requestObject.biz_content && typeof requestObject.biz_content === 'object') {
    for (const key of Object.keys(requestObject.biz_content)) {
      if (SIGN_EXCLUDE_FIELDS.includes(key)) continue;
      fields.push(key);
      fieldMap[key] = requestObject.biz_content[key];
    }
  }

  // Sort alphabetically
  fields.sort();

  // Build sign string
  const signStr = fields.map(k => `${k}=${fieldMap[k]}`).join('&');
  console.log('[TELEBIRR] Sign string:', signStr);

  return rsaSign(signStr, privateKeyPem);
}

// ── Helpers ──────────────────────────────────────────────────────────────────

function createTimestamp() {
  return Math.floor(Date.now() / 1000).toString();
}

function createNonceStr() {
  const chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
  let str = '';
  for (let i = 0; i < 32; i++) {
    str += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return str;
}

function createMerchantOrderId() {
  return Date.now().toString();
}

function parsePem(raw) {
  if (!raw) return null;
  return raw.replace(/\\n/g, '\n').trim();
}

function addMonths(date, months) {
  const result = new Date(date);
  result.setMonth(result.getMonth() + months);
  return result;
}

// ── HTTP POST helper ─────────────────────────────────────────────────────────

function httpPost(url, body, headers = {}) {
  return new Promise((resolve, reject) => {
    const urlObj = new URL(url);
    const postData = JSON.stringify(body);

    const options = {
      hostname: urlObj.hostname,
      port: urlObj.port,
      path: urlObj.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        ...headers,
      },
      rejectUnauthorized: false, // TeleBirr uses self-signed certs
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => data += chunk);
      res.on('end', () => {
        try {
          resolve(JSON.parse(data));
        } catch (e) {
          reject(new Error(`Failed to parse response: ${data}`));
        }
      });
    });

    req.on('error', reject);
    req.write(postData);
    req.end();
  });
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 1: Apply Fabric Token
// ═══════════════════════════════════════════════════════════════════════════════

async function applyFabricToken() {
  const baseUrl = process.env.TELEBIRR_BASE_URL;
  const fabricAppId = process.env.TELEBIRR_FABRIC_APP_ID;
  const appSecret = process.env.TELEBIRR_APP_SECRET;

  if (!baseUrl || !fabricAppId || !appSecret) {
    throw new Error('TeleBirr credentials not configured (BASE_URL, FABRIC_APP_ID, APP_SECRET)');
  }

  console.log('[TELEBIRR] Applying fabric token...');

  const result = await httpPost(
    `${baseUrl}/payment/v1/token`,
    { appSecret },
    { 'X-APP-Key': fabricAppId }
  );

  console.log('[TELEBIRR] Fabric token response:', JSON.stringify(result));

  if (!result.token) {
    throw new Error(`Failed to get fabric token: ${JSON.stringify(result)}`);
  }

  return result.token;
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 2: Auth Token (optional — for user-initiated payments)
// ═══════════════════════════════════════════════════════════════════════════════

async function requestAuthToken(fabricToken, appToken) {
  const baseUrl = process.env.TELEBIRR_BASE_URL;
  const fabricAppId = process.env.TELEBIRR_FABRIC_APP_ID;
  const merchantAppId = process.env.TELEBIRR_MERCHANT_APP_ID;
  const privateKey = parsePem(process.env.TELEBIRR_PRIVATE_KEY);

  const reqObject = {
    timestamp: createTimestamp(),
    method: 'payment.authtoken',
    nonce_str: createNonceStr(),
    version: '1.0',
    biz_content: {
      access_token: appToken,
      trade_type: 'InApp',
      appid: merchantAppId,
      resource_type: 'OpenId',
    },
  };

  reqObject.sign = signRequestObject(reqObject, privateKey);
  reqObject.sign_type = 'SHA256WithRSA';

  const result = await httpPost(
    `${baseUrl}/payment/v1/auth/authToken`,
    reqObject,
    {
      'X-APP-Key': fabricAppId,
      'Authorization': fabricToken,
    }
  );

  return result;
}

// ═══════════════════════════════════════════════════════════════════════════════
// STEP 3: Create Order (preOrder)
// ═══════════════════════════════════════════════════════════════════════════════

async function createTelebirrOrder({ businessId, tier, periodMonths, amount }) {
  const baseUrl = process.env.TELEBIRR_BASE_URL;
  const fabricAppId = process.env.TELEBIRR_FABRIC_APP_ID;
  const merchantAppId = process.env.TELEBIRR_MERCHANT_APP_ID;
  const merchantCode = process.env.TELEBIRR_MERCHANT_CODE;
  const notifyUrl = process.env.TELEBIRR_NOTIFY_URL;
  const privateKey = parsePem(process.env.TELEBIRR_PRIVATE_KEY);

  if (!baseUrl || !fabricAppId || !merchantAppId || !merchantCode || !privateKey) {
    throw new Error('TeleBirr credentials not configured');
  }

  // Step 1: Get fabric token
  const fabricToken = await applyFabricToken();

  // Generate unique merchant order ID
  const merchOrderId = createMerchantOrderId();

  // Build request object
  const reqObject = {
    timestamp: createTimestamp(),
    nonce_str: createNonceStr(),
    method: 'payment.preorder',
    version: '1.0',
    biz_content: {
      notify_url: notifyUrl,
      trade_type: 'InApp',
      appid: merchantAppId,
      merch_code: merchantCode,
      merch_order_id: merchOrderId,
      title: `PayVerify ${tier} Plan`,
      total_amount: Math.round(amount).toString(),
      trans_currency: 'ETB',
      timeout_express: '120m',
      payee_identifier: merchantCode,
      payee_identifier_type: '04',
      payee_type: '5000',
    },
  };

  // Sign the request
  reqObject.sign = signRequestObject(reqObject, privateKey);
  reqObject.sign_type = 'SHA256WithRSA';

  console.log('[TELEBIRR] Creating order:', JSON.stringify(reqObject, null, 2));

  // Send to TeleBirr
  const result = await httpPost(
    `${baseUrl}/payment/v1/merchant/preOrder`,
    reqObject,
    {
      'X-APP-Key': fabricAppId,
      'Authorization': fabricToken,
    }
  );

  console.log('[TELEBIRR] Order response:', JSON.stringify(result));

  // Check for error
  if (result.return_code !== 'SUCCESS' && !result.biz_content?.prepay_id) {
    throw new Error(`TeleBirr order failed: ${result.return_msg || JSON.stringify(result)}`);
  }

  const prepayId = result.biz_content.prepay_id;

  // Build raw request string for the TeleBirr SuperApp
  const rawRequest = createRawRequest(prepayId);
  console.log('[TELEBIRR] Raw request:', rawRequest);

  // Save order to database
  const order = await prisma.subscriptionOrder.create({
    data: {
      businessId,
      outTradeNo: merchOrderId,
      tier,
      periodMonths,
      amount,
      status: 'PENDING',
      toPayUrl: rawRequest, // Store raw request instead of URL
    },
  });

  return {
    outTradeNo: merchOrderId,
    rawRequest,
    prepayId,
    orderId: order.id,
  };
}

/**
 * Build the raw request string that gets sent to TeleBirr SuperApp.
 * Format: appid=X&merch_code=X&nonce_str=X&prepay_id=X&timestamp=X&sign=X&sign_type=SHA256WithRSA
 */
function createRawRequest(prepayId) {
  const merchantAppId = process.env.TELEBIRR_MERCHANT_APP_ID;
  const merchantCode = process.env.TELEBIRR_MERCHANT_CODE;
  const privateKey = parsePem(process.env.TELEBIRR_PRIVATE_KEY);

  const map = {
    appid: merchantAppId,
    merch_code: merchantCode,
    nonce_str: createNonceStr(),
    prepay_id: prepayId,
    timestamp: createTimestamp(),
  };

  const sign = signRequestObject(map, privateKey);

  const rawRequest = [
    `appid=${map.appid}`,
    `merch_code=${map.merch_code}`,
    `nonce_str=${map.nonce_str}`,
    `prepay_id=${map.prepay_id}`,
    `timestamp=${map.timestamp}`,
    `sign=${sign}`,
    `sign_type=SHA256WithRSA`,
  ].join('&');

  return rawRequest;
}

// ═══════════════════════════════════════════════════════════════════════════════
// NOTIFY WEBHOOK
// ═══════════════════════════════════════════════════════════════════════════════

function buildNotifyVerifyContent(payload) {
  return Object.keys(payload)
    .filter(k => k !== 'sign' && payload[k] !== null && payload[k] !== undefined && payload[k] !== '')
    .sort()
    .map(k => `${k}=${payload[k]}`)
    .join('&');
}

async function handleNotify(payload) {
  console.log('[TELEBIRR] Notify received:', JSON.stringify(payload));

  const { out_trade_no, trade_no, total_amount, trade_status, sign } = payload;

  // Find order
  const order = await prisma.subscriptionOrder.findUnique({
    where: { outTradeNo: out_trade_no },
  });

  if (!order) {
    console.error(`[TELEBIRR] Order not found: ${out_trade_no}`);
    return { return_code: 'FAIL', return_msg: 'Order not found' };
  }

  // Idempotency
  if (order.status === 'PAID') {
    console.log(`[TELEBIRR] Order ${out_trade_no} already PAID`);
    return { return_code: 'SUCCESS', return_msg: 'success' };
  }

  // Verify amount
  const expectedAmount = Number(order.amount);
  const receivedAmount = parseFloat(total_amount);
  if (Math.abs(expectedAmount - receivedAmount) > 0.01) {
    console.error(`[TELEBIRR] Amount mismatch: expected ${expectedAmount}, got ${receivedAmount}`);
    await prisma.subscriptionOrder.update({
      where: { outTradeNo: out_trade_no },
      data: { status: 'FAILED', notifyPayload: JSON.stringify(payload) },
    });
    return { return_code: 'FAIL', return_msg: 'Amount mismatch' };
  }

  // Check trade status
  if (trade_status !== 'TRADE_SUCCESS') {
    console.log(`[TELEBIRR] Trade not successful: ${trade_status}`);
    await prisma.subscriptionOrder.update({
      where: { outTradeNo: out_trade_no },
      data: { status: 'FAILED', tradeNo: trade_no, notifyPayload: JSON.stringify(payload) },
    });
    return { return_code: 'SUCCESS', return_msg: 'success' };
  }

  // Mark PAID
  const now = new Date();
  await prisma.subscriptionOrder.update({
    where: { outTradeNo: out_trade_no },
    data: {
      status: 'PAID',
      tradeNo: trade_no,
      paidAt: now,
      notifyPayload: JSON.stringify(payload),
    },
  });

  // Activate subscription
  await activateSubscription(order.businessId, order.tier, order.periodMonths);

  console.log(`[TELEBIRR] Order ${out_trade_no} PAID. Subscription activated.`);
  return { return_code: 'SUCCESS', return_msg: 'success' };
}

// ═══════════════════════════════════════════════════════════════════════════════
// SUBSCRIPTION ACTIVATION
// ═══════════════════════════════════════════════════════════════════════════════

async function activateSubscription(businessId, tier, periodMonths) {
  const now = new Date();

  const result = await prisma.$transaction(async (tx) => {
    const biz = await tx.business.findUnique({ where: { id: businessId } });

    let startDate = now;
    if (biz.subscriptionStatus === 'ACTIVE' && biz.subscriptionEndsAt) {
      startDate = biz.subscriptionEndsAt > now ? biz.subscriptionEndsAt : now;
    } else if (biz.subscriptionStatus === 'GRACE' && biz.subscriptionEndsAt) {
      startDate = biz.subscriptionEndsAt;
    }

    const newEndsAt = addMonths(startDate, periodMonths);

    await tx.business.update({
      where: { id: businessId },
      data: {
        subscriptionStatus: 'ACTIVE',
        subscriptionTier: tier,
        subscriptionEndsAt: newEndsAt,
        graceEndsAt: null,
      },
    });

    return { newEndsAt, tier };
  });

  // Create SubscriptionPayment record
  const order = await prisma.subscriptionOrder.findFirst({
    where: { businessId, tier, status: 'PAID' },
    orderBy: { createdAt: 'desc' },
  });

  if (order) {
    await prisma.subscriptionPayment.create({
      data: {
        businessId,
        transactionId: order.outTradeNo,
        amount: order.amount,
        tier,
        periodMonths,
        paidAt: now,
        verifiedAt: now,
      },
    });
  }

  // Broadcast WebSocket event
  try {
    broadcastToBusiness(businessId, {
      type: 'subscription_activated',
      tier,
      endsAt: result.newEndsAt.toISOString(),
      message: 'Subscription activated!',
    });
  } catch (_) {}

  return result;
}

function getPlanAmount(tier, periodMonths) {
  const plan = PLAN_PRICES[tier];
  if (!plan) return null;
  if (periodMonths === 12) return plan.yearly;
  return plan.monthly * periodMonths;
}

module.exports = {
  applyFabricToken,
  createOrder: createTelebirrOrder,
  handleNotify,
  activateSubscription,
  getPlanAmount,
  createRawRequest,
  PLAN_PRICES,
  TIER_CODES,
};
