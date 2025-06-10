import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class ProfileImageWidget extends StatelessWidget {
  const ProfileImageWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Stack(
      alignment: Alignment.center,
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
          child: CircleAvatar(
            radius: 25,
            backgroundImage: AssetImage('assets/icons/cal_burnner.png'),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: InkWell(
            onTap: () {
              // Handle profile picture change
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: theme.scaffoldBackgroundColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Iconsax.edit_outline,
                color: theme.colorScheme.onPrimary,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
