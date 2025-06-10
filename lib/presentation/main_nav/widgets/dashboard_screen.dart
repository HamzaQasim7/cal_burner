import 'package:cal_burner/widgets/montly_chart_widget.dart';
import 'package:cal_burner/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:easy_localization/easy_localization.dart';

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
  final String _userName = "David";
  final String _userLocation = "LA, America";
  final int _userAge = 34;
  final String _userHeight = "6'0\"";
  final double _impScore = 251.345;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? Color(0xFF121212) : Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
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
                            : 'greeting.evening'.tr()} ${'David'}",
                        style: GoogleFonts.inter(
                          fontSize: 16,
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
                // userName: _userName,
                // userLocation: _userLocation,
                // userAge: _userAge,
                // userHeight: _userHeight,
                // impScore: _impScore,
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
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Color(0xFF1E1E1E) : Colors.white,
                  border: Border.all(
                    color: Colors.grey.withOpacity(0.2),
                    width: 0.5,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'dashboard.daily_steps'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                    ),
                    SizedBox(height: 15),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '7,500',
                          style: GoogleFonts.inter(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          '/ 10,000',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    LinearPercentIndicator(
                      padding: EdgeInsets.zero,
                      lineHeight: 8,
                      percent: 0.75,
                      backgroundColor:
                          isDark ? Colors.grey[800] : Colors.grey[200],
                      progressColor: Color(0xFFFFD60A),
                      barRadius: Radius.circular(4),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'dashboard.keep_moving'.tr(),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: Color(0xFFFFD60A),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 20),

              // Calories Burned Card
              ActivityCard(
                title: 'dashboard.calories_burned'.tr(),
                value: '2,350',
                icon: Icons.local_fire_department,
                color: Color(0xFFFF6B6B),
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

              MonthlyChart(
                weeklyData: [50000, 45000, 48000, 62000],
                title: 'dashboard.calories'.tr(),
                subtitle: '195,000',
                period: 'dashboard.last_4_weeks'.tr(),
                chartColor: Colors.green,
                minY: 40000,
                maxY: 60000,
              ),
              SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }
}
