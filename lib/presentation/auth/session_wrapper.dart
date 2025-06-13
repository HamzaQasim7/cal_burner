import 'package:cal_burner/presentation/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/provider/session_manager.dart';
import '../main_nav/main_nav_screen.dart';
import '../onboardings/landing_screens.dart';

class SessionWrapper extends StatelessWidget {
  const SessionWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionManager>(
      builder: (context, sessionManager, _) {
        // Check if it's first launch
        if (sessionManager.isFirstLaunch) {
          return const LandingScreens();
        }

        // Check if user has seen onboarding
        if (!sessionManager.hasSeenOnboarding) {
          return const LandingScreens();
        }

        // Check if user is authenticated and email is verified
        if (!sessionManager.isAuthenticated) {
          return const LoginScreen();
        }

        // If all conditions are met, show home screen
        return const MainNavigation();
      },
    );
  }
}
