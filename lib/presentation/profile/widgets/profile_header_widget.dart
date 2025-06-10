import 'dart:io'; // Import File class
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:image_picker/image_picker.dart'; // Import image_picker
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'package:path_provider/path_provider.dart'; // Import path_provider for saving image
import 'package:provider/provider.dart';
import '../../../data/provider/auth_provider.dart';
import '../../../data/models/user_model.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final VoidCallback? onInsightButtonTap;
  final VoidCallback? onTrophyButtonTap;

  const ProfileHeaderWidget({
    super.key,
    this.onInsightButtonTap,
    this.onTrophyButtonTap,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  File? _imageFile;
  final String _imagePathKey = 'profile_image_path';

  @override
  void initState() {
    super.initState();
    _loadImage(); // Load the saved image on initialization
  }

  // Load image path from SharedPreferences and set the image file
  Future<void> _loadImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString(_imagePathKey);
    if (imagePath != null && imagePath.isNotEmpty) {
      final file = File(imagePath);
      if (await file.exists()) {
        setState(() {
          _imageFile = file;
        });
      } else {
        // If file doesn't exist, clear the saved path
        prefs.remove(_imagePathKey);
      }
    }
  }

  // Pick image from source (gallery or camera)
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      // Save the file to a persistent location within the app's documents directory
      final directory = await getApplicationDocumentsDirectory();
      final newPath =
          '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.png';
      final newImage = await file.copy(newPath);

      // Save the new path in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_imagePathKey, newImage.path);

      setState(() {
        _imageFile = newImage;
      });

      // Update user profile photo in Firebase
      final authProvider = context.read<AuthenticationProvider>();
      // TODO: Implement photo upload to Firebase Storage and update user profile
    }
  }

  // Show dialog/bottom sheet to choose image source
  void _showImageSourceSelection() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Iconsax.camera_outline),
                title: Text('profile.camera'.tr()), // Add localization key
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Iconsax.gallery_outline,
                ), // Add gallery icon
                title: Text('profile.gallery'.tr()), // Add localization key
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Consumer<AuthenticationProvider>(
      builder: (context, authProvider, child) {
        final user = authProvider.user;
        if (user == null) return const SizedBox.shrink();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Image with Camera Edit Button
            Stack(
              alignment: Alignment.center,
              children: [
                // Main Profile Image (larger)
                CircleAvatar(
                  radius: 30,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  child: CircleAvatar(
                    radius: 25,
                    // Display selected image or placeholder
                    backgroundImage:
                        _imageFile != null
                            ? FileImage(_imageFile!) as ImageProvider
                            : (user.photoUrl != null
                                ? NetworkImage(user.photoUrl!) as ImageProvider
                                : const AssetImage(
                                  'assets/icons/cal_burnner.png',
                                )),
                  ),
                ),
                // Camera Edit Button (positioned)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: InkWell(
                    onTap:
                        _showImageSourceSelection, // Call the selection method
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Iconsax.camera_outline,
                        color: theme.colorScheme.onPrimary,
                        size: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Text(
                    user.email ?? 'location_not_set'.tr(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      _buildUserInfoColumn(
                        label: 'age'.tr().toUpperCase(),
                        value: user.age?.toString() ?? 'not_set'.tr(),
                        theme: theme,
                        isDark: isDark,
                      ),
                      const Gap(32),
                      _buildUserInfoColumn(
                        label: 'height'.tr().toUpperCase(),
                        value: user.height?.toString() ?? 'not_set'.tr(),
                        theme: theme,
                        isDark: isDark,
                      ),
                    ],
                  ),
                  const Gap(16),
                  Row(
                    children: [
                      Text(
                        'imp_score'.tr(),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black54,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          user.impScore?.toStringAsFixed(3) ?? '0.000',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Column(
            //   children: [
            //     _buildCircularIconButton(
            //       icon: Iconsax.blur_bold,
            //       color: theme.colorScheme.primary.withOpacity(0.2),
            //       iconColor: theme.colorScheme.primary,
            //       onTap: widget.onInsightButtonTap,
            //     ),
            //     const Gap(16),
            //     _buildCircularIconButton(
            //       icon: Iconsax.cup_outline,
            //       color: theme.colorScheme.primary.withOpacity(0.2),
            //       iconColor: theme.colorScheme.primary,
            //       onTap: widget.onTrophyButtonTap,
            //     ),
            //   ],
            // ),
          ],
        );
      },
    );
  }

  Widget _buildUserInfoColumn({
    required String label,
    required String value,
    required ThemeData theme,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? Colors.white70 : Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  // Helper function for circular icon buttons
  Widget _buildCircularIconButton({
    required IconData icon,
    required Color color,
    required Color iconColor,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(25),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: iconColor, size: 24),
      ),
    );
  }
}
