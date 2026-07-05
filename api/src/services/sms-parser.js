'use strict';

/**
 * Parses raw SMS text from Ethiopian banks into structured transaction data.
 * Mirrors the Flutter SmsParser — keeps client and server in sync.
 */

const METHODS = {
  TELEBIRR:  'TeleBirr',
  CBE:       'CBE',
  AWASH:     'Awash',
  DASHEN:    'Dashen',
  ABYSSINIA: 'Abyssinia',
  AMOLE:     'Amole',
  HELLOCASH: 'HelloCash',
};

function detectMethod(address = '', body = '') {
  const a = address.toLowerCase();
  const b = body.toLowerCase();
  if (a.includes('telebirr') || b.includes('telebirr'))          return METHODS.TELEBIRR;
  if (a === '841' || b.includes('commercial bank') || b.includes('cbe')) return METHODS.CBE;
  if (a.includes('awash') || b.includes('awash bank'))           return METHODS.AWASH;
  if (a.includes('dashen') || b.includes('dashen bank'))         return METHODS.DASHEN;
  if (a.includes('amole') || b.includes('amole'))                return METHODS.AMOLE;
  if (a.includes('hellocash') || b.includes('hellocash'))        return METHODS.HELLOCASH;
  if (a.includes('abyssinia') || b.includes('bank of abyssinia') || b.includes('boa'))
    return METHODS.ABYSSINIA;
  return null;
}

function parseAmount(raw) {
  return parseFloat(raw.replace(/,/g, '')) || 0;
}

// ── TeleBirr ─────────────────────────────────────────────────────────────────
// "You have received ETB 1,250.00 from 0912345678 (Abebe Bekele). Ref: TLB20260628884201."
function parseTeleBirr(body) {
  const amountMatch = body.match(/received\s+ETB\s+([\d,]+\.?\d*)/i);
  const refMatch    = body.match(/[Rr]ef[:\s]+([A-Z0-9]{8,20})/);
  const phoneMatch  = body.match(/from\s+(09\d{8}|\+2519\d{8})/);
  const nameMatch   = body.match(/\(([^)]+)\)/);
  if (!amountMatch || !refMatch) return null;
  return {
    transactionId: refMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   phoneMatch?.[1] ?? '',
    senderName:    nameMatch?.[1] ?? 'Unknown',
    paymentMethod: METHODS.TELEBIRR,
  };
}

// ── CBE (sender: 841) ─────────────────────────────────────────────────────────
// "Cr ETB1,500.00 A/C No XXXX1234 Date 28/06/26 Desc: Transfer from DAWIT KEBEDE Ref No:CBE2026062812345"
function parseCbe(body) {
  const amountMatch = body.match(/Cr\s*ETB\s*([\d,]+\.?\d*)/i);
  const refMatch    = body.match(/[Rr]ef\s*[Nn]o[:\s]*([A-Z0-9]{6,20})/);
  const nameMatch   = body.match(/(?:Transfer from|from)\s+([A-Z][A-Z\s]+?)(?:\s+Ref|\s+A\/C|$)/);
  if (!amountMatch || !refMatch) return null;
  return {
    transactionId: refMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   '',
    senderName:    nameMatch?.[1]?.trim() ?? 'CBE Customer',
    paymentMethod: METHODS.CBE,
  };
}

// ── Awash Bank ────────────────────────────────────────────────────────────────
// "Dear Customer, ETB 2,000.00 has been credited. Sender: Sara Tesfaye (0923456789). TxnID: AWB20260628556677"
function parseAwash(body) {
  const amountMatch = body.match(/ETB\s*([\d,]+\.?\d*)\s+has been credited/i);
  const txnMatch    = body.match(/TxnID[:\s]+([A-Z0-9]+)/i);
  const senderMatch = body.match(/Sender[:\s]+([^(]+)\s*\(?(\d{10,13})?\)?/i);
  if (!amountMatch || !txnMatch) return null;
  return {
    transactionId: txnMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   senderMatch?.[2] ?? '',
    senderName:    senderMatch?.[1]?.trim() ?? 'Awash Customer',
    paymentMethod: METHODS.AWASH,
  };
}

// ── Dashen / Amole ────────────────────────────────────────────────────────────
function parseDashen(body, method = METHODS.DASHEN) {
  const amountMatch = body.match(/(?:credited|received)\s*(?:with)?\s*ETB\s*([\d,]+\.?\d*)/i);
  const refMatch    = body.match(/[Tt]x(?:n)?[Ii][Dd]?[:\s]+([A-Z0-9]+)/);
  if (!amountMatch || !refMatch) return null;
  return {
    transactionId: refMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   '',
    senderName:    method === METHODS.AMOLE ? 'Amole User' : 'Dashen Customer',
    paymentMethod: method,
  };
}

// ── HelloCash ─────────────────────────────────────────────────────────────────
function parseHelloCash(body) {
  const amountMatch = body.match(/ETB\s*([\d,]+\.?\d*)/i);
  const refMatch    = body.match(/[Tt]x[:\s]+([A-Z0-9]{6,20})/);
  if (!amountMatch || !refMatch) return null;
  return {
    transactionId: refMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   '',
    senderName:    'HelloCash User',
    paymentMethod: METHODS.HELLOCASH,
  };
}

// ── Generic fallback ──────────────────────────────────────────────────────────
function parseGeneric(body, method) {
  const amountMatch = body.match(/ETB\s*([\d,]+\.?\d*)/i);
  const refMatch    = body.match(/[Rr]ef[:\s]+([A-Z0-9]{6,20})/);
  if (!amountMatch || !refMatch) return null;
  return {
    transactionId: refMatch[1].trim(),
    amount:        parseAmount(amountMatch[1]),
    senderPhone:   '',
    senderName:    'Unknown',
    paymentMethod: method,
  };
}

// ── Master parse function ─────────────────────────────────────────────────────
function parseSms(body, senderAddress = '') {
  const method = detectMethod(senderAddress, body);
  if (!method) return null;

  switch (method) {
    case METHODS.TELEBIRR:  return parseTeleBirr(body);
    case METHODS.CBE:       return parseCbe(body);
    case METHODS.AWASH:     return parseAwash(body);
    case METHODS.DASHEN:    return parseDashen(body, METHODS.DASHEN);
    case METHODS.AMOLE:     return parseDashen(body, METHODS.AMOLE);
    case METHODS.HELLOCASH: return parseHelloCash(body);
    default:                return parseGeneric(body, method);
  }
}

module.exports = { parseSms, METHODS };
