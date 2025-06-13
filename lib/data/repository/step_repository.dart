import 'package:cal_burner/core/services/step_detection_service.dart';
import 'package:health/health.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StepRepository {
  late StepDetectionService _stepService;
  bool _isInitialized = false;
  Stream<int>? _stepCountStream;

  StepRepository() {
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _stepService = StepDetectionService(prefs);
    _isInitialized = await _stepService.initialize();
  }

  // Initialize step counting
  Future<bool> initializeStepCounting() async {
    if (!_isInitialized) {
      _isInitialized = await _stepService.initialize();
    }
    return _isInitialized;
  }

  // Get current step count
  Future<int> getCurrentStepCount() async {
    if (!_isInitialized) {
      await _initialize();
    }

    if (_stepService.needsUpdate()) {
      final steps = await _stepService.getTodaySteps();
      await _stepService.saveStepCount(steps);
      return steps;
    }

    return _stepService.getLastStepCount();
  }

  // Get step count stream
  Stream<int>? getStepCountStream() {
    if (!_isInitialized) return null;

    _stepCountStream ??= Stream.periodic(
      const Duration(minutes: 15),
      (_) async {
        final steps = await getCurrentStepCount();
        return steps;
      },
    ).asyncMap((future) => future);

    return _stepCountStream;
  }

  // Calculate calories from steps
  double calculateCaloriesFromSteps(int steps, double weight) {
    // Average stride length in meters
    const strideLength = 0.762;
    // Calories burned per km (average)
    const caloriesPerKm = 60.0;

    final distanceInKm = (steps * strideLength) / 1000;
    return distanceInKm * caloriesPerKm * (weight / 70.0);
  }

  // Calculate distance from steps
  double calculateDistanceFromSteps(int steps) {
    // Average stride length in meters
    const strideLength = 0.762;
    return (steps * strideLength) / 1000; // Convert to kilometers
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
    if (!_isInitialized) {
      await _initialize();
    }
    return _stepService.getTodaySteps();
  }

  // Save step count
  Future<void> saveStepCount(int steps) async {
    if (!_isInitialized) {
      await _initialize();
    }
    await _stepService.saveStepCount(steps);
  }
}
