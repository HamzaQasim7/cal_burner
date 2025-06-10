import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? hintText;
  final String? labelText;
  final String? helperText;
  final String? initialValue;
  final String? suffixText;
  final String? prefixText;
  final IconData? icon;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool readOnly;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final FormFieldSetter<String>? onSaved;
  final void Function()? onTap;
  final bool enabled;
  final int maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final InputBorder? border;
  final EdgeInsetsGeometry? contentPadding;
  final FocusNode? focusNode;
  final List<TextInputFormatter>? inputFormatters;

  const CustomTextField({
    super.key,
    this.controller,
    this.hintText,
    this.labelText,
    this.prefixText,
    this.icon,
    this.suffixIcon,
    this.obscureText = false,
    this.readOnly = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.done,
    this.validator,
    this.onChanged,
    this.enabled = true,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.sentences,
    this.border,
    this.contentPadding,
    this.focusNode,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.helperText,
    this.suffixText,
    this.onTap,
    this.onSaved,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return TextFormField(
      initialValue: initialValue,
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onSaved: onSaved,
      readOnly: readOnly,
      onTap: onTap,
      onFieldSubmitted: onFieldSubmitted,
      enabled: enabled,
      maxLines: maxLines,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
      focusNode: focusNode,
      style: TextStyle(
        color:
            isDarkMode
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        labelStyle: TextStyle(
          color:
              isDarkMode
                  ? theme.colorScheme.onSurface.withOpacity(0.7)
                  : theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        hintText: hintText,
        labelText: labelText,
        suffixText: suffixText,
        helperText: helperText,
        prefixText: prefixText,
        prefixIcon:
            icon != null
                ? Icon(
                  icon,
                  color:
                      isDarkMode
                          ? theme.colorScheme.primary
                          : theme.colorScheme.primary,
                )
                : null,
        suffixIcon: suffixIcon,
        contentPadding:
            contentPadding ??
            const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        filled: true,
        fillColor:
            isDarkMode ? theme.colorScheme.surface : theme.colorScheme.surface,
        border:
            border ??
            OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(
                color: theme.colorScheme.primary.withOpacity(0.5),
              ),
            ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: theme.colorScheme.primary.withOpacity(0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.error, width: 2),
        ),
      ),
      onTapOutside: (f) => FocusScope.of(context).unfocus(),
    );
  }
}
