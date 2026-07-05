import 'package:hive_flutter/hive_flutter.dart';
import '../../models/transaction.dart';
import '../../models/user.dart';

class LocalDb {
  static const _txBox   = 'transactions';
  static const _authBox = 'auth';

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter()); // generated via build_runner
    await Hive.openBox<Map>(_txBox);
    await Hive.openBox<String>(_authBox);
  }

  // ─── Transactions ────────────────────────────────────────────────

  Box<Map> get _tx => Hive.box<Map>(_txBox);

  Future<void> saveTransaction(Transaction t) async {
    await _tx.put(t.transactionId, t.toJson().cast<String, dynamic>());
  }

  Future<void> saveTransactions(List<Transaction> list) async {
    final map = {for (var t in list) t.transactionId: t.toJson()};
    await _tx.putAll(map.cast<String, Map>());
  }

  List<Transaction> getTransactions({String? businessId, int limit = 100}) {
    final all = _tx.values
        .map((v) => Transaction.fromJson(Map<String, dynamic>.from(v)))
        .where((t) => businessId == null || t.businessId == businessId)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return all.take(limit).toList();
  }

  Transaction? getByTxId(String txId) {
    final raw = _tx.get(txId);
    if (raw == null) return null;
    return Transaction.fromJson(Map<String, dynamic>.from(raw));
  }

  Future<void> updateStatus(String txId, String status) async {
    final existing = getByTxId(txId);
    if (existing == null) return;
    await saveTransaction(existing.copyWith(status: status));
  }

  Future<void> clearOldTransactions({int keepDays = 30}) async {
    final cutoff = DateTime.now().subtract(Duration(days: keepDays));
    final toDelete = _tx.values
        .map((v) => Transaction.fromJson(Map<String, dynamic>.from(v)))
        .where((t) => t.timestamp.isBefore(cutoff))
        .map((t) => t.transactionId)
        .toList();
    await _tx.deleteAll(toDelete);
  }

  Map<String, dynamic> getDailySummary(String businessId) {
    final today = DateTime.now();
    final txs = getTransactions(businessId: businessId).where((t) =>
        t.timestamp.year == today.year &&
        t.timestamp.month == today.month &&
        t.timestamp.day == today.day);

    final verified = txs.where((t) => t.status == TxStatus.verified).toList();
    final mismatch = txs.where((t) => t.status == TxStatus.mismatch).toList();

    return {
      'total':       txs.length,
      'verified':    verified.length,
      'mismatch':    mismatch.length,
      'totalAmount': verified.fold(0.0, (sum, t) => sum + t.amount),
    };
  }

  // ─── Auth / Session ──────────────────────────────────────────────

  Box<String> get _auth => Hive.box<String>(_authBox);

  Future<void> saveToken(String token) => _auth.put('token', token);
  String? getToken() => _auth.get('token');
  Future<void> clearToken() => _auth.delete('token');

  Future<void> saveUser(AppUser user) async {
    await _auth.put('user_id',       user.id);
    await _auth.put('user_name',     user.name);
    await _auth.put('user_phone',    user.phone);
    await _auth.put('user_role',     user.role);
    await _auth.put('business_id',   user.businessId);
    await _auth.put('business_name', user.businessName);
  }

  AppUser? getUser() {
    final id = _auth.get('user_id');
    if (id == null) return null;
    return AppUser(
      id:           id,
      name:         _auth.get('user_name') ?? '',
      phone:        _auth.get('user_phone') ?? '',
      role:         _auth.get('user_role') ?? 'CASHIER',
      businessId:   _auth.get('business_id') ?? '',
      businessName: _auth.get('business_name') ?? '',
    );
  }

  Future<void> logout() async {
    await _auth.clear();
  }
}

final localDb = LocalDb();
