import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:telephony/telephony.dart';
import 'package:uuid/uuid.dart';

import '../models/api_config.dart';
import '../models/email_config.dart';
import '../models/sms_log_entry.dart';
import 'storage_service.dart';

/// 短信与未接来电监听并转发
class SmsForwardService {
  SmsForwardService._();
  static final SmsForwardService instance = SmsForwardService._();

  /// 写入一条日志后调用，便于界面刷新列表（仅前台有效）
  static void Function()? onLogAdded;

  final Telephony _telephony = Telephony.instance;
  final StorageService _storage = StorageService.instance;
  final Uuid _uuid = const Uuid();

  bool _listening = false;
  bool get isListening => _listening;

  static const _foregroundChannel = MethodChannel('com.bobog.n.sms_forwarder/foreground');
  static const _configChannel = MethodChannel('com.bobog.n.sms_forwarder/config');

  /// 将当前监听状态与 API/邮箱配置同步到原生，供后台收短信时使用（Flutter 2.x 用 DataStore，原生无法直接读）
  Future<void> syncConfigToNative() async {
    if (!Platform.isAndroid) return;
    try {
      final apis = await _storage.loadApiConfigs();
      final emails = await _storage.loadEmailConfigs();
      await _configChannel.invokeMethod('syncForwarderConfig', {
        'listeningEnabled': _listening,
        'apiConfigsJson': jsonEncode(apis.map((c) => c.toJson()).toList()),
        'emailConfigsJson': jsonEncode(emails.map((c) => c.toJson()).toList()),
      });
    } catch (_) {}
  }

  /// 开始监听短信（会先请求权限）
  /// 返回 true 表示已开始监听，false 表示权限被拒绝或失败
  Future<bool> startListening() async {
    if (_listening) return true;
    final smsGranted = await _telephony.requestPhoneAndSmsPermissions;
    if (smsGranted != true) return false;

    _listening = true;
    _telephony.listenIncomingSms(
      onNewMessage: _onSms,
      onBackgroundMessage: backgroundSmsHandler,
      listenInBackground: true,
    );
    if (Platform.isAndroid) {
      try {
        await Permission.notification.request();
        await _foregroundChannel.invokeMethod<void>('startListenForeground');
        await syncConfigToNative();
      } catch (_) {}
    }
    return true;
  }

  void stopListening() {
    _listening = false;
    if (Platform.isAndroid) {
      try {
        _foregroundChannel.invokeMethod<void>('stopListenForeground');
        syncConfigToNative();
      } catch (_) {}
    }
  }

  void _onSms(SmsMessage msg) {
    _forwardToApis(msg.address ?? '', msg.body ?? '');
  }

  Future<void> _forwardToApis(String sender, String body) async {
    final apiConfigs = await _storage.loadApiConfigs();
    final emailConfigs = await _storage.loadEmailConfigs();
    final enabledApis = apiConfigs.where((c) => c.enabled).toList();
    final enabledEmails = emailConfigs.where((c) => c.enabled).toList();

    if (enabledApis.isEmpty && enabledEmails.isEmpty) {
      await _appendNotForwardedLog(
        sender,
        body,
        '没有启用的 API 或邮箱，请先添加并开启',
      );
      return;
    }

    final matchingApis = enabledApis.where((c) => c.matchesSms(sender, body)).toList();
    final matchingEmails = enabledEmails.where((c) => c.matchesSms(sender, body)).toList();
    if (matchingApis.isEmpty && matchingEmails.isEmpty) {
      await _appendNotForwardedLog(
        sender,
        body,
        '未匹配任何规则（若设置了发送方/内容过滤，需包含对应关键词）',
      );
      return;
    }

    final date = DateTime.now().toIso8601String();
    for (final config in matchingApis) {
      await _sendOne(config, sender, body, date);
    }
    for (final config in matchingEmails) {
      await _sendEmail(config, sender, body, date);
    }
  }

  /// 按名称重新转发（API 或邮箱），用于日志页「重试」
  Future<bool> retryForward(String sender, String body, String targetName) async {
    if (targetName == 'SmsForward:NotForwarded') return false;
    final date = DateTime.now().toIso8601String();
    final apiConfigs = await _storage.loadApiConfigs();
    final apiMatch = apiConfigs.where((c) => c.name == targetName).toList();
    if (apiMatch.isNotEmpty) {
      await _sendOne(apiMatch.first, sender, body, date);
      return true;
    }
    final emailConfigs = await _storage.loadEmailConfigs();
    final emailMatch = emailConfigs.where((c) => c.name == targetName).toList();
    if (emailMatch.isNotEmpty) {
      await _sendEmail(emailMatch.first, sender, body, date);
      return true;
    }
    return false;
  }

  /// 记录「收到但未转发」便于排查
  Future<void> _appendNotForwardedLog(String sender, String body, String reason) async {
    await _storage.appendSmsLog(SmsLogEntry(
      id: _uuid.v4(),
      sender: sender,
      body: body,
      timestamp: DateTime.now(),
      apiName: 'SmsForward:NotForwarded',
      success: false,
      errorMessage: reason,
    ));
    onLogAdded?.call();
  }

  Future<void> _sendOne(
    ApiConfig config,
    String sender,
    String body,
    String date,
  ) async {
    final client = _createDio(config);
    final logId = _uuid.v4();

    try {
      final method = config.method.toUpperCase();
      dynamic data;
      if (config.bodyTemplate != null && config.bodyTemplate!.isNotEmpty) {
        final raw = config.bodyTemplate!
            .replaceAll('{{sender}}', sender)
            .replaceAll('{{body}}', body)
            .replaceAll('{{date}}', date);
        try {
          data = jsonDecode(raw) as Map<String, dynamic>;
        } catch (_) {
          data = raw;
        }
      } else {
        data = {
          'sender': sender,
          'body': body,
          'date': date,
        };
      }

      final query = data is Map<String, dynamic> ? data : null;
      final bodyData = method == 'GET' ? null : data;

      switch (method) {
        case 'GET':
          await client.get(config.url, queryParameters: query);
          break;
        case 'POST':
          await client.post(config.url, data: bodyData);
          break;
        case 'PUT':
          await client.put(config.url, data: bodyData);
          break;
        case 'PATCH':
          await client.patch(config.url, data: bodyData);
          break;
        default:
          await client.post(config.url, data: bodyData);
      }

      await _storage.appendSmsLog(SmsLogEntry(
        id: logId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
        apiName: config.name,
        success: true,
      ));
      onLogAdded?.call();
    } catch (e) {
      final errorMsg = e.toString();
      await _storage.appendSmsLog(SmsLogEntry(
        id: logId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
        apiName: config.name,
        success: false,
        errorMessage: errorMsg,
      ));
      onLogAdded?.call();
    }
  }

  Dio _createDio(ApiConfig config) {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: Map.from(config.headers),
    ));
    return dio;
  }

  Future<void> _sendEmail(
    EmailConfig config,
    String sender,
    String body,
    String date,
  ) async {
    final logId = _uuid.v4();
    final recipients = config.toEmailList;
    if (recipients.isEmpty) {
      await _storage.appendSmsLog(SmsLogEntry(
        id: logId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
        apiName: config.name,
        success: false,
        errorMessage: '未配置收件人',
      ));
      onLogAdded?.call();
      return;
    }
    try {
      final useSsl = config.smtpPort == 465
          ? true
          : config.smtpPort == 587
              ? false
              : config.useSsl;
      final smtpServer = SmtpServer(
        config.smtpHost,
        port: config.smtpPort,
        ssl: useSsl,
        allowInsecure: true,
        ignoreBadCertificate: true,
        username: config.smtpUser,
        password: config.smtpPassword,
      );
      final subject = '短信转发: $sender';
      final text = '发送方: $sender\n时间: $date\n\n$body';
      final message = Message()
        ..from = Address(config.fromEmail, 'SMS Forwarder')
        ..recipients.addAll(recipients)
        ..subject = subject
        ..text = text;
      await send(message, smtpServer, timeout: const Duration(seconds: 30));
      await _storage.appendSmsLog(SmsLogEntry(
        id: logId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
        apiName: config.name,
        success: true,
      ));
      onLogAdded?.call();
    } catch (e) {
      await _storage.appendSmsLog(SmsLogEntry(
        id: logId,
        sender: sender,
        body: body,
        timestamp: DateTime.now(),
        apiName: config.name,
        success: false,
        errorMessage: e.toString(),
      ));
      onLogAdded?.call();
    }
  }
}

/// 后台收到短信时由 native 调用，必须是顶级函数
@pragma('vm:entry-point')
Future<void> backgroundSmsHandler(SmsMessage msg) async {
  await SmsForwardService.instance._forwardToApis(
    msg.address ?? '',
    msg.body ?? '',
  );
}
