import 'package:cal_burner/data/provider/auth_provider.dart';
import 'package:cal_burner/presentation/profile/widgets/profile_header_widget.dart';
import 'package:cal_burner/widgets/shared_appbar.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';

import '../../widgets/custom_text_field.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController ageController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController fatController = TextEditingController();
  String gender = 'profile.gender.male'.tr();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    final authProvider = context.read<AuthenticationProvider>();
    final user = authProvider.user;
    if (user != null) {
      ageController.text = user.age?.toString() ?? '';
      heightController.text = user.height?.toString() ?? '';
      weightController.text = user.weight?.toString() ?? '';
      fatController.text = user.bodyFatPercentage?.toString() ?? '';
      gender = user.gender ?? 'profile.gender.male'.tr();
    }
  }

  @override
  void dispose() {
    ageController.dispose();
    heightController.dispose();
    weightController.dispose();
    fatController.dispose();
    super.dispose();
  }

  void _handleInsightButtonTap() {
    // TODO: Implement insight functionality
  }

  void _handleTrophyButtonTap() {
    // TODO: Implement trophy functionality
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthenticationProvider>();
    final currentUser = authProvider.user;

    if (currentUser == null) return;

    try {
      // Create updated user model
      final updatedUser = currentUser.copyWith(
        age: int.tryParse(ageController.text),
        height: double.tryParse(heightController.text),
        weight: double.tryParse(weightController.text),
        bodyFatPercentage: double.tryParse(fatController.text),
        gender: gender,
        impScore: currentUser.impScore,
      );

      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 16),
                Text('updating'.tr()),
              ],
            ),
            duration: const Duration(seconds: 1),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Update user data
      final success = await authProvider.updateUserData(updatedUser);

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('update_success'.tr()),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authProvider.error ?? 'update_error'.tr()),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('update_error'.tr()),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthenticationProvider>();
    final user = authProvider.user;

    if (user == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: SharedAppbar(
        title: "${"   "}${'profile.title'.tr()}",
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ProfileHeaderWidget(
                onInsightButtonTap: _handleInsightButtonTap,
                onTrophyButtonTap: _handleTrophyButtonTap,
              ),
              const Gap(32),
              _sectionTitle('profile.about_you'.tr()),
              CustomTextField(
                labelText: 'profile.age'.tr(),
                controller: ageController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final age = int.tryParse(value);
                    if (age == null || age < 0 || age > 120) {
                      return 'profile.age_invalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const Gap(12),
              CustomTextField(
                labelText: 'profile.height'.tr(),
                controller: heightController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final height = double.tryParse(value);
                    if (height == null || height < 0 || height > 300) {
                      return 'profile.height_invalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const Gap(12),
              CustomTextField(
                labelText: 'profile.weight'.tr(),
                controller: weightController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final weight = double.tryParse(value);
                    if (weight == null || weight < 0 || weight > 500) {
                      return 'profile.weight_invalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const Gap(12),
              CustomTextField(
                labelText: 'profile.body_fat'.tr(),
                controller: fatController,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final fat = double.tryParse(value);
                    if (fat == null || fat < 0 || fat > 100) {
                      return 'profile.body_fat_invalid'.tr();
                    }
                  }
                  return null;
                },
              ),
              const Gap(12),
              _dropdownField(
                'profile.gender'.tr(),
                gender,
                [
                  'profile.gender.male'.tr(),
                  'profile.gender.female'.tr(),
                  'profile.gender.other'.tr(),
                ],
                (value) {
                  if (value != null) {
                    setState(() => gender = value);
                  }
                },
              ),
              const Gap(30),
              ElevatedButton(
                onPressed: _updateProfile,
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  minimumSize: const Size.fromHeight(50),
                ),
                child: Text(
                  'profile.update'.tr(),
                  style: TextStyle(color: theme.colorScheme.onPrimary),
                ),
              ),
              const Gap(80),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dropdownField(
    String label,
    String? current,
    List<String> items,
    ValueChanged<String?> onChanged,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fallback if current is null or not in items
    final safeValue =
        (current != null && items.contains(current)) ? current : null;

    return InputDecorator(
      decoration: InputDecoration(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        labelText: label,
        labelStyle: TextStyle(
          color: theme.colorScheme.onSurface.withOpacity(0.7),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: .5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
        filled: false,
        fillColor:
            isDark
                ? theme.colorScheme.surfaceVariant.withOpacity(0.3)
                : Colors.grey[200],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isExpanded: true,
          icon: Icon(
            Icons.expand_more,
            color:
                isDark
                    ? theme.colorScheme.onSurface.withOpacity(0.7)
                    : Colors.grey,
          ),
          onChanged: onChanged,
          items:
              items
                  .map(
                    (val) => DropdownMenuItem(
                      value: val,
                      child: Text(
                        val,
                        style: TextStyle(
                          color:
                              isDark
                                  ? theme.colorScheme.onSurface
                                  : Colors.black87,
                        ),
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: isDark ? theme.colorScheme.onSurface : Colors.black87,
        ),
      ),
    );
  }
}
