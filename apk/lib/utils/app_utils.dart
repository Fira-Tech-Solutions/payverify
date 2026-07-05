import 'package:intl/intl.dart';

class AppUtils {
  // ─── Money formatting ─────────────────────────────────────────────

  static String formatAmount(double amount) =>
      'ETB ${NumberFormat('#,##0.00').format(amount)}';

  static String formatAmountShort(double amount) =>
      'ETB ${NumberFormat('#,##0').format(amount)}';

  // ─── Date formatting ──────────────────────────────────────────────

  static String formatDateTime(DateTime dt) =>
      DateFormat('MMM d, y · HH:mm').format(dt);

  static String formatTime(DateTime dt) =>
      DateFormat('HH:mm').format(dt);

  static String formatDate(DateTime dt) =>
      DateFormat('MMM d, y').format(dt);

  static String formatRelative(DateTime dt) {
    final now  = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60)   return 'Just now';
    if (diff.inMinutes < 60)   return '${diff.inMinutes}m ago';
    if (diff.inHours < 24)     return '${diff.inHours}h ago';
    if (diff.inDays == 1)      return 'Yesterday';
    if (diff.inDays < 7)       return '${diff.inDays}d ago';
    return formatDate(dt);
  }

  // ─── Phone number normalisation ───────────────────────────────────

  /// Normalize Ethiopian phone numbers to 09xxxxxxxx format
  static String normalizePhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('2519') && digits.length == 13) {
      return '0${digits.substring(3)}'; // +2519... → 09...
    }
    if (digits.startsWith('9') && digits.length == 9) {
      return '0$digits'; // 9... → 09...
    }
    return digits;
  }

  static bool isValidEthiopianPhone(String phone) {
    final normalized = normalizePhone(phone);
    return RegExp(r'^09\d{8}$').hasMatch(normalized);
  }

  // ─── Reference code cleaning ──────────────────────────────────────

  /// Strip spaces, dashes, common OCR mistakes from scanned reference codes
  static String cleanRefCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'[\s\-_]'), '');

  /// Basic heuristic: a valid Ethiopian payment ref is 8–20 alphanumeric chars
  static bool looksLikeRefCode(String s) =>
      RegExp(r'^[A-Z0-9]{8,20}$').hasMatch(cleanRefCode(s));

  // ─── Amount parsing ───────────────────────────────────────────────

  static double? parseAmount(String raw) {
    final cleaned = raw.replaceAll(RegExp(r'[ETBetb,\s]'), '');
    return double.tryParse(cleaned);
  }

  // ─── Truncation ───────────────────────────────────────────────────

  static String truncate(String s, int maxLen) =>
      s.length <= maxLen ? s : '${s.substring(0, maxLen)}…';

  static String maskPhone(String phone) {
    if (phone.length < 6) return phone;
    return '${phone.substring(0, 4)}****${phone.substring(phone.length - 2)}';
  }
}
