import 'dart:io' show Platform;

import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'dart:async';
import 'dart:io' show Platform;

import 'package:pedometer/pedometer.dart';
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

      // Get the last saved step count
      final lastStepCount = prefs.getInt('last_step_count') ?? 0;
      final now = DateTime.now();

      // Save current timestamp for background update
      await prefs.setString('last_step_update', now.toIso8601String());

      // Note: In background task, we can't directly access pedometer stream
      // So we'll just update the timestamp to indicate the service is running
      print('Background task executed at: ${now.toIso8601String()}');

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
  static const String initialStepCountKey = 'initial_step_count';
  static const String backgroundTaskName = 'stepCountTask';

  final SharedPreferences _prefs;

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  bool _isInitialized = false;
  int _initialStepCount = 0;
  int _currentStepCount = 0;

  // Stream controllers for broadcasting step data
  final _stepCountController = StreamController<int>.broadcast();
  final _pedestrianStatusController =
      StreamController<PedestrianStatus>.broadcast();

  StepDetectionService(this._prefs);

  // Getters for streams
  Stream<int> get stepCountStream => _stepCountController.stream;
  Stream<PedestrianStatus> get pedestrianStatusStream =>
      _pedestrianStatusController.stream;

  Future<bool> _requestPermissions() async {
    try {
      if (Platform.isAndroid) {
        // Request activity recognition permission for Android
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

        // Request sensors permission (optional but recommended)
        final sensorsStatus = await Permission.sensors.status;
        if (!sensorsStatus.isGranted) {
          await Permission.sensors.request();
        }
      }

      if (Platform.isIOS) {
        // iOS automatically handles motion permissions
        // No explicit permission request needed for pedometer
        print('iOS - Motion permissions handled automatically');
      }

      return true;
    } catch (e) {
      print('Permission request error: $e');
      return false;
    }
  }

  Future<bool> initialize() async {
    try {
      print('Starting pedometer step detection initialization...');

      // Request necessary permissions
      final permissionsGranted = await _requestPermissions();
      if (!permissionsGranted) {
        print('Required permissions not granted');
        return false;
      }

      // Check if pedometer is available
      print('Checking pedometer availability...');

      // Get initial step count from device
      try {
        // The pedometer package provides cumulative step count since device boot
        // We need to establish a baseline
        await _initializeStepCounting();

        _isInitialized = true;
        print('Pedometer initialized successfully');
        return true;
      } catch (e) {
        print('Error initializing pedometer: $e');
        return false;
      }
    } catch (e) {
      print('Error initializing step detection: $e');
      _isInitialized = false;
      return false;
    }
  }

  Future<void> _initializeStepCounting() async {
    try {
      // Start listening to step count stream
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Start listening to pedestrian status stream
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      // Get saved initial step count or set it on first run
      _initialStepCount = _prefs.getInt(initialStepCountKey) ?? 0;
      _currentStepCount = _prefs.getInt(stepCountKey) ?? 0;

      print('Step counting streams initialized');
      print('Initial step count: $_initialStepCount');
      print('Current step count: $_currentStepCount');
    } catch (e) {
      print('Error initializing step counting: $e');
      throw e;
    }
  }

  void _onStepCount(StepCount event) async {
    try {
      print('Step count event: ${event.steps} at ${event.timeStamp}');

      // First time setup - establish baseline
      if (_initialStepCount == 0) {
        _initialStepCount = event.steps;
        await _prefs.setInt(initialStepCountKey, _initialStepCount);
        print('Set initial step count baseline: $_initialStepCount');
      }

      // Calculate today's steps (steps since baseline)
      final todaySteps = event.steps - _initialStepCount;

      // Ensure we don't have negative steps
      final validSteps = todaySteps < 0 ? 0 : todaySteps;

      _currentStepCount = validSteps;

      // Save to preferences
      await saveStepCount(_currentStepCount);

      // Broadcast to listeners
      _stepCountController.add(_currentStepCount);

      print('Today\'s steps: $_currentStepCount');
    } catch (e) {
      print('Error processing step count: $e');
    }
  }

  void _onStepCountError(error) {
    print('Step count stream error: $error');
    // You might want to implement retry logic here
  }

  void _onPedestrianStatusChanged(PedestrianStatus event) {
    print('Pedestrian status: ${event.status} at ${event.timeStamp}');
    _pedestrianStatusController.add(event);
  }

  void _onPedestrianStatusError(error) {
    print('Pedestrian status stream error: $error');
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

      // Return current step count
      return _currentStepCount;
    } catch (e) {
      print('Error getting today steps: $e');
      return getLastStepCount();
    }
  }

  // Reset step count for new day
  Future<void> resetForNewDay() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastResetDate = _prefs.getString('last_reset_date');

      final todayString = today.toIso8601String();

      if (lastResetDate != todayString) {
        print('Resetting step count for new day: $todayString');

        // Reset the baseline to current device step count
        if (_stepCountSubscription != null) {
          // We'll wait for the next step count event to set new baseline
          _initialStepCount = 0;
          _currentStepCount = 0;

          await _prefs.setInt(initialStepCountKey, 0);
          await _prefs.setInt(stepCountKey, 0);
          await _prefs.setString('last_reset_date', todayString);
        }
      }
    } catch (e) {
      print('Error resetting for new day: $e');
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
    return difference.inMinutes >= 5; // Check every 5 minutes
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

  // Get current pedestrian status
  Future<String> getPedestrianStatus() async {
    try {
      // This will return the last known status
      // For real-time status, use the stream
      return 'unknown'; // Pedometer package doesn't provide direct status query
    } catch (e) {
      print('Error getting pedestrian status: $e');
      return 'unknown';
    }
  }

  // Calculate calories burned based on steps
  double calculateCaloriesFromSteps(int steps, double weightKg) {
    // Approximate calculation: 0.04 calories per step per kg of body weight
    return steps * 0.04 * weightKg;
  }

  // Calculate distance from steps
  double calculateDistanceFromSteps(int steps) {
    // Approximate: average step length is 0.7 meters
    const double averageStepLengthMeters = 0.7;
    return steps * averageStepLengthMeters; // Returns distance in meters
  }

  // Calculate distance in kilometers
  double calculateDistanceInKm(int steps) {
    return calculateDistanceFromSteps(steps) / 1000;
  }

  // Check initialization status
  bool get isInitialized => _isInitialized;

  // Force re-initialization
  Future<bool> reinitialize() async {
    await dispose();
    _isInitialized = false;
    return await initialize();
  }

  // Dispose resources
  Future<void> dispose() async {
    await _stepCountSubscription?.cancel();
    await _pedestrianStatusSubscription?.cancel();
    await _stepCountController.close();
    await _pedestrianStatusController.close();
    print('Step detection service disposed');
  }
}

/*

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
 */
