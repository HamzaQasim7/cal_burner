import 'dart:ui';

import 'package:cal_burner/presentation/main_nav/widgets/dashboard_screen.dart';
import 'package:cal_burner/presentation/profile/widgets/settings_screen.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart';

import '../profile/profile_screen.dart';
import '../statistic/statistic_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<StatefulWidget> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    SettingsScreen(),
    ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20, left: 20, right: 20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors:
                      isDark
                          ? [
                            const Color(0xFF1E1E1E).withOpacity(0.8),
                            const Color(0xFF2A2A2A).withOpacity(0.7),
                          ]
                          : [
                            Colors.white.withOpacity(0.8),
                            Colors.white.withOpacity(0.6),
                          ],
                ),
                borderRadius: BorderRadius.circular(25),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.1)
                          : Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.3)
                            : Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Gap(2),
                  Expanded(
                    child: _buildNavItem(
                      index: 0,
                      icon: Iconsax.home_1_outline,
                      activeIcon: Iconsax.home_1_bold,
                      label: 'nav.home'.tr(),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      index: 1,
                      icon: Iconsax.chart_1_outline,
                      activeIcon: Iconsax.chart_1_bold,
                      label: 'nav.statistics'.tr(),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      index: 2,
                      icon: Iconsax.setting_outline,
                      activeIcon: Iconsax.setting_bold,
                      label: 'settings.title'.tr(),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildNavItem(
                      index: 3,
                      icon: Iconsax.user_outline,
                      activeIcon: Iconsax.user_bold,
                      label: 'nav.profile'.tr(),
                      isDark: isDark,
                    ),
                  ),
                  Gap(2),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color:
              isSelected
                  ? (isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05))
                  : Colors.transparent,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color:
                    isSelected
                        ? const Color(0xFFF2BA15)
                        : (isDark ? Colors.white70 : Colors.grey),
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected
                        ? const Color(0xFFF2BA15)
                        : (isDark ? Colors.white70 : Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Alternative version with more pronounced glass effect
class MainNavigationGlassyAlt extends StatefulWidget {
  const MainNavigationGlassyAlt({super.key});

  @override
  State<StatefulWidget> createState() => _MainNavigationGlassyAltState();
}

class _MainNavigationGlassyAltState extends State<MainNavigationGlassyAlt> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    DashboardScreen(),
    StatisticsScreen(),
    SettingsScreen(),
    ProfileSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBody: true,
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        controller: _pageController,
        children: _screens,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 25, left: 25, right: 25),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 75,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors:
                      isDark
                          ? [
                            const Color(0xFF2A2A2A).withOpacity(0.9),
                            const Color(0xFF1A1A1A).withOpacity(0.8),
                          ]
                          : [
                            Colors.white.withOpacity(0.9),
                            Colors.white.withOpacity(0.7),
                          ],
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color:
                      isDark
                          ? Colors.white.withOpacity(0.15)
                          : Colors.white.withOpacity(0.4),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.black.withOpacity(0.4)
                            : Colors.black.withOpacity(0.08),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color:
                        isDark
                            ? Colors.white.withOpacity(0.05)
                            : Colors.white.withOpacity(0.3),
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildGlassyNavItem(
                    index: 0,
                    icon: Iconsax.home_1_outline,
                    activeIcon: Iconsax.home_1_bold,
                    label: 'nav.home'.tr(),
                    isDark: isDark,
                  ),
                  _buildGlassyNavItem(
                    index: 1,
                    icon: Iconsax.chart_1_outline,
                    activeIcon: Iconsax.chart_1_bold,
                    label: 'nav.statistics'.tr(),
                    isDark: isDark,
                  ),
                  _buildGlassyNavItem(
                    index: 2,
                    icon: Iconsax.setting_outline,
                    activeIcon: Iconsax.setting_bold,
                    label: 'settings.title'.tr(),
                    isDark: isDark,
                  ),
                  _buildGlassyNavItem(
                    index: 3,
                    icon: Iconsax.user_outline,
                    activeIcon: Iconsax.user_bold,
                    label: 'nav.profile'.tr(),
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassyNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isDark,
  }) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
        _pageController.animateToPage(
          index,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient:
              isSelected
                  ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF007AFF).withOpacity(0.2),
                      const Color(0xFF007AFF).withOpacity(0.1),
                    ],
                  )
                  : null,
          border:
              isSelected
                  ? Border.all(
                    color: const Color(0xFF007AFF).withOpacity(0.3),
                    width: 1,
                  )
                  : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: Icon(
                isSelected ? activeIcon : icon,
                key: ValueKey(isSelected),
                color:
                    isSelected
                        ? const Color(0xFF007AFF)
                        : (isDark ? Colors.white70 : Colors.grey.shade600),
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color:
                    isSelected
                        ? const Color(0xFF007AFF)
                        : (isDark ? Colors.white70 : Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
