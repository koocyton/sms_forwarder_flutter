/// 单条转发日志
class SmsLogEntry {
  SmsLogEntry({
    required this.id,
    required this.sender,
    required this.body,
    required this.timestamp,
    required this.apiName,
    required this.success,
    this.errorMessage,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime timestamp;
  final String apiName;
  final bool success;
  final String? errorMessage;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender': sender,
      'body': body,
      'timestamp': timestamp.toIso8601String(),
      'apiName': apiName,
      'success': success,
      'errorMessage': errorMessage,
    };
  }

  factory SmsLogEntry.fromJson(Map<String, dynamic> json) {
    return SmsLogEntry(
      id: json['id'] as String,
      sender: json['sender'] as String,
      body: json['body'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      apiName: json['apiName'] as String,
      success: json['success'] as bool,
      errorMessage: json['errorMessage'] as String?,
    );
  }
}
