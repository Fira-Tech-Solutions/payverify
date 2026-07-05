import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/providers.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/app_messages.dart';

class WorkersScreen extends ConsumerWidget {
  const WorkersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workersAsync = ref.watch(workersProvider);
    final inviteAsync = ref.watch(inviteCodeProvider);
    final user = ref.watch(authProvider).valueOrNull;

    if (user == null || !user.isManager) {
      return const Scaffold(
        body:
            Center(child: Text('Access restricted to owners and managers')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Workers')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.accentLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.person_add,
                          color: AppTheme.accent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    const Text('Add a cashier',
                        style: TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600)),
                  ]),
                  const SizedBox(height: 12),
                  const Text(
                    'Share this code with your employee. '
                    'They enter it in the app to join your business. '
                    'Code expires in 24 hours.',
                    style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                        height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  inviteAsync.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator()),
                    error: (e, _) => Text('Could not generate code: $e',
                        style: const TextStyle(color: AppTheme.danger)),
                    data: (code) => _CodeBox(code: code),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Generate new code'),
                    onPressed: () => ref.refresh(inviteCodeProvider),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Your workers',
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 10),
          workersAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => _WorkersError(e.toString()),
            data: (workers) => workers.isEmpty
                ? const _EmptyWorkers()
                : Column(
                    children: workers
                        .map((w) => _WorkerTile(
                              worker: w,
                              onRemove: () =>
                                  _confirmRemove(context, ref, w['id']),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(
      BuildContext context, WidgetRef ref, String workerId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove worker?'),
        content: const Text(
            'This will revoke their access to your business immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.danger),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(workersProvider.future).then((_) {});
    }
  }
}

class _CodeBox extends StatelessWidget {
  final String code;
  const _CodeBox({required this.code});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: () {
          Clipboard.setData(ClipboardData(text: code));
          AppMessages.success(context, 'Code copied to clipboard');
        },
        child: Container(
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    code.characters.join(' '),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 8),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.copy, color: Colors.white60, size: 18),
            ],
          ),
        ),
      );
}

class _WorkerTile extends StatelessWidget {
  final Map<String, dynamic> worker;
  final VoidCallback onRemove;
  const _WorkerTile({required this.worker, required this.onRemove});

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: AppTheme.accent.withValues(alpha: 0.15),
            child: Text(
              (worker['name'] as String? ?? 'W')
                  .substring(0, 1)
                  .toUpperCase(),
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppTheme.accent),
            ),
          ),
          title: Text(worker['name'] ?? 'Worker',
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: Text(worker['phone'] ?? '',
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.accentLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  worker['role'] ?? 'CASHIER',
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.accent),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline,
                    color: AppTheme.danger, size: 20),
                onPressed: onRemove,
              ),
            ],
          ),
        ),
      );
}

class _EmptyWorkers extends StatelessWidget {
  const _EmptyWorkers();

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: const Column(
          children: [
            Icon(Icons.people_outline, size: 40, color: AppTheme.textMuted),
            SizedBox(height: 10),
            Text('No workers yet',
                style: TextStyle(
                    fontSize: 14, color: AppTheme.textSecondary)),
            SizedBox(height: 4),
            Text('Share the invite code above to add cashiers',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12, color: AppTheme.textMuted)),
          ],
        ),
      );
}

class _WorkersError extends StatelessWidget {
  final String msg;
  const _WorkersError(this.msg);

  @override
  Widget build(BuildContext context) => Text(
        'Could not load workers: $msg',
        style: const TextStyle(color: AppTheme.danger, fontSize: 13),
      );
}
