import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';
import 'device_screen.dart';
import 'settings_screen.dart';
import 'user_profile_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Profile',
      body: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                  child: Icon(
                    Icons.person_outline,
                    size: 38,
                    color: AppColors.primaryText(context),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        controller.userProfile.name,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Your profile',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _MenuTile(
            title: 'User profile',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(controller: controller),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'Device',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DeviceScreen(controller: controller),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _MenuTile(
            title: 'Settings',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => SettingsScreen(controller: controller),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      child: ListTile(
        onTap: onTap,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          Icons.chevron_right,
          color: AppColors.secondaryText(context),
        ),
      ),
    );
  }
}
