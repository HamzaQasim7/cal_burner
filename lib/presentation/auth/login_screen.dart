import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/presentation/auth/widgets/auth_footer.dart';
import 'package:cal_burner/presentation/auth/widgets/google_sign_in_button.dart';
import 'package:cal_burner/widgets/custom_elevated_button.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_text_field.dart';
import '../../presentation/auth/forgot_password_screen.dart';
import '../main_nav/main_nav_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
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

  // Handle email login
  Future<void> _handleEmailLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthenticationProvider>();

    try {
      await authProvider.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Check email verification status
      final isVerified = await authProvider.checkEmailVerification();

      if (isVerified) {
        // First show success message
        _showSnackBar('auth.login_success'.tr());

        // Use pushAndRemoveUntil to clear the navigation stack
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false, // This removes all previous routes
        );
      } else {
        _showSnackBar('auth.verify_email_first'.tr(), isError: true);
        await authProvider.sendEmailVerification();
      }
    } catch (e) {
      debugPrint('Login Error: $e');
      _showSnackBar(
        authProvider.error ?? 'auth.login_error'.tr(),
        isError: true,
      );
    }
  }

  // Handle Google login
  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.signInWithGoogle();
      if (success) {
        _showSnackBar('auth.google_login_success'.tr());

        // Ensure we're still mounted before navigation
        if (!mounted) return;

        // Use pushAndRemoveUntil to clear the navigation stack
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigation()),
          (route) => false, // This removes all previous routes
        );
      }
    } catch (e) {
      debugPrint('Google Login Error: $e');
      _showSnackBar(
        authProvider.error ?? 'auth.google_login_error'.tr(),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthenticationProvider>();

    return Scaffold(
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
                    const SizedBox(height: 48),
                    // Welcome Text
                    Text(
                      'auth.welcome_back'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auth.sign_in_to_continue'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Email Field
                    CustomTextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      labelText: 'auth.email'.tr(),
                      icon: Iconsax.sms_outline,
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
                    const SizedBox(height: 24),

                    // Password Field
                    CustomTextField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      labelText: 'auth.password'.tr(),
                      icon: Iconsax.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Iconsax.eye_slash_outline
                              : Iconsax.eye_outline,
                          color: AppTheme.lightTheme.primaryColor,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'validation.password_required'.tr();
                        }
                        if (value.length < 6) {
                          return 'validation.password_length'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Forgot Password
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed:
                            authProvider.isLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) =>
                                              const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                        child: Text('auth.forgot_password'.tr()),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Login Button
                    CustomElevatedButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleEmailLogin,
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
                              : Text('auth.sign_in'.tr()),
                    ),
                    const Gap(24),

                    // Divider with "or" text
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'auth.or_sign_in_with'.tr(),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.6,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: theme.colorScheme.outline.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                    const Gap(24),

                    // Google Sign In Button
                    GoogleSignInButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleGoogleLogin,
                    ),
                    const Gap(44),
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
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 12),
        child: AuthFooter(),
      ),
    );
  }
}
