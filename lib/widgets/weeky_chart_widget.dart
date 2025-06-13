// widgets/weekly_chart.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../data/provider/activity_provider.dart';
import '../data/models/daily_activity_model.dart';

class WeeklyChart extends StatelessWidget {
  const WeeklyChart({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final weeklyActivities = activityProvider.weeklyActivities;
        final weeklySummary = activityProvider.getWeeklySummary();

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'dashboard.steps'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        weeklySummary.totalSteps.toString(),
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'dashboard.past_7_days'.tr(),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF007AFF),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 120,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: _getMaxSteps(weeklyActivities),
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchTooltipData: BarTouchTooltipData(
                        // tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          return BarTooltipItem(
                            '${rod.toY.toInt()} steps',
                            TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final days = [
                              'dashboard.mon'.tr(),
                              'dashboard.tue'.tr(),
                              'dashboard.wed'.tr(),
                              'dashboard.thu'.tr(),
                              'dashboard.fri'.tr(),
                              'dashboard.sat'.tr(),
                              'dashboard.sun'.tr(),
                            ];
                            return Text(
                              days[value.toInt()],
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            );
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: false),
                    barGroups: _generateBarGroups(weeklyActivities, isDark),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  double _getMaxSteps(List<DailyActivity> activities) {
    if (activities.isEmpty) return 10000;
    final maxSteps = activities.map((e) => e.steps.toDouble()).reduce((a, b) => a > b ? a : b);
    return (maxSteps * 1.2).ceilToDouble(); // Add 20% padding
  }

  List<BarChartGroupData> _generateBarGroups(List<DailyActivity> activities, bool isDark) {
    // Ensure we have 7 days of data
    final List<DailyActivity> paddedActivities = List.generate(7, (index) {
      if (index < activities.length) {
        return activities[index];
      }
      return DailyActivity(
        id: 'empty_$index',
        userId: '',
        date: DateTime.now().subtract(Duration(days: 6 - index)),
        steps: 0,
        caloriesBurned: 0,
        distance: 0,
        activeMinutes: 0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    });

    return List.generate(7, (index) {
      final activity = paddedActivities[index];
      final steps = activity.steps.toDouble();
      final opacity = _calculateOpacity(steps);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: steps,
            color: const Color(0xFF007AFF).withOpacity(opacity),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    });
  }

  double _calculateOpacity(double steps) {
    // Calculate opacity based on steps (0-10000 range)
    return (steps / 10000).clamp(0.2, 1.0);
  }
}
