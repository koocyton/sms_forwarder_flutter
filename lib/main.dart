import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import 'l10n/translation_service.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'services/sms_forward_service.dart';
import 'services/tip_service.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  late final AppState _appState;
  final TipService _tipService = TipService.instance;

  @override
  void initState() {
    super.initState();
    _appState = AppState()..load();
    _tipService.init();
    SmsForwardService.onLogAdded = () => _appState.refreshLogs();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _appState.refreshLogs();
      _tipService.resetIfStuck();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appState),
        ChangeNotifierProvider.value(value: _tipService),
      ],
      child: GetMaterialApp(
        title: 'App:Title'.tr,
        debugShowCheckedModeBanner: false,
        translations: TranslationService(),
        fallbackLocale: TranslationService.fallbackLocale,
        locale: Get.deviceLocale ?? TranslationService.fallbackLocale,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF2563EB),
            brightness: Brightness.light,
            primary: const Color(0xFF2563EB),
            secondary: const Color(0xFF7C3AED),
          ),
          useMaterial3: true,
          cardTheme: CardThemeData(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
