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
    final device = controller.deviceProfile;
    return ScreenScaffold(
      title: 'Profile',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 22),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ProfileBubble(
                  icon: Icons.person_outline,
                  label: 'User',
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                ),
                _ProfileBubble(
                  icon: Icons.watch_outlined,
                  label: device.connectionMode,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
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
          Material(
            color: AppColors.card(context),
            borderRadius: BorderRadius.circular(18),
            child: SwitchListTile(
              value: controller.settings.darkMode,
              onChanged: controller.updateTheme,
              title: Text(
                'Dark mode',
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontWeight: FontWeight.w500,
                ),
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: controller.signOut,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileBubble extends StatelessWidget {
  const _ProfileBubble({
    required this.icon,
    required this.label,
    required this.backgroundColor,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 48,
          backgroundColor: backgroundColor,
          child: Icon(icon, size: 42, color: AppColors.primaryText(context)),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            color: AppColors.secondaryText(context),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
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
