import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';

class DeviceScreen extends StatelessWidget {
  const DeviceScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final device = controller.deviceProfile;
    return ScreenScaffold(
      title: 'Device',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: CircleAvatar(
                    radius: 72,
                    backgroundColor:
                        Theme.of(context).brightness == Brightness.dark
                        ? Colors.white10
                        : const Color(0xFFE2E8F0),
                    child: const Icon(Icons.watch_outlined, size: 64),
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    'Connect with your device to monitor your vitals',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.secondaryText(context)),
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    device.deviceName,
                    style: TextStyle(
                      color: AppColors.primaryText(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${device.connectionMode} • ${device.batteryLevel}%',
                    style: TextStyle(color: AppColors.secondaryText(context)),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {},
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Connect a device'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
