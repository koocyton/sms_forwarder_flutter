import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_config.dart';
import '../models/email_config.dart';
import '../models/sms_log_entry.dart';

const _keyApiConfigs = 'api_configs';
const _keyEmailConfigs = 'email_configs';
const _keySmsLogs = 'sms_logs';
const _keyListening = 'listening_enabled';
const _maxLogs = 200;

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<List<ApiConfig>> loadApiConfigs() async {
    await init();
    final raw = _prefs!.getString(_keyApiConfigs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ApiConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveApiConfigs(List<ApiConfig> configs) async {
    await init();
    final list = configs.map((e) => e.toJson()).toList();
    await _prefs!.setString(_keyApiConfigs, jsonEncode(list));
  }

  Future<List<EmailConfig>> loadEmailConfigs() async {
    await init();
    final raw = _prefs!.getString(_keyEmailConfigs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => EmailConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveEmailConfigs(List<EmailConfig> configs) async {
    await init();
    final list = configs.map((e) => e.toJson()).toList();
    await _prefs!.setString(_keyEmailConfigs, jsonEncode(list));
  }

  Future<List<SmsLogEntry>> loadSmsLogs() async {
    await init();
    await _prefs!.reload();
    final raw = _prefs!.getString(_keySmsLogs);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => SmsLogEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> appendSmsLog(SmsLogEntry entry) async {
    await init();
    final logs = await loadSmsLogs();
    logs.insert(0, entry);
    if (logs.length > _maxLogs) logs.removeRange(_maxLogs, logs.length);
    final list = logs.map((e) => e.toJson()).toList();
    await _prefs!.setString(_keySmsLogs, jsonEncode(list));
  }

  Future<void> clearSmsLogs() async {
    await init();
    await _prefs!.remove(_keySmsLogs);
  }

  Future<void> removeSmsLogById(String id) async {
    await init();
    final logs = await loadSmsLogs();
    final remaining = logs.where((e) => e.id != id).toList();
    final list = remaining.map((e) => e.toJson()).toList();
    await _prefs!.setString(_keySmsLogs, jsonEncode(list));
  }

  Future<bool> loadListeningState() async {
    await init();
    return _prefs!.getBool(_keyListening) ?? false;
  }

  Future<void> saveListeningState(bool enabled) async {
    await init();
    await _prefs!.setBool(_keyListening, enabled);
  }
}
