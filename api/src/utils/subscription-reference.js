'use strict';

/**
 * Subscription reference code utilities.
 * Format: PV-{last 6 chars of businessId uppercase}-{STR|BIZ|ENT}
 * Example: PV-A3F9C2-STR
 */

const TIER_CODES = {
  STARTER:   'STR',
  BUSINESS:  'BIZ',
  ENTERPRISE: 'ENT',
};

const TIER_FROM_CODE = Object.fromEntries(
  Object.entries(TIER_CODES).map(([k, v]) => [v, k])
);

const AMOUNT_MAP = {
  STR: { 199: 1, 398: 2, 597: 3, 1990: 12 },
  BIZ: { 499: 1, 998: 2, 4990: 12 },
  ENT: { 1200: 1, 2400: 2, 12000: 12 },
};

function generateReferenceCode(businessId, tier) {
  const suffix = businessId.replace(/-/g, '').slice(-6).toUpperCase();
  const code = TIER_CODES[tier];
  return `PV-${suffix}-${code}`;
}

function parseReferenceCode(text) {
  const match = text.match(/PV-([A-Z0-9]{6})-(STR|BIZ|ENT)/);
  if (!match) return null;
  return {
    businessSuffix: match[1],
    tierCode: match[2],
    tier: TIER_FROM_CODE[match[2]],
  };
}

function resolveTierAndMonths(amount) {
  const amt = Math.round(amount);
  for (const [tierCode, amounts] of Object.entries(AMOUNT_MAP)) {
    if (amounts[amt] !== undefined) {
      return { tier: TIER_FROM_CODE[tierCode], months: amounts[amt] };
    }
  }
  return null;
}

module.exports = {
  generateReferenceCode,
  parseReferenceCode,
  resolveTierAndMonths,
  TIER_CODES,
  TIER_FROM_CODE,
  AMOUNT_MAP,
};
