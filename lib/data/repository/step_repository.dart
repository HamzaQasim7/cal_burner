import 'package:cal_burner/core/services/notification_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/firebase_step_data.dart';

import 'package:pedometer/pedometer.dart';
import '../models/step_data_model.dart';
import '../provider/auth_provider.dart';

enum ActivityIntensity { sedentary, light, moderate, vigorous }

enum Gender { male, female }

class StepRepository {
  final SharedPreferences _prefs;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthenticationProvider _authProvider;
  final NotificationService _notificationService = NotificationService();

  StreamSubscription<StepCount>? _stepCountSubscription;
  StreamSubscription<PedestrianStatus>? _pedestrianStatusSubscription;

  // Stream controllers for broadcasting data
  final _stepCountController = StreamController<int>.broadcast();
  final _stepDataController = StreamController<StepData>.broadcast();
  final _pedestrianStatusController =
      StreamController<PedestrianStatus>.broadcast();

  // Internal state
  int _lastStepCount = 0;
  int _sessionStartStepCount = 0;
  bool _isListening = false;

  StepRepository(this._prefs, this._authProvider) {
    _initializeFromPrefs();
  }

  // Initialize from saved preferences
  void _initializeFromPrefs() {
    _lastStepCount = _prefs.getInt('last_step_count') ?? 0;
    _sessionStartStepCount = _prefs.getInt('session_start_step_count') ?? 0;
  }

  // Get step count stream
  Stream<int>? getStepCountStream() {
    if (!_isListening) {
      startListening();
    }
    return _stepCountController.stream;
  }

  // Get step data stream (with more detailed information)
  Stream<StepData>? getStepDataStream() {
    if (!_isListening) {
      startListening();
    }
    return _stepDataController.stream;
  }

  // Get pedestrian status stream
  Stream<PedestrianStatus>? getPedestrianStatusStream() {
    if (!_isListening) {
      startListening();
    }
    return _pedestrianStatusController.stream;
  }

  // Start listening to pedometer streams
  Future<void> startListening() async {
    if (_isListening) {
      print('Already listening to step count');
      return;
    }

    try {
      print('Starting to listen to pedometer streams...');

      // Listen to step count stream
      _stepCountSubscription = Pedometer.stepCountStream.listen(
        _onStepCount,
        onError: _onStepCountError,
        cancelOnError: false,
      );

      // Listen to pedestrian status stream
      _pedestrianStatusSubscription = Pedometer.pedestrianStatusStream.listen(
        _onPedestrianStatusChanged,
        onError: _onPedestrianStatusError,
        cancelOnError: false,
      );

      _isListening = true;
      print('Started listening to pedometer streams');
    } catch (e) {
      print('Error starting pedometer listeners: $e');
      _isListening = false;
    }
  }

  // Stop listening to pedometer streams
  Future<void> stopListening() async {
    try {
      await _stepCountSubscription?.cancel();
      await _pedestrianStatusSubscription?.cancel();
      _stepCountSubscription = null;
      _pedestrianStatusSubscription = null;
      _isListening = false;
      print('Stopped listening to pedometer streams');
    } catch (e) {
      print('Error stopping pedometer listeners: $e');
    }
  }

  // Handle step count updates
  void _onStepCount(StepCount event) async {
    try {
      final deviceStepCount = event.steps;
      final timestamp = event.timeStamp;

      print('Device step count: $deviceStepCount at $timestamp');

      // Initialize session start if not set
      if (_sessionStartStepCount == 0) {
        _sessionStartStepCount = deviceStepCount;
        await _prefs.setInt('session_start_step_count', _sessionStartStepCount);
        print('Set session start step count: $_sessionStartStepCount');
      }

      // Calculate steps for current session (today)
      final currentSessionSteps = deviceStepCount - _sessionStartStepCount;
      final validSteps = currentSessionSteps < 0 ? 0 : currentSessionSteps;

      // Calculate steps since last update
      final stepsSinceLastUpdate = validSteps - _lastStepCount;

      // Update internal state
      _lastStepCount = validSteps;

      // Save to preferences
      await _saveStepCount(validSteps);

      // Create step data object
      final stepData = StepData(
        timestamp: timestamp,
        stepCount: validSteps,
        stepsSinceLastUpdate: stepsSinceLastUpdate,
      );

      // Calculate calories and distance
      final caloriesBurned = calculateAccurateCaloriesFromSteps(
        steps: validSteps,
        weightKg:
            _authProvider.user?.weight ??
            70, // This should come from user profile
        heightCm:
            _authProvider.user?.height ??
            170, // This should come from user profile
        age:
            _authProvider.user?.age ?? 25, // This should come from user profile
        gender: Gender.male, // This should come from user profile
      );

      final distance = calculateDistanceFromSteps(
        validSteps,
        heightCm:
            _authProvider.user?.height ??
            170, // This should come from user profile
        gender: Gender.male, // This should come from user profile
      );

      // Save to Firebase (you'll need to pass the userId from your auth system)
      await saveStepDataToFirebase(
        userId: _authProvider.user?.id ?? '', // Replace with actual user ID
        steps: validSteps,
        caloriesBurned: caloriesBurned,
        distance: distance,
        metadata: {
          'stepsSinceLastUpdate': stepsSinceLastUpdate,
          'deviceStepCount': deviceStepCount,
          'sessionStartStepCount': _sessionStartStepCount,
        },
      );

      // Broadcast updates
      _stepCountController.add(validSteps);
      _stepDataController.add(stepData);

      print('Current session steps: $validSteps ($stepsSinceLastUpdate new)');

      // Add these notification checks after calculating calories and distance
      // Check for step goal achievement
      final stepGoal = _prefs.getDouble('daily_step_goal') ?? 10000.0;
      if (validSteps >= stepGoal && _lastStepCount < stepGoal) {
        await _notificationService.showStepGoalAchieved(
          steps: validSteps,
          goal: stepGoal.toInt(),
          caloriesBurned: caloriesBurned,
          distance: distance,
        );
      }

      // Check for milestones (every 1000 steps)
      final lastMilestone = _prefs.getInt('last_step_milestone') ?? 0;
      final currentMilestone = (validSteps ~/ 1000) * 1000;
      if (currentMilestone > lastMilestone) {
        await _notificationService.showMilestoneAchieved(
          milestone: '${currentMilestone} Steps!',
          description: 'Congratulations on reaching $currentMilestone steps!',
        );
        await _prefs.setInt('last_step_milestone', currentMilestone);
      }
    } catch (e) {
      print('Error processing step count: $e');
    }
  }

  // Handle step count errors
  void _onStepCountError(error) {
    print('Step count stream error: $error');
    // Implement retry logic if needed
    _retryConnection();
  }

  // Handle pedestrian status changes
  void _onPedestrianStatusChanged(PedestrianStatus event) {
    print('Pedestrian status: ${event.status} at ${event.timeStamp}');
    _pedestrianStatusController.add(event);
  }

  // Handle pedestrian status errors
  void _onPedestrianStatusError(error) {
    print('Pedestrian status stream error: $error');
  }

  // Retry connection after error
  void _retryConnection() async {
    if (_isListening) {
      print('Retrying pedometer connection...');
      await stopListening();
      await Future.delayed(Duration(seconds: 5));
      await startListening();
    }
  }

  // Get current step count
  Future<int> getCurrentStepCount() async {
    try {
      if (!_isListening) {
        await startListening();
        // Wait a moment for first reading
        await Future.delayed(Duration(seconds: 1));
      }
      return _lastStepCount;
    } catch (e) {
      print('Error getting current step count: $e');
      return _prefs.getInt('last_step_count') ?? 0;
    }
  }

  // Save step count to preferences
  Future<void> _saveStepCount(int steps) async {
    try {
      await _prefs.setInt('last_step_count', steps);
      await _prefs.setString(
        'last_step_update',
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      print('Error saving step count: $e');
    }
  }

  // Reset for new day
  Future<void> resetForNewDay() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastResetDate = _prefs.getString('last_reset_date');

      final todayString = today.toIso8601String();

      if (lastResetDate != todayString) {
        print('Resetting step count for new day: $todayString');

        // Reset counters
        _sessionStartStepCount = 0;
        _lastStepCount = 0;

        // Clear saved values
        await _prefs.setInt('session_start_step_count', 0);
        await _prefs.setInt('last_step_count', 0);
        await _prefs.setString('last_reset_date', todayString);

        // Restart listening to establish new baseline
        if (_isListening) {
          await stopListening();
          await startListening();
        }

        print('Step count reset completed');
      }
    } catch (e) {
      print('Error resetting for new day: $e');
    }
  }

  // ============================================================================
  // ENHANCED CALORIE CALCULATION METHODS
  // ============================================================================

  /// Calculate Basal Metabolic Rate (BMR) using Mifflin-St Jeor Equation
  /// This is the most accurate formula currently available
  double calculateBMR({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
  }) {
    double bmr;

    if (gender == Gender.male) {
      // Men: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) + 5
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) + 5;
    } else {
      // Women: BMR = 10 × weight(kg) + 6.25 × height(cm) - 5 × age(years) - 161
      bmr = (10 * weightKg) + (6.25 * heightCm) - (5 * age) - 161;
    }

    return bmr;
  }

  /// Calculate MET (Metabolic Equivalent of Task) based on walking speed
  /// Walking speed is derived from step frequency and stride length
  double calculateMET({
    required int steps,
    required Duration timeElapsed,
    required double heightCm,
  }) {
    if (timeElapsed.inSeconds == 0 || steps == 0) return 1.0; // Resting MET

    // Calculate stride length based on height (more accurate than fixed value)
    // Research shows stride length ≈ height × 0.415 for walking
    double strideLength = heightCm * 0.415 / 100; // Convert to meters

    // Calculate walking speed in km/h
    double distanceKm = (steps * strideLength) / 1000;
    double timeHours = timeElapsed.inSeconds / 3600;
    double speedKmh = distanceKm / timeHours;

    // MET values based on walking speed (from Compendium of Physical Activities)
    if (speedKmh < 2.7) {
      return 2.0; // Very slow walking
    } else if (speedKmh < 3.2) {
      return 2.3; // Slow walking (2.0 mph)
    } else if (speedKmh < 4.0) {
      return 2.9; // Moderate walking (2.5 mph)
    } else if (speedKmh < 4.8) {
      return 3.3; // Brisk walking (3.0 mph)
    } else if (speedKmh < 5.6) {
      return 3.8; // Fast walking (3.5 mph)
    } else if (speedKmh < 6.4) {
      return 4.3; // Very fast walking (4.0 mph)
    } else if (speedKmh < 7.2) {
      return 5.0; // Fast walking (4.5 mph)
    } else {
      return 6.0; // Very fast walking/jogging (5.0+ mph)
    }
  }

  /// Calculate step length based on height and gender (more personalized)
  double calculateStepLength({
    required double heightCm,
    required Gender gender,
  }) {
    // Research-based formulas for step length calculation
    if (gender == Gender.male) {
      return (heightCm * 0.415) / 100; // meters
    } else {
      return (heightCm * 0.413) / 100; // meters (slightly shorter for women)
    }
  }

  /// Calculate calories burned using comprehensive method
  /// This considers BMR, MET, body composition, and activity duration
  double calculateAccurateCaloriesFromSteps({
    required int steps,
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    Duration? activityDuration,
    double? bodyFatPercentage,
  }) {
    if (steps == 0) return 0.0;

    // Use provided duration or estimate based on typical walking pace
    Duration duration =
        activityDuration ??
        Duration(
          minutes: (steps / 100).round(),
        ); // ~100 steps per minute average

    // Calculate BMR
    double bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    // Calculate MET value
    double met = calculateMET(
      steps: steps,
      timeElapsed: duration,
      heightCm: heightCm,
    );

    // Calculate calories per hour at rest
    double bmrPerHour = bmr / 24;

    // Calculate total calories burned per hour during activity
    double caloriesPerHour = bmrPerHour * met;

    // Calculate calories for the actual duration
    double totalCalories = caloriesPerHour * (duration.inMinutes / 60);

    // Adjust for body composition if provided
    if (bodyFatPercentage != null) {
      // People with higher muscle mass burn more calories
      double leanBodyMass = weightKg * (1 - bodyFatPercentage / 100);
      double bodyCompositionFactor = 0.8 + (leanBodyMass / weightKg) * 0.4;
      totalCalories *= bodyCompositionFactor;
    }

    // Apply terrain and efficiency factors (can be customized)
    double terrainFactor = 1.0; // Flat terrain
    double efficiencyFactor = 0.95; // Account for individual efficiency

    totalCalories *= terrainFactor * efficiencyFactor;

    return totalCalories.abs(); // Ensure positive value
  }

  /// Simplified but accurate calorie calculation for basic use
  double calculateCaloriesFromSteps(
    int steps,
    double weightKg, {
    double heightCm = 170.0,
    int age = 30,
    Gender gender = Gender.male,
  }) {
    return calculateAccurateCaloriesFromSteps(
      steps: steps,
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );
  }

  /// Calculate calories burned per step (useful for real-time updates)
  double calculateCaloriesPerStep({
    required double weightKg,
    required double heightCm,
    required int age,
    required Gender gender,
    double walkingSpeedKmh = 4.0, // Default moderate walking speed
  }) {
    // Calculate MET for the given walking speed
    double met;
    if (walkingSpeedKmh < 2.7) {
      met = 2.0;
    } else if (walkingSpeedKmh < 3.2) {
      met = 2.3;
    } else if (walkingSpeedKmh < 4.0) {
      met = 2.9;
    } else if (walkingSpeedKmh < 4.8) {
      met = 3.3;
    } else if (walkingSpeedKmh < 5.6) {
      met = 3.8;
    } else if (walkingSpeedKmh < 6.4) {
      met = 4.3;
    } else {
      met = 5.0;
    }

    // Calculate BMR
    double bmr = calculateBMR(
      weightKg: weightKg,
      heightCm: heightCm,
      age: age,
      gender: gender,
    );

    // Calculate calories per minute
    double caloriesPerMinute = (bmr / 24 / 60) * met;

    // Assume average walking pace of 100 steps per minute
    double caloriesPerStep = caloriesPerMinute / 100;

    return caloriesPerStep;
  }

  /// Get activity intensity based on step rate
  ActivityIntensity getActivityIntensity(int stepsPerMinute) {
    if (stepsPerMinute < 70) {
      return ActivityIntensity.sedentary;
    } else if (stepsPerMinute < 100) {
      return ActivityIntensity.light;
    } else if (stepsPerMinute < 130) {
      return ActivityIntensity.moderate;
    } else {
      return ActivityIntensity.vigorous;
    }
  }

  // ============================================================================
  // ENHANCED DISTANCE CALCULATION METHODS
  // ============================================================================

  /// Calculate distance with personalized step length
  double calculateDistanceFromSteps(
    int steps, {
    required double heightCm,
    required Gender gender,
  }) {
    double stepLength = calculateStepLength(heightCm: heightCm, gender: gender);
    // Convert to kilometers by dividing by 1000
    return (steps * stepLength) / 1000.0; // Now returns distance in kilometers
  }

  /// Calculate distance in kilometers with personalized step length
  double calculateDistanceInKm(
    int steps, {
    required double heightCm,
    required Gender gender,
  }) {
    return calculateDistanceFromSteps(
          steps,
          heightCm: heightCm,
          gender: gender,
        ) /
        1000.0;
  }

  /// Calculate distance in miles with personalized step length
  double calculateDistanceInMiles(
    int steps, {
    required double heightCm,
    required Gender gender,
  }) {
    return calculateDistanceInKm(steps, heightCm: heightCm, gender: gender) *
        0.621371;
  }

  // ============================================================================
  // EXISTING METHODS (kept for compatibility)
  // ============================================================================

  // Calculate average pace (steps per minute)
  double calculateAveragePace(int steps, Duration duration) {
    if (duration.inMinutes == 0) return 0.0;
    return steps / duration.inMinutes;
  }

  // Get step statistics for a time period
  Map<String, dynamic> getStepStatistics(List<StepData> stepDataList) {
    if (stepDataList.isEmpty) {
      return {
        'totalSteps': 0,
        'averageStepsPerHour': 0.0,
        'peakSteps': 0,
        'activeTime': Duration.zero,
      };
    }

    final totalSteps = stepDataList.last.stepCount;
    final timeSpan = stepDataList.last.timestamp.difference(
      stepDataList.first.timestamp,
    );
    final averageStepsPerHour =
        timeSpan.inHours > 0 ? totalSteps / timeSpan.inHours : 0.0;

    int peakSteps = 0;
    for (final data in stepDataList) {
      if (data.stepsSinceLastUpdate > peakSteps) {
        peakSteps = data.stepsSinceLastUpdate;
      }
    }

    return {
      'totalSteps': totalSteps,
      'averageStepsPerHour': averageStepsPerHour,
      'peakSteps': peakSteps,
      'activeTime': timeSpan,
    };
  }

  // Check if service is listening
  bool get isListening => _isListening;

  // Get last saved step count
  int getLastSavedStepCount() {
    return _prefs.getInt('last_step_count') ?? 0;
  }

  // Get last update time
  DateTime? getLastUpdateTime() {
    final timeStr = _prefs.getString('last_step_update');
    return timeStr != null ? DateTime.parse(timeStr) : null;
  }

  // Check if data needs refresh
  bool needsRefresh({Duration threshold = const Duration(minutes: 5)}) {
    final lastUpdate = getLastUpdateTime();
    if (lastUpdate == null) return true;

    final now = DateTime.now();
    return now.difference(lastUpdate) > threshold;
  }

  // Dispose resources
  Future<void> dispose() async {
    await stopListening();
    await _stepCountController.close();
    await _stepDataController.close();
    await _pedestrianStatusController.close();
    print('StepRepository disposed');
  }

  // Add method to save step data to Firebase
  Future<void> saveStepDataToFirebase({
    required String userId,
    required int steps,
    required double caloriesBurned,
    required double distance,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final stepData = FirebaseStepData(
        userId: userId,
        steps: steps,
        caloriesBurned: caloriesBurned,
        distance: distance,
        timestamp: DateTime.now(),
        metadata: metadata,
      );

      // Create a document reference with a custom ID (date-based)
      final date = DateTime.now();
      final docId =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('step_data')
          .doc(docId)
          .set(stepData.toMap(), SetOptions(merge: true));

      print('Step data saved to Firebase successfully');
    } catch (e) {
      print('Error saving step data to Firebase: $e');
    }
  }

  // Add method to get step data from Firebase
  Stream<List<FirebaseStepData>> getStepDataFromFirebase(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('step_data')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => FirebaseStepData.fromMap(doc.data()))
              .toList();
        });
  }

  // Add method to get step data for a specific date range
  Future<List<FirebaseStepData>> getStepDataForDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('step_data')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startDate),
              )
              .where(
                'timestamp',
                isLessThanOrEqualTo: Timestamp.fromDate(endDate),
              )
              .orderBy('timestamp', descending: true)
              .get();

      return snapshot.docs
          .map((doc) => FirebaseStepData.fromMap(doc.data()))
          .toList();
    } catch (e) {
      print('Error getting step data from Firebase: $e');
      return [];
    }
  }

  // Add method to get daily step summary
  Future<Map<String, dynamic>> getDailyStepSummary(
    String userId,
    DateTime date,
  ) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot =
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('step_data')
              .where(
                'timestamp',
                isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
              )
              .where('timestamp', isLessThan: Timestamp.fromDate(endOfDay))
              .get();

      if (snapshot.docs.isEmpty) {
        return {'totalSteps': 0, 'totalCalories': 0.0, 'totalDistance': 0.0};
      }

      int totalSteps = 0;
      double totalCalories = 0.0;
      double totalDistance = 0.0;

      for (var doc in snapshot.docs) {
        final data = FirebaseStepData.fromMap(doc.data());
        totalSteps += data.steps;
        totalCalories += data.caloriesBurned;
        totalDistance += data.distance;
      }

      return {
        'totalSteps': totalSteps,
        'totalCalories': totalCalories,
        'totalDistance': totalDistance,
      };
    } catch (e) {
      print('Error getting daily step summary: $e');
      return {'totalSteps': 0, 'totalCalories': 0.0, 'totalDistance': 0.0};
    }
  }
}
