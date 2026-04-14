import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/alert_event.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key, required this.controller});

  static const routeName = '/alerts';

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Alerts & Notifications',
      body: Column(
        children: controller.alerts
            .map(
              (alert) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AlertCard(
                  alert: alert,
                  onAcknowledge: alert.isAcknowledged
                      ? null
                      : () => controller.acknowledgeAlert(alert.id),
                ),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _AlertCard extends StatelessWidget {
  const _AlertCard({required this.alert, required this.onAcknowledge});

  final AlertEvent alert;
  final VoidCallback? onAcknowledge;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (alert.severity) {
      AlertSeverity.high => AppColors.danger,
      AlertSeverity.medium => AppColors.amber,
      AlertSeverity.low => AppColors.success,
    };

    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  alert.title,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: severityColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Text(
                  alert.severity.name.toUpperCase(),
                  style: TextStyle(
                    color: severityColor,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            alert.message,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 10),
          Text(
            '${alert.category} • ${formatShortDateTime(alert.timestamp)}',
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 12,
            ),
          ),
          if (onAcknowledge != null) ...[
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.tonal(
                onPressed: onAcknowledge,
                child: const Text('Acknowledge'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
