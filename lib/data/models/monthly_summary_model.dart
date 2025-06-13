import 'package:cal_burner/data/models/weekly_summary_model.dart';

class MonthlySummary {
  final DateTime monthDate;
  final int totalSteps;
  final double totalCalories;
  final double totalDistance;
  final int totalActiveMinutes;
  final List<WeeklySummary> weeklySummaries;

  MonthlySummary({
    required this.monthDate,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalDistance,
    required this.totalActiveMinutes,
    required this.weeklySummaries,
  });

  double get averageStepsPerDay => totalSteps / 30.0;

  double get averageCaloriesPerDay => totalCalories / 30.0;

  double get averageDistancePerDay => totalDistance / 30.0;
}
