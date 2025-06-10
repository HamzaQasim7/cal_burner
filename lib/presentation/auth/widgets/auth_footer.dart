import 'package:cal_burner/core/theme/app_theme.dart';
import 'package:cal_burner/presentation/auth/login_screen.dart';
import 'package:cal_burner/presentation/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AuthFooter extends StatelessWidget {
  const AuthFooter({super.key, this.isLoginScreen = true});

  final bool isLoginScreen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLoginScreen 
              ? 'auth.dont_have_account'.tr() 
              : 'auth.already_have_account'.tr(),
          style: theme.textTheme.bodyMedium,
        ),
        TextButton(
          onPressed:
              isLoginScreen
                  ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => SignUpScreen()),
                    );
                  }
                  : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => LoginScreen()),
                    );
                  },
          child: Text(
            isLoginScreen ? 'auth.sign_up'.tr() : 'auth.sign_in'.tr(),
            style: theme.textTheme.bodyMedium!.copyWith(
              color: AppTheme.lightTheme.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
