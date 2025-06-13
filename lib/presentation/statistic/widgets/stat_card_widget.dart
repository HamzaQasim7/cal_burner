import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

class StatCardWidget extends StatelessWidget {
  const StatCardWidget({super.key, required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: theme.textTheme.bodyMedium?.copyWith(
              color:
                  isDark
                      ? theme.colorScheme.onSurface.withOpacity(0.7)
                      : Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Gap(8),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color:
                  isDark
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
