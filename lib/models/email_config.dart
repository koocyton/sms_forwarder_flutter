/// 邮箱转发配置
class EmailConfig {
  EmailConfig({
    required this.id,
    required this.name,
    required this.smtpHost,
    this.smtpPort = 465,
    this.useSsl = true,
    this.smtpUser,
    this.smtpPassword,
    required this.fromEmail,
    required this.toEmails,
    this.senderFilter,
    this.bodyFilter,
    this.enabled = true,
  });

  final String id;
  final String name;
  final String smtpHost;
  final int smtpPort;
  final bool useSsl;
  final String? smtpUser;
  final String? smtpPassword;
  final String fromEmail;
  /// 收件人，多个用英文逗号分隔
  final String toEmails;
  final String? senderFilter;
  final String? bodyFilter;
  final bool enabled;

  List<String> get toEmailList =>
      toEmails.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();

  bool matchesSms(String sender, String body) {
    if (senderFilter != null && senderFilter!.isNotEmpty) {
      if (!sender.contains(senderFilter!)) return false;
    }
    if (bodyFilter != null && bodyFilter!.isNotEmpty) {
      if (!body.contains(bodyFilter!)) return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'smtpHost': smtpHost,
      'smtpPort': smtpPort,
      'useSsl': useSsl,
      'smtpUser': smtpUser,
      'smtpPassword': smtpPassword,
      'fromEmail': fromEmail,
      'toEmails': toEmails,
      'senderFilter': senderFilter,
      'bodyFilter': bodyFilter,
      'enabled': enabled,
    };
  }

  factory EmailConfig.fromJson(Map<String, dynamic> json) {
    return EmailConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      smtpHost: json['smtpHost'] as String,
      smtpPort: json['smtpPort'] as int? ?? 465,
      useSsl: json['useSsl'] as bool? ?? true,
      smtpUser: json['smtpUser'] as String?,
      smtpPassword: json['smtpPassword'] as String?,
      fromEmail: json['fromEmail'] as String,
      toEmails: json['toEmails'] as String,
      senderFilter: json['senderFilter'] as String?,
      bodyFilter: json['bodyFilter'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
