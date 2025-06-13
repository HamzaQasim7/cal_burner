import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/src/workmanager.dart';
import 'package:workmanager/workmanager.dart';

// Create a global instance of WorkerManager
final workerManager = Workmanager();

// Define the callback dispatcher at the top level
@pragma('vm:entry-point')
void callbackDispatcher() {
  workerManager.executeTask(
    () {
          try {
            final prefs = SharedPreferences.getInstance();
            final health = Health();

            // Get steps for today
            final now = DateTime.now();
            final midnight = DateTime(now.year, now.month, now.day);
            final steps = health.getTotalStepsInInterval(midnight, now);

            // Save steps
            prefs.then((preferences) {
              preferences.setInt('last_step_count', steps as int);
              preferences.setString('last_step_update', now.toIso8601String());
            });

            return true;
          } catch (e) {
            print('Error in background task: $e');
            return false;
          }
        }
        as BackgroundTaskHandler,
    // priority: Priority.high,
    // taskName: 'backgroundStepCount',
    // retryCount: 3,
    // retryDelay: const Duration(minutes: 15),
  );
}

class StepDetectionService {
  static const String stepCountKey = 'last_step_count';
  static const String lastUpdateKey = 'last_step_update';
  static const String backgroundTaskName = 'stepCountTask';

  final Health _health = Health();
  final SharedPreferences _prefs;
  bool _isInitialized = false;

  StepDetectionService(this._prefs);

  Future<bool> _requestHealthPermissions() async {
    try {
      // Define the types of health data we want to access
      final types = [
        HealthDataType.STEPS,
        HealthDataType.DISTANCE_DELTA,
        HealthDataType.ACTIVE_ENERGY_BURNED,
      ];

      // First check if we already have permissions
      final hasPermissions = await _health.hasPermissions(types);
      if (hasPermissions == true) {
        print('Already has health permissions');
        return true;
      }

      // If not, request them
      print('Requesting health permissions...');
      final authorized = await _health.requestAuthorization(types);
      print('Health authorization result: $authorized');

      if (!authorized) {
        print('Health data access not authorized');
        return false;
      }

      return true;
    } catch (e) {
      print('Health permission request error: $e');
      return false;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    try {
      // Request activity recognition permission
      final activityStatus = await Permission.activityRecognition.request();
      print('Activity recognition status: ${activityStatus.isGranted}');

      if (!activityStatus.isGranted) {
        print('Activity recognition permission not granted');
        return false;
      }

      // Request location permissions
      final locationStatus = await Permission.location.request();
      print('Location status: ${locationStatus.isGranted}');

      if (!locationStatus.isGranted) {
        print('Location permission not granted');
        return false;
      }

      return true;
    } catch (e) {
      print('Android permission request error: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    try {
      if (Platform.isAndroid) {
        // First check if Health Connect is available
        final isAvailable = await _health.isHealthConnectAvailable();
        print('Health Connect available: $isAvailable');

        if (!isAvailable) {
          print('Health Connect not available, attempting to install');
          // Try to install Health Connect
          await _health.installHealthConnect();
          print('Health Connect installation attempted');

          // Verify Health Connect is now available
          final isNowAvailable = await _health.isHealthConnectAvailable();
          if (!isNowAvailable) {
            print(
              'Health Connect still not available after installation attempt',
            );
            throw Exception('Health Connect is not available');
          }
        }

        // Request Android-specific permissions first
        final androidPermissionsGranted = await _requestAndroidPermissions();
        if (!androidPermissionsGranted) {
          print('Android permissions not granted');
          throw Exception('Android permissions not granted');
        }
      }

      // Request health permissions
      final healthPermissionsGranted = await _requestHealthPermissions();
      if (!healthPermissionsGranted) {
        print('Health permissions not granted');
        throw Exception('Health permissions not granted');
      }

      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing step detection: $e');
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Get steps from health service
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      if (steps != null) await saveStepCount(steps);

      return steps ?? 0;
    } catch (e) {
      print('Error getting today steps: $e');
      return getLastStepCount();
    }
  }

  // Save current step count
  Future<void> saveStepCount(int steps) async {
    await _prefs.setInt(stepCountKey, steps);
    await _prefs.setString(lastUpdateKey, DateTime.now().toIso8601String());
  }

  // Get last saved step count
  int getLastStepCount() {
    return _prefs.getInt(stepCountKey) ?? 0;
  }

  // Get last update time
  DateTime? getLastUpdateTime() {
    final timeStr = _prefs.getString(lastUpdateKey);
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  // Check if step count needs update
  bool needsUpdate() {
    final lastUpdate = getLastUpdateTime();
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    final difference = now.difference(lastUpdate);
    return difference.inMinutes >= 15;
  }

  // Start periodic step counting
  Future<void> startPeriodicStepCounting() async {
    try {
      await Workmanager().registerPeriodicTask(
        '2',
        'periodicStepCount',
        frequency: const Duration(minutes: 15),
        constraints: Constraints(
          networkType: NetworkType.not_required,
          requiresBatteryNotLow: false,
          requiresCharging: false,
          requiresDeviceIdle: false,
          requiresStorageNotLow: false,
        ),
      );
    } catch (e) {
      print('Error starting periodic step counting: $e');
    }
  }

  // Stop periodic step counting
  Future<void> stopPeriodicStepCounting() async {
    try {
      await Workmanager().cancelByUniqueName('periodicStepCount');
    } catch (e) {
      print('Error stopping periodic step counting: $e');
    }
  }
}
