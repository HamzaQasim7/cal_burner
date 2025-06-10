import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class SharedAppbar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Function()? onLeading;
  final String? desc;
  final Color? backgroundColor;
  final bool? automaticallyImplyLeading;
  final bool? centerTitle;
  final List<Widget>? actions;

  const SharedAppbar({
    super.key,
    required this.title,
    this.onLeading,
    this.desc,
    this.backgroundColor,
    this.automaticallyImplyLeading = true,
    this.actions,
    this.centerTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppBar(
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor:
          backgroundColor ??
          (isDark ? theme.colorScheme.surface : Colors.white),
      surfaceTintColor:
          backgroundColor ??
          (isDark ? theme.colorScheme.surface : Colors.white),
      automaticallyImplyLeading: automaticallyImplyLeading ?? true,
      titleSpacing: 0,
      elevation: 0,
      leading:
          (automaticallyImplyLeading ?? true)
              ? IconButton(
                onPressed: onLeading ?? () => Navigator.pop(context),
                icon: Icon(
                  Icons.arrow_back_ios_new,
                  weight: 600,
                  size: 20,
                  color:
                      isDark
                          ? theme.colorScheme.primary
                          : AppTheme.lightTheme.primaryColor,
                ),
              )
              : null,
      title:
          desc == null
              ? Text(
                title,
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color:
                      isDark
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurface,
                    ),
                  ),
                  const Gap(8),
                  Text(
                    desc ?? "",
                    style: theme.textTheme.bodySmall?.copyWith(
                      color:
                          isDark
                              ? theme.colorScheme.onSurface.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
    );
  }

  @override
  Size get preferredSize => const Size(double.infinity, 60);
}
