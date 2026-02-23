import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/translation_service.dart';
import '../models/email_config.dart';
import '../providers/app_state.dart';

class EmailConfigScreen extends StatefulWidget {
  const EmailConfigScreen({super.key, this.initial});

  final EmailConfig? initial;

  @override
  State<EmailConfigScreen> createState() => _EmailConfigScreenState();
}

class _EmailConfigScreenState extends State<EmailConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _smtpHostController;
  late TextEditingController _smtpPortController;
  late TextEditingController _smtpUserController;
  late TextEditingController _smtpPasswordController;
  late TextEditingController _fromEmailController;
  late TextEditingController _toEmailsController;
  late TextEditingController _senderFilterController;
  late TextEditingController _bodyFilterController;

  bool _useSsl = true;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _nameController = TextEditingController(text: c?.name ?? '');
    _smtpHostController = TextEditingController(text: c?.smtpHost ?? 'smtp.example.com');
    _smtpPortController = TextEditingController(text: '${c?.smtpPort ?? 465}');
    _smtpUserController = TextEditingController(text: c?.smtpUser ?? '');
    _smtpPasswordController = TextEditingController(text: c?.smtpPassword ?? '');
    _fromEmailController = TextEditingController(text: c?.fromEmail ?? '');
    _toEmailsController = TextEditingController(text: c?.toEmails ?? '');
    _senderFilterController = TextEditingController(text: c?.senderFilter ?? '');
    _bodyFilterController = TextEditingController(text: c?.bodyFilter ?? '');
    _useSsl = c?.useSsl ?? true;
    _enabled = c?.enabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _smtpHostController.dispose();
    _smtpPortController.dispose();
    _smtpUserController.dispose();
    _smtpPasswordController.dispose();
    _fromEmailController.dispose();
    _toEmailsController.dispose();
    _senderFilterController.dispose();
    _bodyFilterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'App:Add Email title'.xtr : 'App:Edit Email title'.xtr),
        actions: [
          if (widget.initial != null)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'App:Name'.xtr,
                hintText: 'App:Name hint'.xtr,
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'App:Enter name'.xtr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _smtpHostController,
              decoration: InputDecoration(
                labelText: 'App:SMTP server'.xtr,
                hintText: 'App:SMTP server hint'.xtr,
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'App:Enter SMTP'.xtr : null,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 88,
                  child: TextFormField(
                    controller: _smtpPortController,
                    decoration: InputDecoration(
                      labelText: 'App:Port'.xtr,
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'App:Enter port'.xtr;
                      final port = int.tryParse(v.trim());
                      if (port == null || port <= 0 || port > 65535) return 'App:Invalid port'.xtr;
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Text('SSL'),
                          const SizedBox(width: 8),
                          Switch(
                            value: _useSsl,
                            onChanged: (v) => setState(() => _useSsl = v),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'App:SSL hint'.xtr,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _smtpUserController,
              decoration: InputDecoration(
                labelText: 'App:SMTP user optional'.xtr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _smtpPasswordController,
              decoration: InputDecoration(
                labelText: 'App:SMTP pass optional'.xtr,
                border: OutlineInputBorder(),
                hintText: 'App:Gmail app password'.xtr,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _fromEmailController,
              decoration: InputDecoration(
                labelText: 'App:From email'.xtr,
                hintText: 'App:From email hint'.xtr,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.trim().isEmpty ? 'App:Enter from email'.xtr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _toEmailsController,
              decoration: InputDecoration(
                labelText: 'App:To emails'.xtr,
                hintText: 'App:To emails hint'.xtr,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (v) => v == null || v.trim().isEmpty ? 'App:Enter to emails'.xtr : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _senderFilterController,
              decoration: InputDecoration(
                labelText: 'App:Sender filter'.xtr,
                hintText: 'App:Empty filter'.xtr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyFilterController,
              decoration: InputDecoration(
                labelText: 'App:Body filter'.xtr,
                hintText: 'App:Empty filter'.xtr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('App:Enabled'.xtr),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text('App:Save'.xtr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final port = int.tryParse(_smtpPortController.text.trim()) ?? 465;
    final config = EmailConfig(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      smtpHost: _smtpHostController.text.trim(),
      smtpPort: port,
      useSsl: _useSsl,
      smtpUser: _smtpUserController.text.trim().isEmpty ? null : _smtpUserController.text.trim(),
      smtpPassword: _smtpPasswordController.text.trim().isEmpty ? null : _smtpPasswordController.text.trim(),
      fromEmail: _fromEmailController.text.trim(),
      toEmails: _toEmailsController.text.trim(),
      senderFilter: _senderFilterController.text.trim().isEmpty ? null : _senderFilterController.text.trim(),
      bodyFilter: _bodyFilterController.text.trim().isEmpty ? null : _bodyFilterController.text.trim(),
      enabled: _enabled,
    );
    final state = context.read<AppState>();
    if (widget.initial == null) {
      await state.addEmailConfig(config);
    } else {
      await state.updateEmailConfig(config);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('App:Delete config'.xtr),
        content: Text('App:Delete email confirm'.xtr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('App:Cancel'.xtr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.error),
            child: Text('App:Delete'.xtr),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && widget.initial != null && mounted) {
        await context.read<AppState>().removeEmailConfig(widget.initial!.id);
        if (mounted) Navigator.of(context).pop();
      }
    });
  }
}
