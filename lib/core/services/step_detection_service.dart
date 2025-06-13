import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

// Create a global instance of WorkerManager
final workerManager = Workmanager();

// Define the callback dispatcher at the top level
@pragma('vm:entry-point')
void callbackDispatcher() {
  workerManager.executeTask((task, inputData) async {
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

      return Future.value(true);
    } catch (e) {
      print('Error in background task: $e');
      return Future.value(false);
    }
  });
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

      // Define permissions for each type
      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];

      print('Checking existing health permissions...');
      // First check if we already have permissions
      final hasPermissions = await _health.hasPermissions(
        types,
        permissions: permissions,
      );

      if (hasPermissions == true) {
        print('Already has health permissions');
        return true;
      }

      print('Requesting health permissions...');
      // Request permissions with explicit permission types
      final authorized = await _health.requestAuthorization(
        types,
        permissions: permissions,
      );

      print('Health authorization result: $authorized');

      // Double-check permissions after request
      if (authorized) {
        final verifyPermissions = await _health.hasPermissions(
          types,
          permissions: permissions,
        );
        print('Verified permissions: $verifyPermissions');
        return verifyPermissions == true;
      }

      return false;
    } catch (e) {
      print('Health permission request error: $e');
      return false;
    }
  }

  Future<bool> _requestAndroidPermissions() async {
    try {
      // Check if permissions are already granted
      final activityStatus = await Permission.activityRecognition.status;
      print('Current activity recognition status: $activityStatus');

      if (!activityStatus.isGranted) {
        print('Requesting activity recognition permission...');
        final result = await Permission.activityRecognition.request();
        print('Activity recognition request result: $result');

        if (!result.isGranted) {
          print('Activity recognition permission denied');
          return false;
        }
      }

      // Location permission is optional for Health Connect
      final locationStatus = await Permission.location.status;
      print('Current location status: $locationStatus');

      if (!locationStatus.isGranted) {
        print('Requesting location permission...');
        final result = await Permission.location.request();
        print('Location request result: $result');
        // Location is not required for basic step counting
      }

      return true;
    } catch (e) {
      print('Android permission request error: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    try {
      print('Starting step detection initialization...');

      if (Platform.isAndroid) {
        // Check Health Connect availability
        print('Checking Health Connect availability...');
        final isAvailable = await _health.isHealthConnectAvailable();
        print('Health Connect available: $isAvailable');

        if (!isAvailable) {
          print('Health Connect not available, attempting to install...');
          try {
            await _health.installHealthConnect();
            print('Health Connect installation attempted');

            // Wait a bit for installation to complete
            await Future.delayed(Duration(seconds: 2));

            final isNowAvailable = await _health.isHealthConnectAvailable();
            print('Health Connect available after install: $isNowAvailable');

            if (!isNowAvailable) {
              print('Health Connect still not available after installation');
              throw Exception(
                'Health Connect is not available. Please install it manually from Play Store.',
              );
            }
          } catch (installError) {
            print('Health Connect installation error: $installError');
            throw Exception(
              'Failed to install Health Connect. Please install it manually from Play Store.',
            );
          }
        }

        // Request Android permissions first
        print('Requesting Android permissions...');
        final androidPermissionsGranted = await _requestAndroidPermissions();
        if (!androidPermissionsGranted) {
          print('Android permissions not granted');
          throw Exception('Required Android permissions not granted');
        }
      }

      // Request health permissions
      print('Requesting health permissions...');
      final healthPermissionsGranted = await _requestHealthPermissions();
      if (!healthPermissionsGranted) {
        print('Health permissions not granted');
        throw Exception(
          'Health permissions not granted. Please allow access in Health Connect app.',
        );
      }

      print('Step detection initialized successfully');
      _isInitialized = true;
      return true;
    } catch (e) {
      print('Error initializing step detection: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<int> getTodaySteps() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) {
          print('Failed to initialize, returning last saved step count');
          return getLastStepCount();
        }
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      print('Getting steps from $midnight to $now');

      // Get steps from health service
      final steps = await _health.getTotalStepsInInterval(midnight, now);
      print('Retrieved steps: $steps');

      if (steps != null && steps >= 0) {
        await saveStepCount(steps);
        return steps;
      } else {
        print('No step data received, returning last saved count');
        return getLastStepCount();
      }
    } catch (e) {
      print('Error getting today steps: $e');
      return getLastStepCount();
    }
  }

  // Alternative method to get steps using health data points
  Future<int> getTodayStepsAlternative() async {
    try {
      if (!_isInitialized) {
        final initialized = await initialize();
        if (!initialized) return getLastStepCount();
      }

      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      // Get health data points
      final healthData = await _health.getHealthDataFromTypes(
        startTime: midnight,
        endTime: now,
        types: [HealthDataType.STEPS],
      );

      if (healthData.isNotEmpty) {
        int totalSteps = 0;
        for (final data in healthData) {
          if (data.value is NumericHealthValue) {
            totalSteps +=
                (data.value as NumericHealthValue).numericValue.toInt();
          }
        }
        await saveStepCount(totalSteps);
        return totalSteps;
      }

      return getLastStepCount();
    } catch (e) {
      print('Error getting steps alternative method: $e');
      return getLastStepCount();
    }
  }

  // Save current step count
  Future<void> saveStepCount(int steps) async {
    try {
      await _prefs.setInt(stepCountKey, steps);
      await _prefs.setString(lastUpdateKey, DateTime.now().toIso8601String());
      print('Saved step count: $steps');
    } catch (e) {
      print('Error saving step count: $e');
    }
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
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);

      await Workmanager().registerPeriodicTask(
        'periodicStepCount',
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
      print('Periodic step counting started');
    } catch (e) {
      print('Error starting periodic step counting: $e');
    }
  }

  // Stop periodic step counting
  Future<void> stopPeriodicStepCounting() async {
    try {
      await Workmanager().cancelByUniqueName('periodicStepCount');
      print('Periodic step counting stopped');
    } catch (e) {
      print('Error stopping periodic step counting: $e');
    }
  }

  // Check initialization status
  bool get isInitialized => _isInitialized;

  // Force re-initialization
  Future<bool> reinitialize() async {
    _isInitialized = false;
    return await initialize();
  }
}
