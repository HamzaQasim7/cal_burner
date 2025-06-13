import 'package:cal_burner/core/services/step_detection_service.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepRepository {
  late StepDetectionService _stepService;
  bool _isInitialized = false;
  Stream<int>? _stepCountStream;
  final SharedPreferences _prefs;

  StepRepository(this._prefs) {
    _initialize();
  }

  Future<void> _initialize() async {
    _stepService = StepDetectionService(_prefs);
    _isInitialized = await _stepService.initialize();
  }

  // Initialize step counting with Health Connect check
  Future<bool> initializeStepCounting() async {
    try {
      if (!_isInitialized) {
        _isInitialized = await _stepService.initialize();
      }

      if (!_isInitialized) {
        throw Exception('Failed to initialize step counting. Please install Health Connect.');
      }

      // Start listening to step count changes
      _stepCountStream = Stream.periodic(
        const Duration(minutes: 5),
        (_) => getCurrentStepCount(),
      ).asyncMap((future) => future);

      return true;
    } catch (e) {
      print('Error initializing step counting: $e');
      return false;
    }
  }

  // Get current step count
  Future<int> getCurrentStepCount() async {
    try {
      if (!_isInitialized) {
        _isInitialized = await _stepService.initialize();
      }

      // Get steps from health service
      final health = Health();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      final steps = await health.getTotalStepsInInterval(midnight, now);
      if (steps != null) {
        await saveStepCount(steps);
      }
      
      return steps ?? 0;
    } catch (e) {
      print('Error getting step count: $e');
      return _stepService.getLastStepCount();
    }
  }

  // Get step count stream
  Stream<int> getStepCountStream() {
    if (!_isInitialized) {
      return Stream.error('Step counting not initialized');
    }

    _stepCountStream ??= Stream.periodic(
      const Duration(minutes: 5),
      (_) => getCurrentStepCount(),
    ).asyncMap((future) => future);

    return _stepCountStream!;
  }

  // Calculate calories from steps
  double calculateCaloriesFromSteps(int steps, double weight) {
    const strideLength = 0.762; // meters
    const caloriesPerKm = 60.0; // base calories per km
    const baseWeight = 70.0; // reference weight

    final distanceInKm = (steps * strideLength) / 1000;
    final weightFactor = weight / baseWeight;
    final calories = distanceInKm * caloriesPerKm * weightFactor;
    final bmrContribution = (steps / 1000) * 0.5;

    return calories + bmrContribution;
  }

  // Calculate distance from steps
  double calculateDistanceFromSteps(int steps) {
    const strideLength = 0.762; // meters
    return (steps * strideLength) / 1000; // Convert to kilometers
  }

  // Save step count
  Future<void> saveStepCount(int steps) async {
    try {
      await _stepService.saveStepCount(steps);
    } catch (e) {
      print('Error saving step count: $e');
    }
  }

  // Get last update time
  DateTime? getLastUpdateTime() {
    return _stepService.getLastUpdateTime();
  }

  // Check if step count needs update
  bool needsUpdate() {
    return _stepService.needsUpdate();
  }

  // Start periodic step counting
  Future<void> startPeriodicStepCounting() async {
    if (!_isInitialized) {
      await _initialize();
    }
    await _stepService.startPeriodicStepCounting();
  }

  // Stop periodic step counting
  Future<void> stopPeriodicStepCounting() async {
    await _stepService.stopPeriodicStepCounting();
  }

  // Get today's steps
  Future<int> getTodaySteps() async {
    try {
      if (!_isInitialized) {
        await _initialize();
      }

      final health = Health();
      final now = DateTime.now();
      final midnight = DateTime(now.year, now.month, now.day);

      return await health.getTotalStepsInInterval(midnight, now) ?? 0;
    } catch (e) {
      print('Error getting today steps: $e');
      return _stepService.getLastStepCount();
    }
  }
}
