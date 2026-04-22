import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';

class DevicePairingFlowScreen extends StatefulWidget {
  const DevicePairingFlowScreen({super.key, required this.controller});

  final AppController controller;

  @override
  State<DevicePairingFlowScreen> createState() =>
      _DevicePairingFlowScreenState();
}

class _DevicePairingFlowScreenState extends State<DevicePairingFlowScreen> {
  _PairingMethod? _selectedMethod;

  @override
  Widget build(BuildContext context) {
    final methods = [
      _PairingMethod.bluetooth,
      _PairingMethod.wifi,
      _PairingMethod.usb,
    ];

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: _selectedMethod == null
            ? Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Add a device',
                      style: TextStyle(
                        color: AppColors.darkBackground,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connect to your own device',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Text(
                                'How would you like to connect?',
                                style: TextStyle(
                                  color: AppColors.darkBackground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ...methods.map(
                              (method) => Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: InkWell(
                                  onTap: () =>
                                      setState(() => _selectedMethod = method),
                                  borderRadius: BorderRadius.circular(22),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.softLilac.withValues(
                                        alpha: 0.48,
                                      ),
                                      borderRadius: BorderRadius.circular(22),
                                    ),
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 42,
                                          height: 42,
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              14,
                                            ),
                                          ),
                                          child: Icon(
                                            method.icon,
                                            color: AppColors.teal,
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Expanded(
                                          child: Text(
                                            method.title,
                                            style: const TextStyle(
                                              color: AppColors.darkBackground,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const Spacer(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: OutlinedButton(
                                onPressed: () {},
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size(98, 36),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 22,
                                  ),
                                ),
                                child: const Text('Cancel'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : Padding(
                padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedMethod!.connectionMode,
                      style: const TextStyle(
                        color: AppColors.darkBackground,
                        fontSize: 30,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Connect to your own device',
                      style: TextStyle(
                        color: AppColors.mutedText,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                        ),
                        padding: const EdgeInsets.fromLTRB(14, 18, 14, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                _selectedMethod!.availableLabel,
                                style: const TextStyle(
                                  color: AppColors.darkBackground,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            ...List.generate(
                              5,
                              (index) => Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF4F1FD),
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 16,
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _selectedMethod!.icon,
                                      color: AppColors.teal,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${_selectedMethod!.devicePrefix} ${index + 1}',
                                        style: const TextStyle(
                                          color: AppColors.darkBackground,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                OutlinedButton(
                                  onPressed: () =>
                                      setState(() => _selectedMethod = null),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(96, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                  ),
                                  child: const Text('Cancel'),
                                ),
                                const Spacer(),
                                FilledButton(
                                  onPressed: () =>
                                      widget.controller.completePairing(
                                        _selectedMethod!.connectionMode,
                                      ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(96, 36),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 18,
                                    ),
                                  ),
                                  child: const Text('Next'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

enum _PairingMethod {
  bluetooth(
    title: 'Add using Bluetooth',
    availableLabel: 'Available devices',
    devicePrefix: 'PulseBand',
    connectionMode: 'Bluetooth',
    icon: Icons.bluetooth,
  ),
  wifi(
    title: 'Add using WiFi',
    availableLabel: 'Available networks',
    devicePrefix: 'Health Monitor',
    connectionMode: 'WiFi',
    icon: Icons.wifi,
  ),
  usb(
    title: 'Add using USB',
    availableLabel: 'Available devices',
    devicePrefix: 'USB Device',
    connectionMode: 'USB',
    icon: Icons.usb,
  );

  const _PairingMethod({
    required this.title,
    required this.availableLabel,
    required this.devicePrefix,
    required this.connectionMode,
    required this.icon,
  });

  final String title;
  final String availableLabel;
  final String devicePrefix;
  final String connectionMode;
  final IconData icon;
}
