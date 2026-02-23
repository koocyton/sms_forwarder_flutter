import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/translation_service.dart';
import '../models/api_config.dart';
import '../providers/app_state.dart';

class ApiConfigScreen extends StatefulWidget {
  const ApiConfigScreen({super.key, this.initial});

  final ApiConfig? initial;

  @override
  State<ApiConfigScreen> createState() => _ApiConfigScreenState();
}

class _ApiConfigScreenState extends State<ApiConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _urlController;
  late TextEditingController _bodyController;
  late TextEditingController _senderFilterController;
  late TextEditingController _bodyFilterController;

  String _method = 'POST';
  bool _enabled = true;
  final List<TextEditingController> _headerKeys = [];
  final List<TextEditingController> _headerValues = [];

  @override
  void initState() {
    super.initState();
    final c = widget.initial;
    _nameController = TextEditingController(text: c?.name ?? '');
    _urlController = TextEditingController(text: c?.url ?? '');
    _bodyController = TextEditingController(
      text: c?.bodyTemplate ?? '{"sender":"{{sender}}","body":"{{body}}","date":"{{date}}"}',
    );
    _senderFilterController = TextEditingController(text: c?.senderFilter ?? '');
    _bodyFilterController = TextEditingController(text: c?.bodyFilter ?? '');
    _method = c?.method ?? 'POST';
    _enabled = c?.enabled ?? true;
    if (c?.headers != null && c!.headers.isNotEmpty) {
      for (final e in c.headers.entries) {
        _headerKeys.add(TextEditingController(text: e.key));
        _headerValues.add(TextEditingController(text: e.value));
      }
    }
  }

  void _addHeaderEntry() {
    setState(() {
      _headerKeys.add(TextEditingController());
      _headerValues.add(TextEditingController());
    });
  }

  void _removeHeaderAt(int i) {
    setState(() {
      _headerKeys[i].dispose();
      _headerValues[i].dispose();
      _headerKeys.removeAt(i);
      _headerValues.removeAt(i);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    _senderFilterController.dispose();
    _bodyFilterController.dispose();
    for (final c in _headerKeys) {
      c.dispose();
    }
    for (final c in _headerValues) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initial == null ? 'App:Add API title'.xtr : 'App:Edit API title'.xtr),
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
              controller: _urlController,
              decoration: InputDecoration(
                labelText: 'App:URL'.xtr,
                hintText: 'App:URL hint'.xtr,
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'App:Enter URL'.xtr;
                final uri = Uri.tryParse(v.trim());
                if (uri == null || !uri.hasScheme) return 'App:Invalid URL'.xtr;
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _method,
              decoration: InputDecoration(
                labelText: 'App:Method'.xtr,
                border: OutlineInputBorder(),
              ),
              items: ['GET', 'POST', 'PUT', 'PATCH']
                  .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                  .toList(),
              onChanged: (v) => setState(() => _method = v ?? 'POST'),
            ),
            const SizedBox(height: 16),
            ExpansionTile(
              title: Text('App:Headers count'.xtrFormat({'count': '${_headerKeys.length}'})),
              initiallyExpanded: _headerKeys.isNotEmpty,
              children: [
                ...List.generate(_headerKeys.length, (i) => _HeaderRow(
                      key: ValueKey(i),
                      keyController: _headerKeys[i],
                      valueController: _headerValues[i],
                      onRemove: () => _removeHeaderAt(i),
                    )),
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: TextButton.icon(
                    onPressed: _addHeaderEntry,
                    icon: const Icon(Icons.add),
                    label: Text('App:Add header'.xtr),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: InputDecoration(
                labelText: 'App:Body template'.xtr,
                hintText: 'App:Body template hint'.xtr,
                alignLabelWithHint: true,
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _senderFilterController,
              decoration: InputDecoration(
                labelText: 'App:Sender filter'.xtr,
                hintText: 'App:Sender filter API'.xtr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyFilterController,
              decoration: InputDecoration(
                labelText: 'App:Body filter'.xtr,
                hintText: 'App:Body filter API'.xtr,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
            SwitchListTile(
              title: Text('App:Enabled'.xtr),
              subtitle: Text('App:Enabled subtitle'.xtr),
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
    final headers = <String, String>{};
    for (var i = 0; i < _headerKeys.length; i++) {
      final k = _headerKeys[i].text.trim();
      if (k.isEmpty) {
        continue;
      }
      headers[k] = _headerValues[i].text.trim();
    }

    final config = ApiConfig(
      id: widget.initial?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      method: _method,
      headers: headers,
      bodyTemplate: _bodyController.text.trim().isEmpty
          ? null
          : _bodyController.text.trim(),
      senderFilter: _senderFilterController.text.trim().isEmpty
          ? null
          : _senderFilterController.text.trim(),
      bodyFilter: _bodyFilterController.text.trim().isEmpty
          ? null
          : _bodyFilterController.text.trim(),
      enabled: _enabled,
    );

    final state = context.read<AppState>();
    if (widget.initial == null) {
      await state.addConfig(config);
    } else {
      await state.updateConfig(config);
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmDelete() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('App:Delete config'.xtr),
        content: Text('App:Delete API confirm'.xtr),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('App:Cancel'.xtr),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('App:Delete'.xtr),
          ),
        ],
      ),
    ).then((ok) async {
      if (ok == true && widget.initial != null && mounted) {
        await context.read<AppState>().removeConfig(widget.initial!.id);
        if (mounted) Navigator.of(context).pop();
      }
    });
  }
}

class _HeaderRow extends StatefulWidget {
  const _HeaderRow({
    super.key,
    required this.keyController,
    required this.valueController,
    required this.onRemove,
  });

  final TextEditingController keyController;
  final TextEditingController valueController;
  final VoidCallback onRemove;

  @override
  State<_HeaderRow> createState() => _HeaderRowState();
}

class _HeaderRowState extends State<_HeaderRow> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              controller: widget.keyController,
              decoration: InputDecoration(
                labelText: 'Key',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: TextField(
              controller: widget.valueController,
              decoration: InputDecoration(
                labelText: 'Value',
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: widget.onRemove,
          ),
        ],
      ),
    );
  }
}
