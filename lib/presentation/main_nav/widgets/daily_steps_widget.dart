import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:provider/provider.dart';
import '../../../data/provider/activity_provider.dart';

class DailyStepsWidget extends StatefulWidget {
  const DailyStepsWidget({super.key});

  @override
  State<DailyStepsWidget> createState() => _DailyStepsWidgetState();
}

class _DailyStepsWidgetState extends State<DailyStepsWidget> {
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Initialize after the first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    if (!_isInitialized) {
      final activityProvider = context.read<ActivityProvider>();
      await activityProvider.initializeStepCounting();
      await activityProvider.loadTodayActivity();
      setState(() {
        _isInitialized = true;
      });
    }
  }

  String _getMotivationalMessage(double progress) {
    if (progress >= 1.0) {
      return 'great_job'.tr();
    } else if (progress >= 0.75) {
      return 'almost_there'.tr();
    } else if (progress >= 0.5) {
      return 'keep_moving'.tr();
    } else if (progress >= 0.25) {
      return 'keep_going'.tr();
    } else {
      return 'start_moving'.tr();
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 1.0) {
      return const Color(0xFF4CAF50);
    } else if (progress >= 0.75) {
      return const Color(0xFFFFD60A);
    } else if (progress >= 0.5) {
      return const Color(0xFFFFA000);
    } else {
      return const Color(0xFFFF5252);
    }
  }

  Widget _buildErrorWidget(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Text(
            error,
            style: GoogleFonts.inter(fontSize: 14, color: Colors.red),
          ),
          if (error.contains('Health Connect'))
            ElevatedButton(
              onPressed: () async {
                final activityProvider = context.read<ActivityProvider>();
                await activityProvider.initializeStepCounting();
              },
              child: Text('Install Health Connect'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Consumer<ActivityProvider>(
      builder: (context, activityProvider, child) {
        if (activityProvider.error != null) {
          return _buildErrorWidget(activityProvider.error!);
        }

        final todayActivity = activityProvider.todayActivity;
        final steps = todayActivity?.steps ?? 0;
        const stepGoal = 10000;
        final progress = (steps / stepGoal).clamp(0.0, 1.0);
        final progressColor = _getProgressColor(progress);
        final message = _getMotivationalMessage(progress);

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
                  Text(
                    'dashboard.daily_steps'.tr(),
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  if (activityProvider.isLoading)
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    steps.toString(),
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    '/ $stepGoal',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              LinearPercentIndicator(
                padding: EdgeInsets.zero,
                lineHeight: 8,
                percent: progress,
                backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                progressColor: progressColor,
                barRadius: const Radius.circular(4),
                animation: true,
                animationDuration: 1000,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    message,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: progressColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (todayActivity != null)
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
