import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../models/user.dart';
import '../services/api/api_client.dart';
import '../services/local_db/local_db.dart';

// ─── Auth ────────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AsyncValue<AppUser?>>(
  (ref) => AuthNotifier(),
);

class AuthNotifier extends StateNotifier<AsyncValue<AppUser?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _loadCached();
  }

  void _loadCached() {
    final user = localDb.getUser();
    final token = localDb.getToken();
    state = AsyncValue.data(token != null ? user : null);
  }

  Future<void> login(String phone, String password) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.login(phone, password));
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String businessName,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.registerOwner(
          name: name,
          phone: phone,
          password: password,
          businessName: businessName,
        ));
  }

  Future<void> joinWithCode({
    required String code,
    required String name,
    required String phone,
    required String password,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => api.joinWithCode(
          inviteCode: code,
          name: name,
          phone: phone,
          password: password,
        ));
  }

  Future<void> logout() async {
    await localDb.logout();
    state = const AsyncValue.data(null);
  }
}

// ─── Transactions ────────────────────────────────────────────────────────────

final transactionsProvider =
    StateNotifierProvider<TransactionNotifier, AsyncValue<List<Transaction>>>(
  (ref) => TransactionNotifier(),
);

class TransactionNotifier
    extends StateNotifier<AsyncValue<List<Transaction>>> {
  TransactionNotifier() : super(const AsyncValue.loading()) {
    _loadLocal();
  }

  void _loadLocal() {
    final user = localDb.getUser();
    final txs = localDb.getTransactions(businessId: user?.businessId);
    state = AsyncValue.data(txs);
  }

  Future<void> sync() async {
    state = await AsyncValue.guard(() => api.syncTransactions());
  }

  Future<Transaction> verify(String referenceCode) async {
    final tx = await api.verifyTransaction(referenceCode);
    _loadLocal(); // refresh list
    return tx;
  }

  void addFromSms(Transaction tx) {
    localDb.saveTransaction(tx);
    _loadLocal();
  }
}

// ─── Verify state ────────────────────────────────────────────────────────────

enum VerifyState { idle, scanning, processing, success, error }

class VerifyResult {
  final VerifyState state;
  final Transaction? transaction;
  final String? errorMessage;

  const VerifyResult({
    required this.state,
    this.transaction,
    this.errorMessage,
  });

  const VerifyResult.idle()   : this(state: VerifyState.idle);
  const VerifyResult.loading(): this(state: VerifyState.processing);
}

final verifyProvider =
    StateNotifierProvider<VerifyNotifier, VerifyResult>(
  (ref) => VerifyNotifier(ref.read(transactionsProvider.notifier)),
);

class VerifyNotifier extends StateNotifier<VerifyResult> {
  final TransactionNotifier _txNotifier;
  VerifyNotifier(this._txNotifier) : super(const VerifyResult.idle());

  Future<void> verify(String referenceCode) async {
    if (referenceCode.trim().isEmpty) return;
    state = const VerifyResult.loading();
    try {
      final tx = await _txNotifier.verify(referenceCode.trim());
      state = VerifyResult(state: VerifyState.success, transaction: tx);
    } catch (e) {
      state = VerifyResult(
        state: VerifyState.error,
        errorMessage: _friendlyError(e),
      );
    }
  }

  void reset() => state = const VerifyResult.idle();

  String _friendlyError(Object e) {
    // ApiException already contains a user-friendly message
    if (e is ApiException) return e.message;
    final msg = e.toString().toLowerCase();
    if (msg.contains('not found'))   return 'Transaction not found. Check the reference code.';
    if (msg.contains('expired'))     return 'This transaction has expired.';
    if (msg.contains('already'))     return 'This payment was already verified.';
    if (msg.contains('network') || msg.contains('socket'))
      return 'No internet. Check your connection and try again.';
    return 'Verification failed. Please try again.';
  }
}

// ─── Workers ─────────────────────────────────────────────────────────────────

final workersProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) => api.getWorkers());

final inviteCodeProvider = FutureProvider<String>(
  (ref) => api.generateInviteCode(),
);
