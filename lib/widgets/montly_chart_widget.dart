import 'package:cal_burner/data/models/daily_activity_model.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../data/provider/activity_provider.dart';

class MonthlyChart extends StatelessWidget {
  final String title;
  final String subtitle;
  final String period;
  final Color chartColor;
  final double minY;
  final double maxY;

  const MonthlyChart({
    super.key,
    required this.title,
    required this.subtitle,
    required this.period,
    required this.chartColor,
    required this.minY,
    required this.maxY,
  });

  List<double> _getWeeklyData(List<DailyActivity> monthlyActivities) {
    if (monthlyActivities.isEmpty) {
      return List.filled(4, 0.0);
    }

    // Group activities by week
    final weeklyData = List<double>.filled(4, 0.0);
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);

    for (var activity in monthlyActivities) {
      final weekIndex =
          ((activity.date.difference(monthStart).inDays) / 7).floor();
      if (weekIndex >= 0 && weekIndex < 4) {
        // For calories chart
        if (title.toLowerCase().contains('calories')) {
          weeklyData[weekIndex] += activity.caloriesBurned;
        }
        // For steps chart
        else if (title.toLowerCase().contains('steps')) {
          weeklyData[weekIndex] += activity.steps.toDouble();
        }
        // For distance chart
        else if (title.toLowerCase().contains('distance')) {
          weeklyData[weekIndex] += activity.distance;
        }
      }
    }

    return weeklyData;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        final weeklyData = _getWeeklyData(activityProvider.monthlyActivities);
        final monthlySummary = activityProvider.getMonthlySummary();

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
              // Header Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        period,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: chartColor,
                        ),
                      ),
                    ],
                  ),
                  if (activityProvider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Chart Section
              SizedBox(
                height: 120,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final weeks = [
                              'week1'.tr(),
                              'week2'.tr(),
                              'week3'.tr(),
                              'week4'.tr(),
                            ];
                            return Padding(
                              padding: const EdgeInsets.only(
                                top: 8.0,
                                left: 8,
                                right: 8,
                              ),
                              child: Text(
                                weeks[value.toInt()],
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color:
                                      isDark ? Colors.white70 : Colors.black54,
                                ),
                              ),
                            );
                          },
                          reservedSize: 30,
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
                    minX: 0,
                    maxX: 3,
                    minY: minY,
                    maxY: maxY,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(
                          weeklyData.length,
                          (index) =>
                              FlSpot(index.toDouble(), weeklyData[index]),
                        ),
                        isCurved: true,
                        color: chartColor,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: chartColor,
                              strokeWidth: 2,
                              strokeColor:
                                  isDark
                                      ? const Color(0xFF1E1E1E)
                                      : Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: chartColor.withOpacity(0.1),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              chartColor.withOpacity(0.2),
                              chartColor.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ],
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        tooltipRoundedRadius: 8,
                        getTooltipItems: (List<LineBarSpot> touchedSpots) {
                          return touchedSpots.map((spot) {
                            return LineTooltipItem(
                              '${spot.y.toInt()}',
                              GoogleFonts.inter(
                                color: isDark ? Colors.white : Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            );
                          }).toList();
                        },
                      ),
                      handleBuiltInTouches: true,
                      getTouchedSpotIndicator: (
                        LineChartBarData barData,
                        List<int> spotIndexes,
                      ) {
                        return spotIndexes.map((spotIndex) {
                          return TouchedSpotIndicatorData(
                            FlLine(
                              color: chartColor.withOpacity(0.5),
                              strokeWidth: 2,
                              dashArray: [5, 5],
                            ),
                            FlDotData(
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: chartColor,
                                  strokeWidth: 2,
                                  strokeColor:
                                      isDark
                                          ? const Color(0xFF1E1E1E)
                                          : Colors.white,
                                );
                              },
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
