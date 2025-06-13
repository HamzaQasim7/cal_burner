import 'package:cal_burner/data/models/daily_activity_model.dart';
import 'package:cal_burner/presentation/statistic/widgets/stat_card_widget.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';
import '../../data/provider/activity_provider.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int selectedTabIndex = 0;
  late List<String> tabs;

  @override
  void initState() {
    super.initState();
    tabs = [
      'statistics.weekly'.tr(),
      'statistics.monthly'.tr(),
      'statistics.yearly'.tr(),
    ];
    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ActivityProvider>().loadWeeklyActivities();
    });
  }

  void _loadData() {
    final activityProvider = context.read<ActivityProvider>();
    switch (selectedTabIndex) {
      case 0:
        activityProvider.loadWeeklyActivities();
        break;
      case 1:
        activityProvider.loadMonthlyActivities();
        break;
      case 2:
        // Implement yearly data loading when available
        break;
    }
  }

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
                              _loadData();
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
                child: Consumer<ActivityProvider>(
                  builder: (context, activityProvider, child) {
                    if (activityProvider.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final weeklySummary = activityProvider.getWeeklySummary();
                    final monthlySummary = activityProvider.getMonthlySummary();

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Distance Stats Row
                          Row(
                            children: [
                              Flexible(
                                child: StatCardWidget(
                                  title: 'statistics.total_km_walked'.tr(),
                                  value:
                                      '${monthlySummary['totalDistance']?.toStringAsFixed(1) ?? '0'} km',
                                ),
                              ),
                              const Gap(16),
                              Flexible(
                                child: StatCardWidget(
                                  title:
                                      'statistics.weekly_average_distance'.tr(),
                                  value:
                                      '${(monthlySummary['totalDistance'] ?? 0) / (monthlySummary['daysInMonth'] ?? 1)} km',
                                ),
                              ),
                            ],
                          ),
                          const Gap(16),

                          // Calories Burned
                          StatCardWidget(
                            title: 'statistics.calories_burned'.tr(),
                            value:
                                '${monthlySummary['totalCalories']?.toStringAsFixed(0) ?? '0'} kcal',
                          ),
                          const Gap(16),

                          // Daily Steps Chart
                          _buildChartCard(
                            title: 'statistics.daily_steps'.tr(),
                            value: '${weeklySummary.totalSteps}',
                            subtitle: 'statistics.past_5_days'.tr(),
                            chartWidget: _buildStepsChart(activityProvider),
                          ),
                          const SizedBox(height: 16),

                          // Exercise Calories Chart
                          _buildChartCard(
                            title: 'statistics.exercise'.tr(),
                            value:
                                '${weeklySummary.totalCalories.toStringAsFixed(0)} Calories',
                            subtitle: 'statistics.past_5_days'.tr(),
                            chartWidget: _buildExerciseChart(activityProvider),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const Gap(100),
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

  Widget _buildStepsChart(ActivityProvider activityProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyActivities = activityProvider.weeklyActivities;

    return BarChart(
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
        barGroups: _generateStepBarGroups(weeklyActivities, isDark, theme),
      ),
    );
  }

  Widget _buildExerciseChart(ActivityProvider activityProvider) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final weeklyActivities = activityProvider.weeklyActivities;

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _getMaxCalories(weeklyActivities),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            // tooltipBgColor: isDark ? Colors.grey[800]! : Colors.white,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                '${rod.toY.toInt()} kcal',
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
        barGroups: _generateCalorieBarGroups(weeklyActivities, isDark, theme),
      ),
    );
  }

  double _getMaxSteps(List<DailyActivity> activities) {
    if (activities.isEmpty) return 8000;
    final maxSteps = activities
        .map((e) => e.steps.toDouble())
        .reduce((a, b) => a > b ? a : b);
    return (maxSteps * 1.2).ceilToDouble();
  }

  double _getMaxCalories(List<DailyActivity> activities) {
    if (activities.isEmpty) return 1500;
    final maxCalories = activities
        .map((e) => e.caloriesBurned)
        .reduce((a, b) => a > b ? a : b);
    return (maxCalories * 1.2).ceilToDouble();
  }

  List<BarChartGroupData> _generateStepBarGroups(
    List<DailyActivity> activities,
    bool isDark,
    ThemeData theme,
  ) {
    return List.generate(5, (index) {
      final activity = index < activities.length ? activities[index] : null;
      final steps = activity?.steps.toDouble() ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: steps,
            color:
                isDark
                    ? theme.colorScheme.primaryContainer
                    : const Color(0xFFE8E8E8),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }

  List<BarChartGroupData> _generateCalorieBarGroups(
    List<DailyActivity> activities,
    bool isDark,
    ThemeData theme,
  ) {
    return List.generate(5, (index) {
      final activity = index < activities.length ? activities[index] : null;
      final calories = activity?.caloriesBurned ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: calories,
            color:
                isDark
                    ? theme.colorScheme.primaryContainer
                    : const Color(0xFFE8E8E8),
            width: 20,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });
  }
}
