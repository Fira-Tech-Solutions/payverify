import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../local_db/local_db.dart';
import '../../models/transaction.dart';
import '../../models/user.dart';
import '../../models/subscription.dart';

/// User-friendly API exception with a message safe to display in UI.
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  ApiException(this.message, {this.statusCode});
  @override
  String toString() => message;
}

class ApiClient {
  static const _baseUrl = 'http://192.168.100.131:3000/v1'; // your backend URL

  late final Dio _dio;

  /// Called when a 401 is received — allows the app to force logout
  VoidCallback? onAuthExpired;

  ApiClient() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));

    // Auth interceptor — attach JWT token to every request
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = localDb.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        debugPrint('[API] Error: ${error.response?.statusCode} ${error.message}');
        // Auto-logout on 401 — token is invalid/expired/user deleted
        if (error.response?.statusCode == 401) {
          localDb.clearToken();
          localDb.logout();
          onAuthExpired?.call();
        }
        handler.next(error);
      },
    ));
  }

  /// Converts any DioException into a user-safe [ApiException].
  Never _handleError(DioException e) {
    throw _mapDioError(e);
  }

  static ApiException _mapDioError(DioException e) {
    // ── No connection / timeout ──────────────────────────────────────
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return ApiException('Connection timed out. Check your internet and try again.');
    }
    if (e.type == DioExceptionType.connectionError ||
        e.error is Exception && e.error.toString().contains('SocketException')) {
      return ApiException('No internet connection. Check your network and try again.');
    }
    if (e.type == DioExceptionType.cancel) {
      return ApiException('Request was cancelled.');
    }

    // ── Server responded with an HTTP status code ────────────────────
    final statusCode = e.response?.statusCode;
    final body = e.response?.data;

    // Try to extract server error message
    String? serverMessage;
    if (body is Map<String, dynamic>) {
      serverMessage = body['error'] as String? ??
          body['message'] as String? ??
          body['detail'] as String?;
      // Fall back to details array if error is generic
      if (serverMessage == null && body['details'] is List) {
        serverMessage = (body['details'] as List).join('. ');
      }
    }

    switch (statusCode) {
      case 400:
        return ApiException(serverMessage ?? 'Invalid request. Please check your input.', statusCode: 400);
      case 401:
        return ApiException('Session expired. Please sign in again.', statusCode: 401);
      case 403:
        return ApiException('You don\'t have permission for this action.', statusCode: 403);
      case 404:
        return ApiException(serverMessage ?? 'Not found. The resource doesn\'t exist.', statusCode: 404);
      case 409:
        return ApiException(serverMessage ?? 'Conflict. This action was already done.', statusCode: 409);
      case 410:
        return ApiException(serverMessage ?? 'This offer has expired. Please refresh and try again.', statusCode: 410);
      case 422:
        return ApiException(serverMessage ?? 'Invalid data. Please check your input.', statusCode: 422);
      case 429:
        return ApiException('Too many requests. Wait a moment and try again.', statusCode: 429);
      case 500:
        return ApiException('Server error. Please try again later.', statusCode: 500);
      case 502:
      case 503:
        return ApiException('Service temporarily unavailable. Please try again later.', statusCode: statusCode);
      default:
        if (statusCode != null && statusCode >= 400) {
          return ApiException(
            serverMessage ?? 'Something went wrong (error $statusCode).',
            statusCode: statusCode,
          );
        }
    }

    // ── Fallback ─────────────────────────────────────────────────────
    return ApiException('Something went wrong. Please try again.');
  }

  // ─── Auth ────────────────────────────────────────────────────────

  Future<AppUser> login(String phone, String password) async {
    try {
      final res = await _dio.post('/auth/login', data: {
        'phone':    phone,
        'password': password,
      });
      final user = AppUser.fromJson({
        ...res.data['user'],
        'token': res.data['token'],
      });
      await localDb.saveToken(res.data['token']);
      await localDb.saveUser(user);
      return user;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<AppUser> registerOwner({
    required String name,
    required String phone,
    required String password,
    required String businessName,
  }) async {
    try {
      final res = await _dio.post('/auth/register', data: {
        'name':         name,
        'phone':        phone,
        'password':     password,
        'businessName': businessName,
      });
      final user = AppUser.fromJson({
        ...res.data['user'],
        'token': res.data['token'],
      });
      await localDb.saveToken(res.data['token']);
      await localDb.saveUser(user);
      return user;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Worker joins using 6-char invite code generated by owner
  Future<AppUser> joinWithCode({
    required String inviteCode,
    required String name,
    required String phone,
    required String password,
  }) async {
    try {
      final res = await _dio.post('/auth/join', data: {
        'inviteCode': inviteCode,
        'name':       name,
        'phone':      phone,
        'password':   password,
      });
      final user = AppUser.fromJson({
        ...res.data['user'],
        'token': res.data['token'],
      });
      await localDb.saveToken(res.data['token']);
      await localDb.saveUser(user);
      return user;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<String> updateBusinessName(String businessName) async {
    try {
      final res = await _dio.patch('/auth/business-name', data: {
        'businessName': businessName,
      });
      final user = localDb.getUser();
      if (user != null) {
        final updated = AppUser(
          id: user.id,
          name: user.name,
          phone: user.phone,
          role: user.role,
          businessId: user.businessId,
          businessName: res.data['businessName'],
          token: user.token,
        );
        await localDb.saveUser(updated);
      }
      return res.data['businessName'];
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Verify ──────────────────────────────────────────────────────

  /// Core verification: send tx reference → get VERIFIED / MISMATCH / PENDING
  Future<Transaction> verifyTransaction(String referenceCode) async {
    try {
      final user = localDb.getUser();
      final res = await _dio.post('/verify', data: {
        'referenceCode': referenceCode,
        'businessId':    user?.businessId,
        'workerId':      user?.id,
      });
      final tx = Transaction.fromJson(res.data['transaction']);
      await localDb.saveTransaction(tx);
      return tx;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  /// Sync pending transactions from server (for offline recovery)
  Future<List<Transaction>> syncTransactions() async {
    try {
      final user = localDb.getUser();
      final res = await _dio.get('/transactions', queryParameters: {
        'businessId': user?.businessId,
        'limit':      50,
      });
      final list = (res.data['transactions'] as List)
          .map((j) => Transaction.fromJson(j))
          .toList();
      await localDb.saveTransactions(list);
      return list;
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Workers ─────────────────────────────────────────────────────

  Future<String> generateInviteCode() async {
    try {
      final res = await _dio.post('/workers/invite');
      return res.data['code'];
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<Map<String, dynamic>>> getWorkers() async {
    try {
      final user = localDb.getUser();
      final res = await _dio.get('/workers', queryParameters: {
        'businessId': user?.businessId,
      });
      return List<Map<String, dynamic>>.from(res.data['workers']);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<void> removeWorker(String workerId) async {
    try {
      await _dio.delete('/workers/$workerId');
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Analytics (owner only) ──────────────────────────────────────

  Future<Map<String, dynamic>> getDashboardStats(String period) async {
    try {
      final user = localDb.getUser();
      final res = await _dio.get('/analytics/dashboard', queryParameters: {
        'businessId': user?.businessId,
        'period':     period, // today, week, month
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── Subscription ───────────────────────────────────────────────

  Future<SubscriptionStatus> getSubscriptionStatus() async {
    try {
      final res = await _dio.get('/subscription');
      return SubscriptionStatus.fromJson(res.data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<SubscriptionPlan>> getSubscriptionPlans() async {
    try {
      final res = await _dio.get('/subscription/plans');
      return (res.data['plans'] as List)
          .map((j) => SubscriptionPlan.fromJson(j))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<List<SubscriptionPayment>> getSubscriptionHistory() async {
    try {
      final res = await _dio.get('/subscription/history');
      return (res.data['payments'] as List)
          .map((j) => SubscriptionPayment.fromJson(j))
          .toList();
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<SubscriptionStatus> verifySubscriptionPayment() async {
    try {
      final res = await _dio.post('/subscription/verify-payment');
      return SubscriptionStatus.fromJson(res.data['subscription']);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  // ─── TeleBirr H5 Payment ─────────────────────────────────────────

  Future<Map<String, dynamic>> createTelebirrOrder(String tier, int periodMonths) async {
    try {
      final res = await _dio.post('/telebirr/create-order', data: {
        'tier': tier,
        'periodMonths': periodMonths,
      });
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getOrderStatus(String outTradeNo) async {
    try {
      final res = await _dio.get('/telebirr/order/$outTradeNo');
      return Map<String, dynamic>.from(res.data);
    } on DioException catch (e) {
      _handleError(e);
    }
  }
}

final api = ApiClient();
