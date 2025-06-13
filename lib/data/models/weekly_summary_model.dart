import 'daily_activity_model.dart';

class WeeklySummary {
  final DateTime weekStartDate;
  final int totalSteps;
  final double totalCalories;
  final double totalDistance;
  final int totalActiveMinutes;
  final List<DailyActivity> dailyActivities;

  WeeklySummary({
    required this.weekStartDate,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalActiveMinutes,
    required this.dailyActivities,
  });

  double get averageStepsPerDay => totalSteps / 7.0;
  double get averageCaloriesPerDay => totalCalories / 7.0;
  double get averageDistancePerDay => totalDistance / 7.0;
}
