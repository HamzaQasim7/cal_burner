import 'package:cal_burner/presentation/statistic/widgets/stat_card_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:easy_localization/easy_localization.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int selectedTabIndex = 0;
  final List<String> tabs = [
    'statistics.weekly'.tr(),
    'statistics.monthly'.tr(),
    'statistics.yearly'.tr(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                'statistics.title'.tr(),
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Tab Selection
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? theme.colorScheme.surface : Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  border:
                      isDark
                          ? Border.all(
                            color: theme.colorScheme.outline.withOpacity(0.2),
                            width: 0.5,
                          )
                          : null,
                ),
                child: Row(
                  children:
                      tabs.asMap().entries.map((entry) {
                        int index = entry.key;
                        String tab = entry.value;
                        bool isSelected = index == selectedTabIndex;

                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                selectedTabIndex = index;
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color:
                                    isSelected
                                        ? (isDark
                                            ? theme.colorScheme.primaryContainer
                                            : Colors.white)
                                        : Colors.transparent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color:
                                                isDark
                                                    ? Colors.black.withOpacity(
                                                      0.2,
                                                    )
                                                    : Colors.grey.withOpacity(
                                                      0.2,
                                                    ),
                                            spreadRadius: 1,
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                        : null,
                              ),
                              child: Text(
                                tab,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                  color:
                                      isSelected
                                          ? (isDark
                                              ? theme
                                                  .colorScheme
                                                  .onPrimaryContainer
                                              : Colors.black)
                                          : theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Distance Stats Row
                      Row(
                        children: [
                          Flexible(
                            child: StatCardWidget(
                              title: 'statistics.total_km_walked'.tr(),
                              value: '120 km',
                            ),
                          ),
                          const Gap(16),
                          Flexible(
                            child: StatCardWidget(
                              title: 'statistics.weekly_average_distance'.tr(),
                              value: '15 km',
                            ),
                          ),
                        ],
                      ),
                      const Gap(16),

                      // Calories Burned
                      StatCardWidget(
                        title: 'statistics.calories_burned'.tr(),
                        value: '3,500 kcal',
                      ),
                      const Gap(16),
                      // Daily Steps Chart
                      _buildChartCard(
                        title: 'statistics.daily_steps'.tr(),
                        value: '5,239',
                        subtitle: 'statistics.past_5_days'.tr(),
                        chartWidget: _buildStepsChart(),
                      ),
                      const SizedBox(height: 16),

                      // Exercise Calories Chart
                      _buildChartCard(
                        title: 'statistics.exercise'.tr(),
                        value: '4,493 Calories',
                        subtitle: 'statistics.past_5_days'.tr(),
                        chartWidget: _buildExerciseChart(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Gap(60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChartCard({
    required String title,
    required String value,
    required String subtitle,
    required Widget chartWidget,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        border: Border.all(
          color:
              isDark
                  ? theme.colorScheme.outline.withOpacity(0.2)
                  : Colors.grey.withOpacity(0.2),
          width: 0.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? null
                : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color:
                  isDark
                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                      : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(height: 120, child: chartWidget),
        ],
      ),
    );
  }

  Widget _buildStepsChart() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 8000,
        barTouchData: BarTouchData(enabled: false),
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
                ];
                if (value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: 4000,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: 7500,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: 2000,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: 3500,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [
              BarChartRodData(
                toY: 2500,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExerciseChart() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: 1500,
        barTouchData: BarTouchData(enabled: false),
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
                ];
                if (value.toInt() < days.length) {
                  return Text(
                    days[value.toInt()],
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
        barGroups: [
          BarChartGroupData(
            x: 0,
            barRods: [
              BarChartRodData(
                toY: 600,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 1,
            barRods: [
              BarChartRodData(
                toY: 1200,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 2,
            barRods: [
              BarChartRodData(
                toY: 400,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 3,
            barRods: [
              BarChartRodData(
                toY: 1000,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
          BarChartGroupData(
            x: 4,
            barRods: [
              BarChartRodData(
                toY: 300,
                color:
                    isDark
                        ? theme.colorScheme.primaryContainer
                        : const Color(0xFFE8E8E8),
                width: 20,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
