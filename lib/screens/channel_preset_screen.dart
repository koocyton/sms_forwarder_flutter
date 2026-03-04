import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../l10n/translation_service.dart';
import '../models/api_config.dart';
import '../providers/app_state.dart';

// ─────────────────────────────────────────────
// 平台枚举
// ─────────────────────────────────────────────

enum ChannelType { telegram, feishu, dingtalk, wecom, slack }

extension ChannelTypeInfo on ChannelType {
  String get id {
    switch (this) {
      case ChannelType.telegram: return 'telegram';
      case ChannelType.feishu:   return 'feishu';
      case ChannelType.dingtalk: return 'dingtalk';
      case ChannelType.wecom:    return 'wecom';
      case ChannelType.slack:    return 'slack';
    }
  }

  String get label {
    switch (this) {
      case ChannelType.telegram: return 'Telegram';
      case ChannelType.feishu:   return '飞书';
      case ChannelType.dingtalk: return '钉钉';
      case ChannelType.wecom:    return '企业微信';
      case ChannelType.slack:    return 'Slack';
    }
  }

  Color get color {
    switch (this) {
      case ChannelType.telegram: return const Color(0xFF229ED9);
      case ChannelType.feishu:   return const Color(0xFF3370FF);
      case ChannelType.dingtalk: return const Color(0xFF1472FF);
      case ChannelType.wecom:    return const Color(0xFF07C160);
      case ChannelType.slack:    return const Color(0xFF4A154B);
    }
  }

  String get avatar {
    switch (this) {
      case ChannelType.telegram: return 'TG';
      case ChannelType.feishu:   return '飞';
      case ChannelType.dingtalk: return '钉';
      case ChannelType.wecom:    return '企';
      case ChannelType.slack:    return 'SL';
    }
  }

  String get descriptionKey {
    switch (this) {
      case ChannelType.telegram: return 'App:Channel desc telegram';
      case ChannelType.feishu:   return 'App:Channel desc feishu';
      case ChannelType.dingtalk: return 'App:Channel desc dingtalk';
      case ChannelType.wecom:    return 'App:Channel desc wecom';
      case ChannelType.slack:    return 'App:Channel desc slack';
    }
  }

  String get guideKey {
    switch (this) {
      case ChannelType.telegram: return 'App:Channel guide telegram';
      case ChannelType.feishu:   return 'App:Channel guide feishu';
      case ChannelType.dingtalk: return 'App:Channel guide dingtalk';
      case ChannelType.wecom:    return 'App:Channel guide wecom';
      case ChannelType.slack:    return 'App:Channel guide slack';
    }
  }
}

ChannelType? channelTypeFromId(String? id) {
  if (id == null) return null;
  for (final t in ChannelType.values) {
    if (t.id == id) return t;
  }
  return null;
}

// ─────────────────────────────────────────────
// 平台选择列表页
// ─────────────────────────────────────────────

class ChannelPresetScreen extends StatelessWidget {
  const ChannelPresetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('App:Channel preset'.xtr)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'App:Channel preset hint'.xtr,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          ...ChannelType.values.map((t) => _PlatformCard(channelType: t)),
        ],
      ),
    );
  }
}

class _PlatformCard extends StatelessWidget {
  const _PlatformCard({required this.channelType});

  final ChannelType channelType;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        leading: _PlatformAvatar(channelType: channelType, size: 40),
        title: Text(
          channelType.label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          channelType.descriptionKey.xtr,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => ChannelFormScreen(channelType: channelType)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 平台头像组件（供外部复用）
// ─────────────────────────────────────────────

class _PlatformAvatar extends StatelessWidget {
  const _PlatformAvatar({required this.channelType, this.size = 40});

  final ChannelType channelType;
  final double size;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: channelType.color,
      child: Text(
        channelType.avatar,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: size * 0.32,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// 各平台配置表单页
// ─────────────────────────────────────────────

class ChannelFormScreen extends StatefulWidget {
  const ChannelFormScreen({super.key, required this.channelType});

  final ChannelType channelType;

  @override
  State<ChannelFormScreen> createState() => _ChannelFormScreenState();
}

class _ChannelFormScreenState extends State<ChannelFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _webhookCtrl;
  late final TextEditingController _botTokenCtrl;
  late final TextEditingController _chatIdCtrl;
  late final TextEditingController _senderFilterCtrl;
  late final TextEditingController _bodyFilterCtrl;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    _nameCtrl        = TextEditingController(text: widget.channelType.label);
    _webhookCtrl     = TextEditingController();
    _botTokenCtrl    = TextEditingController();
    _chatIdCtrl      = TextEditingController();
    _senderFilterCtrl = TextEditingController();
    _bodyFilterCtrl  = TextEditingController();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _webhookCtrl.dispose();
    _botTokenCtrl.dispose();
    _chatIdCtrl.dispose();
    _senderFilterCtrl.dispose();
    _bodyFilterCtrl.dispose();
    super.dispose();
  }

  // 各平台消息正文模板（{{sender}} {{body}} {{date}} 为运行时占位符）
  static const _msgBody = '{{sender}} 的短信:\\n\\n{{body}}\\n\\n时间: {{date}}';

  ApiConfig _buildConfig() {
    final id     = const Uuid().v4();
    final name   = _nameCtrl.text.trim();
    final sender = _senderFilterCtrl.text.trim().isEmpty ? null : _senderFilterCtrl.text.trim();
    final body   = _bodyFilterCtrl.text.trim().isEmpty ? null : _bodyFilterCtrl.text.trim();

    switch (widget.channelType) {
      case ChannelType.telegram:
        final token  = _botTokenCtrl.text.trim();
        final chatId = _chatIdCtrl.text.trim();
        return ApiConfig(
          id: id, name: name,
          url: 'https://api.telegram.org/bot$token/sendMessage',
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"chat_id":"$chatId","text":"$_msgBody"}',
          senderFilter: sender, bodyFilter: body,
          enabled: _enabled, channel: ChannelType.telegram.id,
        );

      case ChannelType.feishu:
        return ApiConfig(
          id: id, name: name,
          url: _webhookCtrl.text.trim(),
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"msg_type":"text","content":{"text":"$_msgBody"}}',
          senderFilter: sender, bodyFilter: body,
          enabled: _enabled, channel: ChannelType.feishu.id,
        );

      case ChannelType.dingtalk:
        return ApiConfig(
          id: id, name: name,
          url: _webhookCtrl.text.trim(),
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"msgtype":"text","text":{"content":"$_msgBody"},"at":{"isAtAll":false}}',
          senderFilter: sender, bodyFilter: body,
          enabled: _enabled, channel: ChannelType.dingtalk.id,
        );

      case ChannelType.wecom:
        return ApiConfig(
          id: id, name: name,
          url: _webhookCtrl.text.trim(),
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"msgtype":"text","text":{"content":"$_msgBody"}}',
          senderFilter: sender, bodyFilter: body,
          enabled: _enabled, channel: ChannelType.wecom.id,
        );

      case ChannelType.slack:
        return ApiConfig(
          id: id, name: name,
          url: _webhookCtrl.text.trim(),
          method: 'POST',
          headers: {'Content-Type': 'application/json'},
          bodyTemplate: '{"text":"$_msgBody"}',
          senderFilter: sender, bodyFilter: body,
          enabled: _enabled, channel: ChannelType.slack.id,
        );
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final config = _buildConfig();
    await context.read<AppState>().addConfig(config);
    if (mounted) {
      Navigator.of(context)
        ..pop()
        ..pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.channelType.label)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            // 配置名称
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: 'App:Name'.xtr,
                hintText: widget.channelType.label,
                border: const OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'App:Enter name'.xtr : null,
            ),
            const SizedBox(height: 16),
            // 平台专属字段
            ..._buildPlatformFields(context),
            const SizedBox(height: 16),
            // 获取引导折叠面板
            _buildGuide(context),
            const SizedBox(height: 8),
            // 过滤（可选）
            ExpansionTile(
              title: Text('App:Channel filter'.xtr),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              children: [
                TextFormField(
                  controller: _senderFilterCtrl,
                  decoration: InputDecoration(
                    labelText: 'App:Sender filter'.xtr,
                    hintText: 'App:Sender filter API'.xtr,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _bodyFilterCtrl,
                  decoration: InputDecoration(
                    labelText: 'App:Body filter'.xtr,
                    hintText: 'App:Body filter API'.xtr,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            SwitchListTile(
              title: Text('App:Enabled'.xtr),
              subtitle: Text('App:Enabled subtitle'.xtr),
              value: _enabled,
              onChanged: (v) => setState(() => _enabled = v),
            ),
            const SizedBox(height: 24),
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

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.channelType.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: widget.channelType.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          _PlatformAvatar(channelType: widget.channelType, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.channelType.label,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.channelType.descriptionKey.xtr,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPlatformFields(BuildContext context) {
    if (widget.channelType == ChannelType.telegram) {
      return [
        TextFormField(
          controller: _botTokenCtrl,
          decoration: InputDecoration(
            labelText: 'App:Telegram bot token'.xtr,
            hintText: '110201543:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw',
            border: const OutlineInputBorder(),
          ),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'App:Enter bot token'.xtr : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _chatIdCtrl,
          decoration: InputDecoration(
            labelText: 'App:Telegram chat id'.xtr,
            hintText: '123456789',
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'App:Enter chat id'.xtr : null,
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            'App:Telegram chat id tip'.xtr,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }

    // feishu / dingtalk / wecom / slack — 统一 Webhook URL 输入
    return [
      TextFormField(
        controller: _webhookCtrl,
        decoration: InputDecoration(
          labelText: 'App:Webhook URL'.xtr,
          hintText: _webhookHint(),
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.url,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return 'App:Enter webhook'.xtr;
          final uri = Uri.tryParse(v.trim());
          if (uri == null || !uri.hasScheme) return 'App:Invalid URL'.xtr;
          return null;
        },
      ),
      // 钉钉安全设置提示
      if (widget.channelType == ChannelType.dingtalk) ...[
        const SizedBox(height: 10),
        _InfoTip(
          icon: Icons.warning_amber_rounded,
          color: Theme.of(context).colorScheme.tertiary,
          background: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.4),
          text: 'App:Dingtalk keyword tip'.xtr,
        ),
      ],
    ];
  }

  Widget _buildGuide(BuildContext context) {
    return ExpansionTile(
      leading: Icon(Icons.help_outline, color: Theme.of(context).colorScheme.primary),
      title: Text('App:Channel guide title'.xtr),
      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      children: [
        Text(
          widget.channelType.guideKey.xtr,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            height: 1.7,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  String _webhookHint() {
    switch (widget.channelType) {
      case ChannelType.feishu:
        return 'https://open.feishu.cn/open-apis/bot/v2/hook/xxx';
      case ChannelType.dingtalk:
        return 'https://oapi.dingtalk.com/robot/send?access_token=xxx';
      case ChannelType.wecom:
        return 'https://qyapi.weixin.qq.com/cgi-bin/webhook/send?key=xxx';
      case ChannelType.slack:
        return 'https://hooks.slack.com/services/xxx/yyy/zzz';
      default:
        return '';
    }
  }
}

// ─────────────────────────────────────────────
// 提示信息组件
// ─────────────────────────────────────────────

class _InfoTip extends StatelessWidget {
  const _InfoTip({
    required this.text,
    required this.icon,
    required this.color,
    required this.background,
  });

  final String text;
  final IconData icon;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
