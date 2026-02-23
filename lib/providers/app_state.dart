import 'package:flutter/foundation.dart';

import '../models/api_config.dart';
import '../models/email_config.dart';
import '../models/sms_log_entry.dart';
import '../services/storage_service.dart';
import '../services/sms_forward_service.dart';

class AppState extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final SmsForwardService _sms = SmsForwardService.instance;

  List<ApiConfig> _configs = [];
  List<EmailConfig> _emailConfigs = [];
  List<SmsLogEntry> _logs = [];
  bool _listening = false;
  bool _loading = true;
  String? _error;

  List<ApiConfig> get configs => List.unmodifiable(_configs);
  List<EmailConfig> get emailConfigs => List.unmodifiable(_emailConfigs);
  List<SmsLogEntry> get logs => List.unmodifiable(_logs);
  bool get isListening => _listening;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasSuccessLog => _logs.any((e) => e.success);

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _configs = await _storage.loadApiConfigs();
      _emailConfigs = await _storage.loadEmailConfigs();
      _logs = await _storage.loadSmsLogs();
      // 恢复上次的监听状态
      final wasListening = await _storage.loadListeningState();
      if (wasListening && !_sms.isListening) {
        await _sms.startListening();
      }
      _listening = _sms.isListening;
      await _sms.syncConfigToNative();
    } catch (e) {
      _error = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  Future<void> addConfig(ApiConfig config) async {
    _configs = [..._configs, config];
    await _storage.saveApiConfigs(_configs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<void> updateConfig(ApiConfig config) async {
    final i = _configs.indexWhere((c) => c.id == config.id);
    if (i < 0) return;
    _configs = [..._configs]..[i] = config;
    await _storage.saveApiConfigs(_configs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<void> removeConfig(String id) async {
    _configs = _configs.where((c) => c.id != id).toList();
    await _storage.saveApiConfigs(_configs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<void> addEmailConfig(EmailConfig config) async {
    _emailConfigs = [..._emailConfigs, config];
    await _storage.saveEmailConfigs(_emailConfigs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<void> updateEmailConfig(EmailConfig config) async {
    final i = _emailConfigs.indexWhere((c) => c.id == config.id);
    if (i < 0) return;
    _emailConfigs = [..._emailConfigs]..[i] = config;
    await _storage.saveEmailConfigs(_emailConfigs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<void> removeEmailConfig(String id) async {
    _emailConfigs = _emailConfigs.where((c) => c.id != id).toList();
    await _storage.saveEmailConfigs(_emailConfigs);
    await _sms.syncConfigToNative();
    notifyListeners();
  }

  Future<bool> toggleListening() async {
    if (_listening) {
      _sms.stopListening();
      _listening = false;
      await _storage.saveListeningState(false);
      notifyListeners();
      return true;
    }
    final started = await _sms.startListening();
    _listening = _sms.isListening;
    await _storage.saveListeningState(_listening);
    notifyListeners();
    return started;
  }

  Future<void> refreshLogs() async {
    _logs = await _storage.loadSmsLogs();
    notifyListeners();
  }

  Future<void> clearLogs() async {
    await _storage.clearSmsLogs();
    _logs = [];
    notifyListeners();
  }

  Future<void> deleteLog(String id) async {
    await _storage.removeSmsLogById(id);
    _logs = _logs.where((e) => e.id != id).toList();
    notifyListeners();
  }

  /// 重试转发该条记录，返回 true 表示已发起重试
  Future<bool> retryLog(SmsLogEntry entry) async {
    return _sms.retryForward(entry.sender, entry.body, entry.apiName);
  }
}
