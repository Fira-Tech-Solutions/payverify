import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/api/api_client.dart';

/// Centralized message display — consistent styling, auto-dismiss, proper duration.
class AppMessages {
  AppMessages._();

  // ─── Durations ───────────────────────────────────────────────────
  static const _short  = Duration(seconds: 2);
  static const _medium = Duration(seconds: 3);
  static const _long   = Duration(seconds: 5);

  // ─── Success ─────────────────────────────────────────────────────
  static void success(BuildContext context, String msg) {
    _show(context, msg, icon: Icons.check_circle_outline, color: AppTheme.forest, duration: _medium);
  }

  // ─── Error ───────────────────────────────────────────────────────
  static void error(BuildContext context, Object e) {
    final msg = _extractMessage(e);
    _show(context, msg, icon: Icons.error_outline, color: AppTheme.destructive, duration: _long);
  }

  // ─── Warning ─────────────────────────────────────────────────────
  static void warning(BuildContext context, String msg) {
    _show(context, msg, icon: Icons.warning_amber_rounded, color: AppTheme.gold, duration: _medium);
  }

  // ─── Info ────────────────────────────────────────────────────────
  static void info(BuildContext context, String msg) {
    _show(context, msg, icon: Icons.info_outline, color: AppTheme.mutedForeground, duration: _short);
  }

  // ─── With action ─────────────────────────────────────────────────
  static void errorWithAction(
    BuildContext context,
    String msg, {
    required String actionLabel,
    required VoidCallback onAction,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: AppTheme.destructive, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: AppTheme.foreground))),
      ]),
      backgroundColor: AppTheme.obsidianLight,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: _long,
      action: SnackBarAction(
        label: actionLabel,
        textColor: AppTheme.gold,
        onPressed: onAction,
      ),
    ));
  }

  // ─── Helpers ─────────────────────────────────────────────────────

  static void _show(
    BuildContext context,
    String msg, {
    required IconData icon,
    required Color color,
    required Duration duration,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(SnackBar(
      content: Row(children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontSize: 13, color: AppTheme.foreground))),
      ]),
      backgroundColor: AppTheme.obsidianLight,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: duration,
    ));
  }

  /// Extracts a user-friendly message from any exception type.
  static String _extractMessage(Object e) {
    if (e is ApiException) return e.message;
    // Strip "Exception: " prefix that Dart adds to toString()
    final raw = e.toString();
    final prefix = raw.indexOf(': ');
    if (prefix > 0 && prefix < 20) {
      return raw.substring(prefix + 2);
    }
    return raw;
  }
}
