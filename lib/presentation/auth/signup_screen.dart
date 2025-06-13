import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/presentation/auth/login_screen.dart';
import 'package:cal_burner/presentation/auth/widgets/auth_footer.dart';
import 'package:cal_burner/presentation/auth/widgets/google_sign_in_button.dart';
import 'package:cal_burner/widgets/custom_elevated_button.dart';
import 'package:cal_burner/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:provider/provider.dart';

import '../main_nav/main_nav_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _fullNameController.dispose();
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

  // Handle email sign up
  Future<void> _handleEmailSignUp() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );

      if (success) {
        _showSnackBar('auth.verification_email_sent'.tr());
        // Navigate to verification screen or home screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
        );
      }
    } catch (e) {
      debugPrint('SignUp Error: $e');
      _showSnackBar(
        authProvider.error ?? 'auth.signup_error'.tr(),
        isError: true,
      );
    }
  }

  // Handle Google sign up
  Future<void> _handleGoogleSignUp() async {
    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.signInWithGoogle();
      if (success) {
        _showSnackBar('auth.google_signup_success'.tr());

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainNavigation()),
        );
      }
    } catch (e) {
      debugPrint('Google SignUp Error: $e');
      _showSnackBar(
        authProvider.error ?? 'auth.google_signup_error'.tr(),
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
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 48),
                    // Welcome Text
                    Text(
                      'auth.create_account'.tr(),
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'auth.sign_up_to_get_started'.tr(),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 48),

                    // Full Name Field
                    CustomTextField(
                      controller: _fullNameController,
                      labelText: 'auth.full_name'.tr(),
                      icon: Iconsax.user_outline,
                      textCapitalization: TextCapitalization.words,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'validation.name_required'.tr();
                        }
                        if (value.split(' ').length < 2) {
                          return 'validation.name_invalid'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

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
                        if (!value.contains(RegExp(r'[A-Z]'))) {
                          return 'validation.password_uppercase'.tr();
                        }
                        if (!value.contains(RegExp(r'[0-9]'))) {
                          return 'validation.password_number'.tr();
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Sign Up Button
                    CustomElevatedButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleEmailSignUp,
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
                              : Text('auth.create_account'.tr()),
                    ),
                    const SizedBox(height: 24),

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
                    const SizedBox(height: 24),

                    // Google Sign In Button
                    GoogleSignInButton(
                      onPressed:
                          authProvider.isLoading ? null : _handleGoogleSignUp,
                    ),
                    const SizedBox(height: 44),
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
        child: AuthFooter(isLoginScreen: false),
      ),
    );
  }
}
