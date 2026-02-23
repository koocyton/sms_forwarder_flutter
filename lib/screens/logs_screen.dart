import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/translation_service.dart';
import '../models/sms_log_entry.dart';
import '../providers/app_state.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key});

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  @override
  void initState() {
    super.initState();
    // 每次打开本页都从本地存储刷新，避免漏看后台收到的短信记录
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().refreshLogs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('App:Logs title'.xtr),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<AppState>().refreshLogs(),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) async {
              if (v == 'clear') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('App:Clear logs'.xtr),
                    content: Text('App:Clear logs confirm'.xtr),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: Text('App:Cancel'.xtr),
                      ),
                      FilledButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: Text('App:Clear'.xtr),
                      ),
                    ],
                  ),
                );
                if (ok == true && context.mounted) {
                  await context.read<AppState>().clearLogs();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'clear', child: Text('App:Clear logs'.xtr)),
            ],
          ),
        ],
      ),
      body: Consumer<AppState>(
        builder: (_, state, child) {
          final logs = state.logs;
          if (logs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'App:No logs'.xtr,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'App:No logs hint'.xtr,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<AppState>().refreshLogs(),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              itemCount: logs.length,
              itemBuilder: (_, i) => _LogTile(entry: logs[i]),
            ),
          );
        },
      ),
    );
  }
}

class _LogTile extends StatelessWidget {
  const _LogTile({required this.entry});

  final SmsLogEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: entry.success
              ? theme.colorScheme.outlineVariant
              : theme.colorScheme.errorContainer,
        ),
      ),
      child: ExpansionTile(
        leading: Icon(
          entry.success ? Icons.check_circle : Icons.error,
          color: entry.success
              ? theme.colorScheme.primary
              : theme.colorScheme.error,
          size: 28,
        ),
        title: Text(
          entry.body,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text.rich(
          TextSpan(children: [
            TextSpan(text: entry.sender),
            TextSpan(
              text: '  →  ',
              style: TextStyle(color: theme.colorScheme.outline),
            ),
            TextSpan(
              text: entry.apiName == 'SmsForward:NotForwarded'
                  ? (entry.errorMessage ?? 'SmsForward:NotForwarded'.xtr)
                  : entry.apiName,
            ),
          ]),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  entry.body,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  _formatTime(entry.timestamp),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                if (entry.errorMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      entry.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (entry.apiName != 'SmsForward:NotForwarded')
                      TextButton.icon(
                        onPressed: () => _onRetry(context),
                        icon: const Icon(Icons.refresh, size: 20),
                        label: Text('App:Retry'.xtr),
                      ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () => _onDelete(context),
                      icon: Icon(Icons.delete_outline, size: 20, color: theme.colorScheme.error),
                      label: Text('App:Delete'.xtr, style: TextStyle(color: theme.colorScheme.error)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onRetry(BuildContext context) async {
    final state = context.read<AppState>();
    final ok = await state.retryLog(entry);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'App:Retry success'.xtr : 'App:Retry fail'.xtr),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _onDelete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('App:Delete record'.xtr),
        content: Text('App:Delete record confirm'.xtr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('App:Cancel'.xtr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(ctx).colorScheme.error),
            child: Text('App:Delete'.xtr),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<AppState>().deleteLog(entry.id);
    }
  }

  String _formatTime(DateTime t) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logDay = DateTime(t.year, t.month, t.day);
    if (logDay == today) {
      return '${'App:Today'.xtr} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }
    return '${t.month}/${t.day} ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  }
}
