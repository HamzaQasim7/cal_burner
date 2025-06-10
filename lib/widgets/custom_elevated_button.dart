import 'package:flutter/material.dart';

class CustomElevatedButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double? height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final bool isLoading;
  final bool isFullWidth;
  final double? elevation;
  final BorderSide? borderSide;
  final Gradient? gradient;
  final IconData? icon;
  final double? iconSize;
  final double? fontSize;
  final FontWeight? fontWeight;
  final bool isOutlined;
  final bool isTextButton;
  final bool isDisabled;
  final String? tooltip;

  const CustomElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height,
    this.borderRadius = 8.0,
    this.padding,
    this.margin,
    this.isLoading = false,
    this.isFullWidth = false,
    this.elevation,
    this.borderSide,
    this.gradient,
    this.icon,
    this.iconSize,
    this.fontSize,
    this.fontWeight,
    this.isOutlined = false,
    this.isTextButton = false,
    this.isDisabled = false,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    // Determine button colors based on type and theme
    final defaultBackgroundColor = isOutlined
        ? Colors.transparent
        : isTextButton
            ? Colors.transparent
            : theme.colorScheme.primary;

    final defaultForegroundColor = isOutlined
        ? theme.colorScheme.primary
        : isTextButton
            ? theme.colorScheme.primary
            : theme.colorScheme.onPrimary;

    // Create button style
    final buttonStyle = ButtonStyle(
      backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
        if (states.contains(MaterialState.disabled)) {
          return (backgroundColor ?? defaultBackgroundColor).withOpacity(0.5);
        }
        if (states.contains(MaterialState.pressed)) {
          return (backgroundColor ?? defaultBackgroundColor).withOpacity(0.8);
        }
        return backgroundColor ?? defaultBackgroundColor;
      }),
      foregroundColor: MaterialStateProperty.all(
        isDisabled ? defaultForegroundColor.withOpacity(0.5) : foregroundColor ?? defaultForegroundColor,
      ),
      elevation: MaterialStateProperty.all(elevation ?? (isOutlined ? 0 : 2)),
      padding: MaterialStateProperty.all(
        padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
          side: borderSide ??
              (isOutlined
                  ? BorderSide(color: theme.colorScheme.primary)
                  : BorderSide.none),
        ),
      ),
    );

    // Create the button content
    Widget buttonContent = child;
    if (icon != null) {
      buttonContent = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: iconSize ?? 20,
            color: foregroundColor ?? defaultForegroundColor,
          ),
          const SizedBox(width: 8),
          buttonContent,
        ],
      );
    }

    if (isLoading) {
      buttonContent = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            foregroundColor ?? defaultForegroundColor,
          ),
        ),
      );
    }

    // Wrap with tooltip if provided
    if (tooltip != null) {
      buttonContent = Tooltip(
        message: tooltip!,
        child: buttonContent,
      );
    }

    // Create the button
    Widget button = isTextButton
        ? TextButton(
            onPressed: isDisabled ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          )
        : ElevatedButton(
            onPressed: isDisabled ? null : onPressed,
            style: buttonStyle,
            child: buttonContent,
          );

    // Apply gradient if provided
    if (gradient != null && !isOutlined && !isTextButton) {
      button = Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: button,
      );
    }

    // Apply width constraints
    if (isFullWidth) {
      button = SizedBox(
        width: double.infinity,
        child: button,
      );
    } else if (width != null || height != null) {
      button = SizedBox(
        width: width,
        height: height,
        child: button,
      );
    }

    // Apply margin if provided
    if (margin != null) {
      button = Padding(
        padding: margin!,
        child: button,
      );
    }

    return button;
  }
} 