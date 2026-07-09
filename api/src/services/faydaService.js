'use strict';

/**
 * Mock Fayda (Ethiopian National Digital ID) Registry Service
 *
 * In production, this would call the real Fayda ID data-pull API.
 * For now, it returns a hardcoded test identity for any valid-looking FIN/FAN.
 */

const TEST_IDENTITIES = {
  'FAYDA-001': { name: 'Abebe Kebede Tessema',  phone: '+251911234567' },
  'FAYDA-002': { name: 'Hiwot Tadesse Bekele',  phone: '+251922334455' },
  'FAYDA-003': { name: 'Dawit Solomon Getachew', phone: '+251933445566' },
};

const DEFAULT_IDENTITY = { name: 'Abebe Kebede Tessema', phone: '+251911234567' };

/**
 * Looks up a Fayda ID (FIN/FAN) and returns the associated identity data.
 *
 * @param {string} faydaId - The Fayda ID number (FIN or FAN)
 * @returns {{ name: string, phone: string }} The identity data
 * @throws {Error} If the Fayda ID is invalid or not found
 */
async function mockFaydaRegistryLookup(faydaId) {
  if (!faydaId || typeof faydaId !== 'string') {
    throw new Error('Fayda ID is required');
  }

  const normalized = faydaId.trim().toUpperCase();

  // Simulate network latency (100-300ms)
  await new Promise((resolve) => setTimeout(resolve, 100 + Math.random() * 200));

  // Return test identity if registered, otherwise return default
  const identity = TEST_IDENTITIES[normalized] || DEFAULT_IDENTITY;

  return {
    name: identity.name,
    phone: identity.phone,
  };
}

module.exports = { mockFaydaRegistryLookup };
