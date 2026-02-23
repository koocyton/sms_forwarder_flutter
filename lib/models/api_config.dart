/// 单个 HTTP API 配置
class ApiConfig {
  ApiConfig({
    required this.id,
    required this.name,
    required this.url,
    this.method = 'POST',
    Map<String, String>? headers,
    this.bodyTemplate,
    this.senderFilter,
    this.bodyFilter,
    this.enabled = true,
  }) : headers = headers ?? {};

  final String id;
  final String name;
  final String url;
  final String method;
  final Map<String, String> headers;
  /// 请求体模板，支持占位符：{{sender}} {{body}} {{date}}
  final String? bodyTemplate;
  /// 发送方过滤（子串匹配，空则不过滤）
  final String? senderFilter;
  /// 内容过滤（子串匹配，空则不过滤）
  final String? bodyFilter;
  final bool enabled;

  ApiConfig copyWith({
    String? id,
    String? name,
    String? url,
    String? method,
    Map<String, String>? headers,
    String? bodyTemplate,
    String? senderFilter,
    String? bodyFilter,
    bool? enabled,
  }) {
    return ApiConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      method: method ?? this.method,
      headers: headers ?? Map.from(this.headers),
      bodyTemplate: bodyTemplate ?? this.bodyTemplate,
      senderFilter: senderFilter ?? this.senderFilter,
      bodyFilter: bodyFilter ?? this.bodyFilter,
      enabled: enabled ?? this.enabled,
    );
  }

  /// 是否匹配该条短信（过滤条件为空则匹配）
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
      'url': url,
      'method': method,
      'headers': headers,
      'bodyTemplate': bodyTemplate,
      'senderFilter': senderFilter,
      'bodyFilter': bodyFilter,
      'enabled': enabled,
    };
  }

  factory ApiConfig.fromJson(Map<String, dynamic> json) {
    final headers = json['headers'];
    return ApiConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      method: json['method'] as String? ?? 'POST',
      headers: headers != null
          ? Map<String, String>.from(headers as Map)
          : {},
      bodyTemplate: json['bodyTemplate'] as String?,
      senderFilter: json['senderFilter'] as String?,
      bodyFilter: json['bodyFilter'] as String?,
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}
