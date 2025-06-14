import 'package:cal_burner/data/provider/activity_provider.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/presentation/main_nav/widgets/daily_steps_widget.dart';
import 'package:cal_burner/widgets/montly_chart_widget.dart';
import 'package:cal_burner/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../../widgets/activity_card.dart';
import '../../../widgets/weeky_chart_widget.dart';
import '../../profile/widgets/profile_header_widget.dart';
import '../../profile/widgets/profile_image_widget.dart';
import '../../profile/widgets/settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<StatefulWidget> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Load monthly activities when the dashboard initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final activityProvider = Provider.of<ActivityProvider>(
        context,
        listen: false,
      );
      activityProvider.initializeDashboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authProvider = Provider.of<AuthenticationProvider>(
      context,
      listen: false,
    );
    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${DateTime.now().hour < 12
                            ? 'greeting.morning'.tr()
                            : DateTime.now().hour < 18
                            ? 'greeting.afternoon'.tr()
                            : 'greeting.evening'.tr()} ${authProvider.firebaseUser?.displayName ?? 'User'}",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: Icon(Iconsax.notification_outline),
                  ),
                ],
              ),
              Gap(20),
              ProfileHeaderWidget(
                onInsightButtonTap: () {},
                onTrophyButtonTap: () {},
              ),

              SizedBox(height: 12),
              Text(
                'dashboard.activity'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              SizedBox(height: 12),

              // Daily Steps Progress
              DailyStepsWidget(),
              SizedBox(height: 20),
              Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  final todayActivity = activityProvider.todayActivity;
                  final caloriesBurned = todayActivity?.caloriesBurned ?? 0;

                  return ActivityCard(
                    title: 'dashboard.calories_burned'.tr(),
                    value: caloriesBurned.toStringAsFixed(1),
                    icon: Icons.local_fire_department,
                    color: Color(0xFFFF6B6B),
                  );
                },
              ),

              SizedBox(height: 30),
              // Weekly Steps
              Text(
                'dashboard.weekly_steps'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              SizedBox(height: 15),

              WeeklyChart(),

              SizedBox(height: 30),

              // Monthly Steps
              Text(
                'dashboard.monthly_steps'.tr(),
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),

              SizedBox(height: 15),
              Consumer<ActivityProvider>(
                builder: (context, activityProvider, child) {
                  final monthlySummary = activityProvider.getMonthlySummary();
                  final totalCalories =
                      monthlySummary['totalCalories']?.toDouble() ?? 0.0;

                  return MonthlyChart(
                    title: 'dashboard.calories'.tr(),
                    subtitle: '${totalCalories.toStringAsFixed(0)}',
                    period: 'dashboard.last_4_weeks'.tr(),
                    chartColor: Colors.green,
                    minY: 0,
                    maxY: totalCalories > 0 ? totalCalories * 1.2 : 1000,
                  );
                },
              ),

              SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}
