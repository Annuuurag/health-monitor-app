import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Settings',
      body: Column(
        children: [
          _ActionTile(
            title: 'Delete Account',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Delete account flow is not enabled in demo mode.',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _SettingSwitchTile(
            title: 'Push Notification',
            value: controller.settings.notificationsEnabled,
            onChanged: controller.updateNotifications,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.title, required this.onTap});

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
      ),
    );
  }
}

class _SettingSwitchTile extends StatelessWidget {
  const _SettingSwitchTile({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.card(context),
      borderRadius: BorderRadius.circular(18),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            color: AppColors.primaryText(context),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
