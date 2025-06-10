import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/data/provider/language_provider.dart';
import 'package:cal_burner/data/provider/theme_provider.dart';
import 'package:cal_burner/presentation/auth/login_screen.dart';
import 'package:cal_burner/widgets/shared_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final Map<String, String> languages = {
    'en': 'English',
    'es': 'Español',
    'de': 'Deutsch',
  };

  // Show confirmation dialog for logout
  Future<void> _showLogoutConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('logout_confirmation_title'.tr()),
            content: Text('logout_confirmation_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'logout'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _handleLogout();
    }
  }

  // Handle logout
  Future<void> _handleLogout() async {
    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.signOut();
      if (success && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('logout_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Show confirmation dialog for deleting account
  Future<void> _showDeleteAccountConfirmationDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('delete_account_confirmation_title'.tr()),
            content: Text('delete_account_confirmation_message'.tr()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('cancel'.tr()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'delete_account'.tr(),
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _handleDeleteAccount();
    }
  }

  // Handle account deletion
  Future<void> _handleDeleteAccount() async {
    final authProvider = context.read<AuthenticationProvider>();

    try {
      final success = await authProvider.deleteAccount();
      if (success && mounted) {
        // Navigate to login screen and clear all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('delete_account_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final languageProvider = Provider.of<LanguageProvider>(context);
    final authProvider = context.watch<AuthenticationProvider>();
    final isDarkMode = themeProvider.isDarkMode;
    final currentLanguage =
        languages[languageProvider.currentLocale.languageCode] ?? 'English';

    return Scaffold(
      appBar: SharedAppbar(
        title: "${"   "}${'settings.title'.tr()}",
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionTitle('settings.preferences'.tr()),
            const Gap(8),
            _dropdownField(
              'settings.language'.tr(),
              currentLanguage,
              languages.values.toList(),
              (value) {
                if (value != null) {
                  final languageCode =
                      languages.entries
                          .firstWhere((entry) => entry.value == value)
                          .key;
                  languageProvider.setLanguage(context, languageCode);
                }
              },
            ),
            const Gap(8),
            SwitchListTile(
              title: Text('settings.dark_mode'.tr()),
              subtitle: Text(
                isDarkMode
                    ? 'settings.dark_mode_enabled'.tr()
                    : 'settings.light_mode_enabled'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              value: isDarkMode,
              onChanged: (value) {
                themeProvider.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                );
              },
            ),
            const SizedBox(height: 20),
            _sectionTitle('settings.account'.tr()),
            _settingsTile(
              'settings.change_email'.tr(),
              Iconsax.sms_outline,
              () {},
            ),
            _settingsTile(
              'settings.change_password'.tr(),
              Iconsax.lock_outline,
              () {},
            ),
            const Gap(20),
            _sectionTitle('danger_zone'.tr()),
            _dangerZoneTile(
              'logout'.tr(),
              Iconsax.logout_outline,
              _showLogoutConfirmationDialog,
              authProvider.isLoading,
            ),
            const Gap(8),
            _dangerZoneTile(
              'delete_account'.tr(),
              Iconsax.trash_outline,
              _showDeleteAccountConfirmationDialog,
              authProvider.isLoading,
            ),
            const Gap(80),
          ],
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String current,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          padding: EdgeInsets.zero,
          value: current,
          isExpanded: true,
          icon: const Icon(Icons.expand_more, color: Colors.grey),
          onChanged: onChanged,
          items:
              items
                  .map((val) => DropdownMenuItem(value: val, child: Text(val)))
                  .toList(),
        ),
      ),
    );
  }

  Widget _settingsTile(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.navigate_next),
      onTap: onTap,
    );
  }

  Widget _dangerZoneTile(
    String title,
    IconData icon,
    VoidCallback onTap,
    bool isLoading,
  ) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.error),
      title: Text(
        title,
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      trailing:
          isLoading
              ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
              : null,
      onTap: isLoading ? null : onTap,
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}
