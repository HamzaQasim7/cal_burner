// // widgets/weekly_chart.dart
// import 'package:flutter/material.dart';
// import 'package:fl_chart/fl_chart.dart';
// import 'package:google_fonts/google_fonts.dart';
// import 'package:easy_localization/easy_localization.dart';
// import 'package:provider/provider.dart';
// import '../data/provider/activity_provider.dart';
// import '../data/models/daily_activity_model.dart';
//
// class WeeklyChart extends StatelessWidget {
//   const WeeklyChart({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     final isDark = Theme.of(context).brightness == Brightness.dark;
//
//     return Consumer<ActivityProvider>(
//       builder: (context, activityProvider, child) {
//         final weeklyActivities = activityProvider.weeklyActivities;
//         final weeklySummary = activityProvider.getWeeklySummary();
//
//         return Container(
//           padding: const EdgeInsets.all(20),
//           decoration: BoxDecoration(
//             color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//             border: Border.all(color: Colors.grey.withOpacity(0.2), width: 0.5),
//             borderRadius: BorderRadius.circular(16),
//           ),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         'dashboard.steps'.tr(),
//                         style: GoogleFonts.inter(
//                           fontSize: 14,
//                           color: isDark ? Colors.white70 : Colors.black54,
//                         ),
//                       ),
//                       const SizedBox(height: 5),
//                       Text(
//                         weeklySummary.totalSteps.toString(),
//                         style: GoogleFonts.inter(
//                           fontSize: 24,
//                           fontWeight: FontWeight.bold,
//                           color: isDark ? Colors.white : Colors.black87,
//                         ),
//                       ),
//                       Text(
//                         'dashboard.past_7_days'.tr(),
//                         style: GoogleFonts.inter(
//                           fontSize: 12,
//                           color: const Color(0xFF007AFF),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 height: 120,
//                 child: BarChart(
//                   BarChartData(
//                     alignment: BarChartAlignment.spaceAround,
//                     maxY: _getMaxSteps(weeklyActivities),
//                     barTouchData: BarTouchData(
//                       enabled: true,
//                       touchTooltipData: BarTouchTooltipData(
//                         // tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
//                         getTooltipItem: (group, groupIndex, rod, rodIndex) {
//                           return BarTooltipItem(
//                             '${rod.toY.toInt()} steps',
//                             TextStyle(
//                               color: isDark ? Colors.white : Colors.black87,
//                               fontWeight: FontWeight.bold,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     titlesData: FlTitlesData(
//                       show: true,
//                       bottomTitles: AxisTitles(
//                         sideTitles: SideTitles(
//                           showTitles: true,
//                           getTitlesWidget: (value, meta) {
//                             final now = DateTime.now();
//   final today = now.weekday;
//                             final days = [
//                               'dashboard.mon'.tr(),
//                               'dashboard.tue'.tr(),
//                               'dashboard.wed'.tr(),
//                               'dashboard.thu'.tr(),
//                               'dashboard.fri'.tr(),
//                               'dashboard.sat'.tr(),
//                               'dashboard.sun'.tr(),
//                             ];
//                             final index = (value.toInt() + today - 1) % 7;
//                             return Text(
//                               days[index],
//                               style: GoogleFonts.inter(
//                                 fontSize: 12,
//                                 color: isDark ? Colors.white70 : Colors.black54,
//                               ),
//                             );
//                           },
//                         ),
//                       ),
//                       leftTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       topTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                       rightTitles: AxisTitles(
//                         sideTitles: SideTitles(showTitles: false),
//                       ),
//                     ),
//                     borderData: FlBorderData(show: false),
//                     gridData: FlGridData(show: false),
//                     barGroups: _generateBarGroups(weeklyActivities, isDark),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   double _getMaxSteps(List<DailyActivity> activities) {
//     if (activities.isEmpty) return 10000;
//     final maxSteps = activities.map((e) => e.steps.toDouble()).reduce((a, b) => a > b ? a : b);
//     return (maxSteps * 1.2).ceilToDouble(); // Add 20% padding
//   }
//
//   List<BarChartGroupData> _generateBarGroups(List<DailyActivity> activities, bool isDark) {
//     // Ensure we have 7 days of data
//     final List<DailyActivity> paddedActivities = List.generate(7, (index) {
//       if (index < activities.length) {
//         return activities[index];
//       }
//       return DailyActivity(
//         id: 'empty_$index',
//         userId: '',
//         date: DateTime.now().subtract(Duration(days: 6 - index)),
//         steps: 0,
//         caloriesBurned: 0,
//         distance: 0,
//         activeMinutes: 0,
//         createdAt: DateTime.now(),
//         updatedAt: DateTime.now(),
//       );
//     });
//
//     return List.generate(7, (index) {
//       final activity = paddedActivities[index];
//       final steps = activity.steps.toDouble();
//       final opacity = _calculateOpacity(steps);
//
//       return BarChartGroupData(
//         x: index,
//         barRods: [
//           BarChartRodData(
//             toY: steps,
//             color: const Color(0xFF007AFF).withOpacity(opacity),
//             width: 20,
//             borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
//           ),
//         ],
//       );
//     });
//   }
//
//   double _calculateOpacity(double steps) {
//     // Calculate opacity based on steps (0-10000 range)
//     return (steps / 10000).clamp(0.2, 1.0);
//   }
// }
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
                        NumberFormat('#,###').format(weeklySummary.totalSteps),
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
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final dayData =
                              _getWeeklyData(weeklyActivities)[groupIndex];
                          return BarTooltipItem(
                            '${NumberFormat('#,###').format(rod.toY.toInt())} steps\n${_getDayName(dayData.date)}',
                            TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
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
                            final weeklyData = _getWeeklyData(weeklyActivities);
                            final index = value.toInt();
                            if (index >= 0 && index < weeklyData.length) {
                              return Text(
                                _getDayAbbreviation(weeklyData[index].date),
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              );
                            }
                            return const SizedBox.shrink();
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

  // Get properly ordered weekly data (Monday to Sunday)
  List<DailyActivity> _getWeeklyData(List<DailyActivity> activities) {
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(
      weekStart.year,
      weekStart.month,
      weekStart.day,
    );

    // Create a map for quick lookup
    final activityMap = <String, DailyActivity>{};
    for (final activity in activities) {
      final dateKey = DateFormat('yyyy-MM-dd').format(activity.date);
      activityMap[dateKey] = activity;
    }

    // Generate 7 days of data (Monday to Sunday)
    final weeklyData = <DailyActivity>[];
    for (int i = 0; i < 7; i++) {
      final currentDate = weekStartDate.add(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(currentDate);

      final activity =
          activityMap[dateKey] ??
          DailyActivity(
            id: 'empty_${dateKey}',
            userId: '',
            date: currentDate,
            steps: 0,
            caloriesBurned: 0,
            distance: 0,
            activeMinutes: 0,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

      weeklyData.add(activity);
    }

    return weeklyData;
  }

  String _getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[date.weekday - 1];
  }

  String _getDayAbbreviation(DateTime date) {
    final dayNames = [
      'dashboard.mon'.tr(),
      'dashboard.tue'.tr(),
      'dashboard.wed'.tr(),
      'dashboard.thu'.tr(),
      'dashboard.fri'.tr(),
      'dashboard.sat'.tr(),
      'dashboard.sun'.tr(),
    ];
    return dayNames[date.weekday - 1];
  }

  double _getMaxSteps(List<DailyActivity> activities) {
    final weeklyData = _getWeeklyData(activities);
    if (weeklyData.isEmpty) return 10000;

    final maxSteps = weeklyData
        .map((e) => e.steps.toDouble())
        .reduce((a, b) => a > b ? a : b);

    // Ensure minimum height for better visualization
    final minHeight = 5000.0;
    final calculatedMax = maxSteps * 1.2; // Add 20% padding

    return calculatedMax < minHeight ? minHeight : calculatedMax;
  }

  List<BarChartGroupData> _generateBarGroups(
    List<DailyActivity> activities,
    bool isDark,
  ) {
    final weeklyData = _getWeeklyData(activities);
    final maxSteps = _getMaxSteps(activities);

    return List.generate(weeklyData.length, (index) {
      final activity = weeklyData[index];
      final steps = activity.steps.toDouble();
      final opacity = _calculateOpacity(steps, maxSteps);
      final isToday = _isToday(activity.date);

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: steps == 0 ? 0 : steps,
            color:
                isToday
                    ? const Color(0xFF007AFF)
                    : const Color(0xFF007AFF).withOpacity(opacity),
            width: 20,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            borderSide:
                isToday
                    ? const BorderSide(color: Color(0xFF007AFF), width: 2)
                    : BorderSide.none,
          ),
        ],
      );
    });
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  double _calculateOpacity(double steps, double maxSteps) {
    if (steps == 0) return 0.1;
    if (maxSteps == 0) return 0.5;

    // Calculate opacity based on relative steps (min 0.3, max 1.0)
    final relativeSteps = steps / maxSteps;
    return (0.3 + (relativeSteps * 0.7)).clamp(0.3, 1.0);
  }
}
