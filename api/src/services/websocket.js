'use strict';

const { WebSocketServer } = require('ws');
const jwt = require('jsonwebtoken');
const { URL } = require('url');

const JWT_SECRET = process.env.JWT_SECRET || 'change-this-in-production';

// Map of businessId → Set of connected WebSocket clients
const businessRooms = new Map();

function setupWebSocket(server) {
  const wss = new WebSocketServer({ server, path: '/ws' });

  wss.on('connection', (ws, req) => {
    // Parse token + businessId from query string
    // e.g. /ws?token=xxx&businessId=yyy
    let clientMeta = null;

    try {
      const url = new URL(req.url, `http://${req.headers.host}`);
      const token      = url.searchParams.get('token');
      const businessId = url.searchParams.get('businessId');

      if (!token || !businessId) {
        ws.close(1008, 'Missing token or businessId');
        return;
      }

      const payload = jwt.verify(token, JWT_SECRET);
      if (payload.businessId !== businessId) {
        ws.close(1008, 'Token businessId mismatch');
        return;
      }

      clientMeta = { userId: payload.userId, businessId, role: payload.role };

      // Add to business room
      if (!businessRooms.has(businessId)) {
        businessRooms.set(businessId, new Set());
      }
      businessRooms.get(businessId).add(ws);

      console.log(`[WS] Client connected: ${clientMeta.userId} → room ${businessId} (${businessRooms.get(businessId).size} clients)`);

      send(ws, { type: 'connected', message: 'PayVerify real-time active' });
    } catch (err) {
      console.error('[WS] Auth failed:', err.message);
      ws.close(1008, 'Unauthorized');
      return;
    }

    // ── Incoming messages from client ───────────────────────────────
    ws.on('message', (raw) => {
      try {
        const data = JSON.parse(raw.toString());
        if (data.type === 'ping') {
          send(ws, { type: 'pong' });
        }
      } catch (_) {}
    });

    // ── Cleanup on disconnect ────────────────────────────────────────
    ws.on('close', () => {
      if (clientMeta) {
        const room = businessRooms.get(clientMeta.businessId);
        if (room) {
          room.delete(ws);
          if (room.size === 0) businessRooms.delete(clientMeta.businessId);
        }
        console.log(`[WS] Client disconnected: ${clientMeta.userId}`);
      }
    });

    ws.on('error', (err) => {
      console.error('[WS] Socket error:', err.message);
    });
  });

  console.log('[WS] WebSocket server ready');
}

// ── Push helpers (called by route handlers) ───────────────────────────────────

/**
 * Broadcast a new PENDING transaction to all cashiers in the business room.
 * Called when a bank SMS arrives via Africa's Talking webhook or Android forwarder.
 */
function broadcastNewTransaction(businessId, transaction) {
  broadcast(businessId, {
    type: 'new_transaction',
    transaction,
  });
}

/**
 * Broadcast a status change (PENDING → VERIFIED) to all clients in the room.
 * Called after a cashier successfully verifies a payment.
 */
function broadcastStatusUpdate(businessId, transactionId, status) {
  broadcast(businessId, {
    type: 'status_update',
    transactionId,
    status,
  });
}

function broadcast(businessId, payload) {
  const room = businessRooms.get(businessId);
  if (!room || room.size === 0) return;

  const msg = JSON.stringify(payload);
  for (const client of room) {
    if (client.readyState === 1 /* OPEN */) {
      client.send(msg);
    }
  }
}

function send(ws, payload) {
  if (ws.readyState === 1) {
    ws.send(JSON.stringify(payload));
  }
}

function broadcastToBusiness(businessId, payload) {
  broadcast(businessId, payload);
}

module.exports = { setupWebSocket, broadcastNewTransaction, broadcastStatusUpdate, broadcastToBusiness };
