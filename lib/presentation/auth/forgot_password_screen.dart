import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/widgets/custom_elevated_button.dart';
import 'package:cal_burner/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // Show snackbar with message
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  // Handle password reset
  Future<void> _handlePasswordReset() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.sendPasswordResetEmail(
        _emailController.text.trim(),
      );

      if (success) {
        _showSnackBar('auth.reset_password_success'.tr());
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      _showSnackBar(
        authProvider.error ?? 'auth.reset_password_error'.tr(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthenticationProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.navigate_before, color: theme.colorScheme.onSurface),
          onPressed:
              authProvider.isLoading ? null : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 18,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Gap(32),
                    // Header Text
                    Text(
                      'auth.reset_password'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(12),
                    Text(
                      'auth.reset_password_description'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const Gap(48),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      labelText: 'auth.email'.tr(),
                      icon: Iconsax.sms_outline,
                      enabled: !authProvider.isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'validation.email_required'.tr();
                        }
                        if (!value.contains('@')) {
                          return 'validation.email_invalid'.tr();
                        }
                        return null;
                      },
                    ),
                    const Gap(32),

                    // Reset Password Button
                    CustomElevatedButton(
                      onPressed:
                          authProvider.isLoading ? null : _handlePasswordReset,
                      isFullWidth: true,
                      child:
                          authProvider.isLoading
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                ),
                              )
                              : Text('auth.send_reset_instructions'.tr()),
                    ),
                    const Gap(24),

                    // Back to Login
                    Center(
                      child: TextButton(
                        onPressed:
                            authProvider.isLoading
                                ? null
                                : () => Navigator.pop(context),
                        child: Text(
                          'auth.back_to_login'.tr(),
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Loading overlay
            if (authProvider.isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(child: CircularProgressIndicator()),
              ),
          ],
        ),
      ),
    );
  }
}
