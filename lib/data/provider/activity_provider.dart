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

  ActivityProvider(this._prefs)
    : _activityRepository = ActivityRepository(_prefs),
      _stepRepository = StepRepository(_prefs);

  DailyActivity? _todayActivity;
  List<DailyActivity> _weeklyActivities = [];
  List<DailyActivity> _monthlyActivities = [];
  bool _isLoading = false;
  String? _error;
  bool _isStepCountingInitialized = false;
  String? _userId;

  // Getters
  DailyActivity? get todayActivity => _todayActivity;

  List<DailyActivity> get weeklyActivities => _weeklyActivities;

  List<DailyActivity> get monthlyActivities => _monthlyActivities;

  bool get isLoading => _isLoading;

  String? get error => _error;

  bool get isStepCountingInitialized => _isStepCountingInitialized;
  User? get currentUser => FirebaseAuth.instance.currentUser;

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

      // Initialize step detection service
      final stepService = StepDetectionService(_prefs);
      final isInitialized = await stepService.initialize();

      if (!isInitialized) {
        _setError(
          'Failed to initialize step counting. Please check Health Connect permissions.',
        );
        _isStepCountingInitialized = false;
        return;
      }

      _isStepCountingInitialized = true;
      print('Step counting initialized successfully');

      // Start periodic step counting in background
      await stepService.startPeriodicStepCounting();

      // Get initial step count
      final initialSteps = await stepService.getTodaySteps();
      print('Initial step count: $initialSteps');

      if (initialSteps > 0) {
        await _updateStepCount(initialSteps);
      }

      // Start listening to step count changes if you have a stream
      _stepRepository.getStepCountStream()?.listen(
        (steps) => _updateStepCount(steps),
        onError: (error) {
          print('Step count stream error: $error');
          _setError('Step counting error: $error');
        },
      );

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

  // Update step count
  Future<void> _updateStepCount(int steps) async {
    if (_userId == null) return;

    try {
      if (_todayActivity == null) {
        await _loadTodayActivityInternal();
      }

      if (_todayActivity != null) {
        final weight = 70.0; // Get this from UserProvider
        final calories = _stepRepository.calculateCaloriesFromSteps(
          steps,
          weight,
        );
        final distance = _stepRepository.calculateDistanceFromSteps(steps);

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
      notifyListeners();
    } catch (e) {
      _setError('Failed to load weekly activities: $e');
    } finally {
      _setLoading(false);
    }
  }

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
      notifyListeners();
    } catch (e) {
      _setError('Failed to load monthly activities: $e');
    } finally {
      _setLoading(false);
    }
  }

  // Get weekly summary
  WeeklySummary getWeeklySummary() {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    final totalSteps = _weeklyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.steps,
    );
    final totalCalories = _weeklyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.caloriesBurned,
    );
    final totalDistance = _weeklyActivities.fold<double>(
      0,
      (sum, activity) => sum + activity.distance,
    );
    final totalActiveMinutes = _weeklyActivities.fold<int>(
      0,
      (sum, activity) => sum + activity.activeMinutes,
    );

    return WeeklySummary(
      weekStartDate: weekStartDate,
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalDistance: totalDistance,
      totalActiveMinutes: totalActiveMinutes,
      dailyActivities: List.from(_weeklyActivities),
    );
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

  // Dispose method to clean up resources
  @override
  void dispose() {
    // Clean up any streams or resources here
    super.dispose();
  }
}
