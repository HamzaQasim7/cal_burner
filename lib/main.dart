import 'package:cal_burner/core/services/step_detection_service.dart';
import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:cal_burner/data/provider/activity_provider.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/data/provider/language_provider.dart';
import 'package:cal_burner/data/provider/session_manager.dart';
import 'package:cal_burner/data/provider/theme_provider.dart';
import 'package:cal_burner/presentation/auth/session_wrapper.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

import 'firebase_options.dart';

// Define the callback dispatcher at the top level
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == 'stepCountTask' || task == 'periodicStepCount') {
      try {
        final prefs = await SharedPreferences.getInstance();
        final health = Health();

        // Get steps for today
        final now = DateTime.now();
        final midnight = DateTime(now.year, now.month, now.day);
        final steps = await health.getTotalStepsInInterval(midnight, now);

        // Save steps
        await prefs.setInt('last_step_count', steps ?? 0);
        await prefs.setString('last_step_update', now.toIso8601String());

        return true;
      } catch (e) {
        print('Error in background task: $e');
        return false;
      }
    }
    return false;
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await EasyLocalization.ensureInitialized();
  final authProvider = AuthenticationProvider();
  await authProvider.initialize();
  // Initialize Workmanager
  await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

  final prefs = await SharedPreferences.getInstance();
  // Initialize StepDetectionService
  final stepService = StepDetectionService(prefs);
  await stepService.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('es'), Locale('de')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
          ChangeNotifierProvider(create: (_) => LanguageProvider()),
          ChangeNotifierProvider(create: (_) => SessionManager(prefs: prefs)),
          ChangeNotifierProvider(create: (_) => AuthenticationProvider()),
          ChangeNotifierProvider(create: (_) => ActivityProvider(prefs)),
          ChangeNotifierProvider.value(value: authProvider),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, LanguageProvider>(
      builder: (context, themeProvider, languageProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Calories Burner',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeProvider.themeMode,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: languageProvider.currentLocale,
          home: SessionWrapper(),
        );
      },
    );
  }
}
