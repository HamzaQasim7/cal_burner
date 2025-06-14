import 'dart:async';

import 'package:cal_burner/data/models/step_data_model.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/step_detection_service.dart';
import '../models/daily_activity_model.dart';
import '../models/weekly_summary_model.dart';
import '../repository/activity_repository.dart';
import '../repository/step_repository.dart';

class ActivityProvider with ChangeNotifier {
  final ActivityRepository _activityRepository;
  final StepRepository _stepRepository;
  final SharedPreferences _prefs;
  final AuthenticationProvider _authProvider;

  ActivityProvider(this._prefs, this._authProvider)
    : _activityRepository = ActivityRepository(_prefs),
      _stepRepository = StepRepository(_prefs, _authProvider) {
    loadStepGoal();
  }

  DailyActivity? _todayActivity;
  List<DailyActivity> _weeklyActivities = [];
  List<DailyActivity> _monthlyActivities = [];
  List<DailyActivity> _yearlyActivities = [];
  bool _isLoading = false;
  String? _error;
  bool _isStepCountingInitialized = false;
  String? _userId;
  StreamSubscription<int>? _stepCountSubscription;
  StreamSubscription<StepData>? _stepDataSubscription;

  // Add step goal state
  double _stepGoal = 10000.0;

  // Getters
  DailyActivity? get todayActivity => _todayActivity;

  List<DailyActivity> get weeklyActivities => _weeklyActivities;

  List<DailyActivity> get monthlyActivities => _monthlyActivities;
  List<DailyActivity> get yearlyActivities => _yearlyActivities;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isStepCountingInitialized => _isStepCountingInitialized;
  User? get currentUser => FirebaseAuth.instance.currentUser;

  // Add getter for step goal
  double get stepGoal => _stepGoal;

  // Set user ID (call this when user logs in)
  void setUserId(String userId) {
    _userId = userId;
    notifyListeners();
  }

  // Initialize step counting
  Future<void> initializeStepCounting() async {
    if (_userId == null) {
      setUserId(currentUser?.uid ?? '');
      if (_userId == null) {
        _setError('User not authenticated');
        return;
      }
    }

    _setLoading(true);
    _clearError();

    try {
      print('Initializing step counting for user: $_userId');

      // Start listening to step count stream
      _stepCountSubscription?.cancel();
      _stepCountSubscription = _stepRepository.getStepCountStream()?.listen(
        (steps) async {
          print('Received step update: $steps');
          await _updateStepCount(steps);
        },
        onError: (error) {
          print('Step count stream error: $error');
          _setError('Step counting error: $error');
        },
      );

      // Start listening to detailed step data stream
      _stepDataSubscription?.cancel();
      _stepDataSubscription = _stepRepository.getStepDataStream()?.listen(
        (stepData) async {
          print('Received detailed step data: ${stepData.stepCount} steps');
          await _updateStepCount(stepData.stepCount);
        },
        onError: (error) {
          print('Step data stream error: $error');
          _setError('Step data error: $error');
        },
      );

      // Get initial step count
      final initialSteps = await _stepRepository.getCurrentStepCount();
      print('Initial step count: $initialSteps');

      if (initialSteps > 0) {
        await _updateStepCount(initialSteps);
      }

      _isStepCountingInitialized = true;
      print('Step counting initialized successfully');
      notifyListeners();
    } catch (e) {
      print('Error initializing step counting: $e');
      _setError('Failed to initialize step counting: ${e.toString()}');
      _isStepCountingInitialized = false;
    } finally {
      _setLoading(false);
    }
  }

  // Add a method to retry initialization
  Future<void> retryStepCountingInitialization() async {
    print('Retrying step counting initialization...');
    _isStepCountingInitialized = false;
    await initializeStepCounting();
  }

  // Listen to step count changes
  void _listenToStepCount() {
    _stepRepository.getStepCountStream()?.listen(
      (steps) {
        _updateStepCount(steps);
      },
      onError: (error) {
        print('Step count error: $error');
        _setError('Step counting error: $error');
      },
    );
  }

  // Handle background updates
  Future<void> handleBackgroundUpdate() async {
    if (_userId == null) return;

    try {
      final currentSteps = await _stepRepository.getCurrentStepCount();
      await _updateStepCount(currentSteps);
    } catch (e) {
      print('Error handling background update: $e');
    }
  }

  // Helper method to get user's physical attributes
  Map<String, dynamic> _getUserPhysicalAttributes() {
    final user = _authProvider.user;
    if (user == null) {
      // Return default values if user is not available
      return {
        'weight': 70.0,
        'height': 170.0,
        'age': 30,
        'gender': Gender.male,
        'bodyFatPercentage': null,
      };
    }

    // Convert string gender to enum
    Gender gender = Gender.male; // default
    if (user.gender != null) {
      gender =
          user.gender!.toLowerCase() == 'female' ? Gender.female : Gender.male;
    }

    return {
      'weight': user.weight ?? 70.0,
      'height': user.height ?? 170.0,
      'age': user.age ?? 30,
      'gender': gender,
      'bodyFatPercentage': user.bodyFatPercentage,
    };
  }

  // Update step count
  Future<void> _updateStepCount(int steps) async {
    if (_userId == null) return;

    try {
      if (_todayActivity == null) {
        await _loadTodayActivityInternal();
      }

      if (_todayActivity != null) {
        // Get user's physical attributes
        final attributes = _getUserPhysicalAttributes();

        // Calculate calories using enhanced method with user's attributes
        final calories = _stepRepository.calculateAccurateCaloriesFromSteps(
          steps: steps,
          weightKg: attributes['weight'],
          heightCm: attributes['height'],
          age: attributes['age'],
          gender: attributes['gender'],
          bodyFatPercentage: attributes['bodyFatPercentage'],
        );

        // Calculate distance using enhanced method with user's attributes
        final distance = _stepRepository.calculateDistanceFromSteps(
          steps,
          heightCm: attributes['height'],
          gender: attributes['gender'],
        );

        final updatedActivity = _todayActivity!.copyWith(
          steps: steps,
          caloriesBurned: calories,
          distance: distance,
          updatedAt: DateTime.now(),
        );

        await _updateTodayActivity(updatedActivity);
      }
    } catch (e) {
      print('Error updating step count: $e');
      _setError('Failed to update step count: $e');
    }
  }

  // Load today's activity (public method)
  Future<void> loadTodayActivity() async {
    if (_userId == null) {
      _setError('User not logged in');
      return;
    }

    if (_isLoading) return; // Prevent multiple simultaneous loads

    _setLoading(true);
    _clearError();

    try {
      await _loadTodayActivityInternal();
    } catch (e) {
      _setError('Failed to load today activity: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Internal method to load today's activity
  Future<void> _loadTodayActivityInternal() async {
    if (_userId == null) return;

    _todayActivity = await _activityRepository.getTodayActivity(_userId!);

    // If no activity exists for today, create one
    if (_todayActivity == null) {
      await _createTodayActivity(_userId!);
    }

    notifyListeners();
  }

  // Create today's activity
  Future<void> _createTodayActivity(String userId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);

    _todayActivity = DailyActivity(
      id: '${userId}_${todayStart.millisecondsSinceEpoch}',
      userId: userId,
      date: todayStart,
      steps: 0,
      caloriesBurned: 0.0,
      distance: 0.0,
      activeMinutes: 0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _activityRepository.saveDailyActivity(_todayActivity!);
  }

  // Update today's activity
  Future<void> _updateTodayActivity(DailyActivity activity) async {
    try {
      await _activityRepository.updateTodayActivity(activity);
      _todayActivity = activity;
      notifyListeners();
    } catch (e) {
      _setError('Failed to update activity: $e');
    }
  }

  // Manually update activity data (for manual entries)
  Future<void> updateActivityData({
    int? steps,
    double? caloriesBurned,
    double? distance,
    int? activeMinutes,
  }) async {
    if (_todayActivity == null || _userId == null) {
      await loadTodayActivity();
    }

    if (_todayActivity != null) {
      final updatedActivity = _todayActivity!.copyWith(
        steps: steps ?? _todayActivity!.steps,
        caloriesBurned: caloriesBurned ?? _todayActivity!.caloriesBurned,
        distance: distance ?? _todayActivity!.distance,
        activeMinutes: activeMinutes ?? _todayActivity!.activeMinutes,
        updatedAt: DateTime.now(),
      );

      await _updateTodayActivity(updatedActivity);
    }
  }

  // Load weekly activities
  Future<void> loadWeeklyActivities() async {
    if (_userId == null) {
      _setError('User not logged in');
      return;
    }

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    _setLoading(true);
    _clearError();

    try {
      _weeklyActivities = await _activityRepository.getWeeklyActivities(
        _userId!,
        weekStartDate,
      );

      // Sort activities by date to ensure proper ordering
      _weeklyActivities.sort((a, b) => a.date.compareTo(b.date));

      notifyListeners();
    } catch (e) {
      _setError('Failed to load weekly activities: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Future<void> loadWeeklyActivitie() async {
  //   if (_userId == null) {
  //     _setError('User not logged in');
  //     return;
  //   }
  //
  //   final now = DateTime.now();
  //   final weekStart = now.subtract(Duration(days: now.weekday - 1));
  //   final weekStartDate = DateTime(
  //     weekStart.year,
  //     weekStart.month,
  //     weekStart.day,
  //   );
  //
  //   _setLoading(true);
  //   _clearError();
  //
  //   try {
  //     _weeklyActivities = await _activityRepository.getWeeklyActivities(
  //       _userId!,
  //       weekStartDate,
  //     );
  //     notifyListeners();
  //   } catch (e) {
  //     _setError('Failed to load weekly activities: $e');
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Load monthly activities
  Future<void> loadMonthlyActivities() async {
    if (_userId == null) {
      _setError('User not logged in');
      return;
    }

    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    _setLoading(true);
    _clearError();

    try {
      _monthlyActivities = await _activityRepository.getMonthlyActivities(
        _userId!,
        monthStart,
      );

      // Debug: Print monthly activities for verification
      print('Loaded ${_monthlyActivities.length} monthly activities');
      for (var activity in _monthlyActivities) {
        print('Date: ${activity.date}, Calories: ${activity.caloriesBurned}');
      }

      notifyListeners();
    } catch (e) {
      print('Error loading monthly activities: $e');
      _setError('Failed to load monthly activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Load yearly activities
  Future<void> loadYearlyActivities() async {
    if (_userId == null) {
      _setError('User not logged in');
      return;
    }

    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);

    _setLoading(true);
    _clearError();

    try {
      _yearlyActivities = await _activityRepository.getYearlyActivities(
        _userId!,
        yearStart,
      );
      notifyListeners();
    } catch (e) {
      _setError('Failed to load yearly activities: $e');
    } finally {
      _setLoading(false);
    }
  }
  // Future<void> loadMonthlyActivitie() async {
  //   if (_userId == null) {
  //     _setError('User not logged in');
  //     return;
  //   }
  //
  //   final now = DateTime.now();
  //   final monthStart = DateTime(now.year, now.month, 1);
  //
  //   _setLoading(true);
  //   _clearError();
  //
  //   try {
  //     _monthlyActivities = await _activityRepository.getMonthlyActivities(
  //       _userId!,
  //       monthStart,
  //     );
  //     notifyListeners();
  //   } catch (e) {
  //     _setError('Failed to load monthly activities: $e');
  //   } finally {
  //     _setLoading(false);
  //   }
  // }

  // Get weekly summary
  WeeklySummary getWeeklySummary() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    // Ensure activities are sorted by date
    final sortedActivities = List<DailyActivity>.from(_weeklyActivities)
      ..sort((a, b) => a.date.compareTo(b.date));

    final totalSteps = sortedActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.steps,
    );
    final totalCalories = sortedActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.caloriesBurned,
    );
    final totalDistance = sortedActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.distance,
    );
    final totalActiveMinutes = sortedActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.activeMinutes,
    );

    return WeeklySummary(
      weekStartDate: weekStartDate,
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalDistance: totalDistance,
      totalActiveMinutes: totalActiveMinutes,
      dailyActivities: sortedActivities,
    );
  }

  // Get yearly summary
  Map<String, dynamic> getYearlySummary() {
    if (_yearlyActivities.isEmpty) {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays + 1;

      return {
        'totalSteps': 0,
        'totalCalories': 0.0,
        'totalDistance': 0.0,
        'totalActiveMinutes': 0,
        'averageStepsPerDay': 0,
        'averageCaloriesPerDay': 0.0,
        'activeDays': 0,
        'daysInYear': dayOfYear,
      };
    }

    final totalSteps = _yearlyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.steps,
    );
    final totalCalories = _yearlyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.caloriesBurned,
    );
    final totalDistance = _yearlyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.distance,
    );
    final totalActiveMinutes = _yearlyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.activeMinutes,
    );

    final activeDays =
        _yearlyActivities.where((activity) => activity.steps > 0).length;
    final averageSteps = activeDays > 0 ? (totalSteps / activeDays).round() : 0;
    final averageCalories = activeDays > 0 ? totalCalories / activeDays : 0.0;

    return {
      'totalSteps': totalSteps,
      'totalCalories': totalCalories,
      'totalDistance': totalDistance,
      'totalActiveMinutes': totalActiveMinutes,
      'averageStepsPerDay': averageSteps,
      'averageCaloriesPerDay': averageCalories,
      'activeDays': activeDays,
      'daysInYear': _yearlyActivities.length,
    };
  }

  Future<void> initializeDashboard() async {
    if (_userId == null) {
      _setError('User not logged in');
      return;
    }

    _setLoading(true);
    _clearError();

    try {
      // Load all required data
      await Future.wait([
        loadTodayActivity(),
        loadWeeklyActivities(),
        loadMonthlyActivities(),
      ]);
    } catch (e) {
      _setError('Failed to initialize dashboard: $e');
    } finally {
      _setLoading(false);
    }
  }

  Map<String, dynamic> getWeeklyProgress() {
    final summary = getWeeklySummary();
    final averageSteps =
        summary.dailyActivities.isNotEmpty ? summary.totalSteps / 7 : 0;

    final stepGoalAchievedDays =
        summary.dailyActivities
            .where((activity) => activity.steps >= _stepGoal)
            .length;

    return {
      'averageStepsPerDay': averageSteps,
      'stepGoalAchievedDays': stepGoalAchievedDays,
      'totalActiveDays':
          summary.dailyActivities
              .where((activity) => activity.steps > 0)
              .length,
      'weeklyStepGoal': _stepGoal * 7,
      'weeklyGoalProgress': (summary.totalSteps / (_stepGoal * 7)).clamp(
        0.0,
        1.0,
      ),
    };
  }

  DailyActivity? getDayActivity(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);

    try {
      return _weeklyActivities.firstWhere((activity) {
        final activityDate = DateTime(
          activity.date.year,
          activity.date.month,
          activity.date.day,
        );
        return activityDate == dateOnly;
      });
    } catch (e) {
      return null;
    }
  }

  // Get monthly summary
  Map<String, dynamic> getMonthlySummary() {
    if (_monthlyActivities.isEmpty) {
      return {
        'totalSteps': 0,
        'totalCalories': 0.0,
        'totalDistance': 0.0,
        'totalActiveMinutes': 0,
        'averageStepsPerDay': 0,
        'averageCaloriesPerDay': 0.0,
        'activeDays': 0,
        'daysInMonth': DateTime.now().day,
      };
    }

    final totalSteps = _monthlyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.steps,
    );
    final totalCalories = _monthlyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.caloriesBurned,
    );
    final totalDistance = _monthlyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.distance,
    );
    final totalActiveMinutes = _monthlyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.activeMinutes,
    );

    final activeDays =
        _monthlyActivities.where((activity) => activity.steps > 0).length;
    final averageSteps = activeDays > 0 ? (totalSteps / activeDays).round() : 0;
    final averageCalories = activeDays > 0 ? totalCalories / activeDays : 0.0;

    return {
      'totalSteps': totalSteps,
      'totalCalories': totalCalories,
      'totalDistance': totalDistance,
      'totalActiveMinutes': totalActiveMinutes,
      'averageStepsPerDay': averageSteps,
      'averageCaloriesPerDay': averageCalories,
      'activeDays': activeDays,
      'daysInMonth': _monthlyActivities.length,
    };
  }

  // Get today's step progress (percentage towards goal)
  double getStepProgress({int stepGoal = 10000}) {
    if (_todayActivity == null) return 0.0;
    return (_todayActivity!.steps / stepGoal).clamp(0.0, 1.0);
  }

  // Get today's calorie progress
  double getCalorieProgress({double calorieGoal = 2000}) {
    if (_todayActivity == null) return 0.0;
    return (_todayActivity!.caloriesBurned / calorieGoal).clamp(0.0, 1.0);
  }

  // Reset all data (useful for logout)
  void reset() {
    _todayActivity = null;
    _weeklyActivities.clear();
    _monthlyActivities.clear();
    _isLoading = false;
    _error = null;
    _isStepCountingInitialized = false;
    _userId = null;
    notifyListeners();
  }

  // Refresh all data
  Future<void> refreshAllData() async {
    if (_userId == null) return;

    _setLoading(true);
    _clearError();

    try {
      await Future.wait([
        loadTodayActivity(),
        loadWeeklyActivities(),
        loadMonthlyActivities(),
      ]);
    } catch (e) {
      _setError('Failed to refresh data: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Helper methods for state management
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _setError(String error) {
    if (_error != error) {
      _error = error;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }

  // Add method to get activity intensity
  ActivityIntensity getCurrentActivityIntensity() {
    if (_todayActivity == null) return ActivityIntensity.sedentary;

    final lastUpdate = _todayActivity!.updatedAt;
    final now = DateTime.now();
    final minutesElapsed = now.difference(lastUpdate).inMinutes;

    if (minutesElapsed == 0) return ActivityIntensity.sedentary;

    final stepsPerMinute = _todayActivity!.steps / minutesElapsed;
    return _stepRepository.getActivityIntensity(stepsPerMinute.round());
  }

  // Update getCaloriesPerStep to use user attributes
  double getCaloriesPerStep() {
    final attributes = _getUserPhysicalAttributes();

    return _stepRepository.calculateCaloriesPerStep(
      weightKg: attributes['weight'],
      heightCm: attributes['height'],
      age: attributes['age'],
      gender: attributes['gender'],
    );
  }

  // Add method to get user's step length
  double getUserStepLength() {
    final attributes = _getUserPhysicalAttributes();

    return _stepRepository.calculateStepLength(
      heightCm: attributes['height'],
      gender: attributes['gender'],
    );
  }

  // Add method to get user's BMR
  double getUserBMR() {
    final attributes = _getUserPhysicalAttributes();

    return _stepRepository.calculateBMR(
      weightKg: attributes['weight'],
      heightCm: attributes['height'],
      age: attributes['age'],
      gender: attributes['gender'],
    );
  }

  // Add method to get personalized step statistics
  Map<String, dynamic> getPersonalizedStepStatistics() {
    if (_todayActivity == null) {
      return {
        'totalSteps': 0,
        'averageStepsPerHour': 0.0,
        'peakSteps': 0,
        'activeTime': Duration.zero,
        'caloriesBurned': 0.0,
        'distance': 0.0,
        'activityIntensity': ActivityIntensity.sedentary,
      };
    }

    final attributes = _getUserPhysicalAttributes();
    final stepData = StepData(
      timestamp: _todayActivity!.updatedAt,
      stepCount: _todayActivity!.steps,
      stepsSinceLastUpdate: _todayActivity!.steps,
    );

    final stats = _stepRepository.getStepStatistics([stepData]);

    // Add personalized calculations
    stats['caloriesBurned'] = _stepRepository
        .calculateAccurateCaloriesFromSteps(
          steps: _todayActivity!.steps,
          weightKg: attributes['weight'],
          heightCm: attributes['height'],
          age: attributes['age'],
          gender: attributes['gender'],
          bodyFatPercentage: attributes['bodyFatPercentage'],
        );

    stats['distance'] = _stepRepository.calculateDistanceFromSteps(
      _todayActivity!.steps,
      heightCm: attributes['height'],
      gender: attributes['gender'],
    );

    stats['activityIntensity'] = getCurrentActivityIntensity();

    return stats;
  }

  // Dispose method to clean up resources
  @override
  void dispose() {
    _stepCountSubscription?.cancel();
    _stepDataSubscription?.cancel();
    super.dispose();
  }

  // Add method to update step goal
  Future<void> updateStepGoal(double value) async {
    _stepGoal = value;
    await _prefs.setDouble('daily_step_goal', value);
    notifyListeners();
  }

  // Add method to load step goal
  Future<void> loadStepGoal() async {
    _stepGoal = _prefs.getDouble('daily_step_goal') ?? 10000.0;
    notifyListeners();
  }
}
