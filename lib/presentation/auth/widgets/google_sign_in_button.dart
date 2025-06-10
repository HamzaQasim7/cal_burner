import 'package:cal_burner/widgets/custom_elevated_button.dart';
import 'package:cal_burner/widgets/shared_dynamic_icon.dart';
import 'package:flutter/material.dart';

class GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDisabled;

  const GoogleSignInButton({
    super.key,
    this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return CustomElevatedButton(
      onPressed: isDisabled ? null : onPressed,
      isOutlined: true,
      isFullWidth: true,
      backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
      foregroundColor: isDark ? theme.colorScheme.onSurface : Colors.black87,
      elevation: 0,
      borderSide: BorderSide(
        color: isDark 
            ? theme.colorScheme.outline.withOpacity(0.5)
            : theme.colorScheme.outline.withOpacity(0.3),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          SharedDynamicIcon(
            'assets/icons/google.png',
            height: 24,
            weight: 24,
            color: isDark ? theme.colorScheme.onSurface : null,
          ),
          const SizedBox(width: 12),
          Text(
            'Google',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? theme.colorScheme.onSurface : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
