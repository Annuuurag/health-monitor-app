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
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 82,
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                            ? Colors.white10
                            : const Color(0xFFE2E8F0),
                        child: const Icon(Icons.watch_outlined, size: 74),
                      ),
                      Positioned(
                        right: 6,
                        bottom: 6,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: const BoxDecoration(
                            color: AppColors.success,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const Text(
                            'On',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
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
          const SizedBox(height: 18),
          Text(
            'Paired devices (1)',
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.card(context),
              borderRadius: BorderRadius.circular(20),
            ),
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      Theme.of(context).brightness == Brightness.dark
                      ? Colors.white10
                      : const Color(0xFFE2E8F0),
                  child: const Icon(Icons.watch_outlined, size: 40),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        device.deviceName,
                        style: TextStyle(
                          color: AppColors.primaryText(context),
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        device.connectionMode,
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${device.batteryLevel}% battery',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  children: [
                    const Icon(Icons.battery_full, color: AppColors.teal),
                    Text(
                      '${device.batteryLevel}%',
                      style: TextStyle(
                        color: AppColors.primaryText(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
