import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/alert_event.dart';
import 'alerts_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final snapshot = controller.snapshot;
    if (snapshot == null && controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (snapshot == null) {
      return const Scaffold(
        body: Center(child: Text('No health data available yet.')),
      );
    }

    final textColor = AppColors.primaryText(context);
    final secondaryText = AppColors.secondaryText(context);
    final cardColor = AppColors.card(context);
    final summaryBadgeColor = snapshot.isAnomaly
        ? AppColors.amber
        : AppColors.success;
    final score = snapshot.isAnomaly ? 85 : 93;

    return ScreenScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AlertsScreen.routeName),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: Colors.white),
              if (controller.activeAlertCount > 0)
                Positioned(
                  top: -4,
                  right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.danger,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      controller.activeAlertCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: AppTheme.cardDecoration(context),
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Today\'s summary',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      RichText(
                        text: TextSpan(
                          style: TextStyle(color: textColor, fontSize: 14),
                          children: [
                            const TextSpan(text: 'Overall Status : '),
                            TextSpan(
                              text: snapshot.overallStatus,
                              style: TextStyle(
                                color: summaryBadgeColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        snapshot.summary,
                        style: TextStyle(color: secondaryText, height: 1.35),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Activity: ${snapshot.activityLabel}',
                        style: TextStyle(color: secondaryText),
                      ),
                      Text(
                        'Last updated: ${formatShortDateTime(snapshot.timestamp)}',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.12)
                        : AppColors.cream,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$score',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Health Score',
                        style: TextStyle(color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Key vitals',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1,
            children: [
              MetricCard(
                title: 'Heart Rate',
                value: snapshot.heartRateBpm.toStringAsFixed(0),
                unit: 'BPM',
                footer: 'Status: Normal',
                color: AppColors.teal,
              ),
              MetricCard(
                title: 'SPO2',
                value: snapshot.spo2Percent.toStringAsFixed(0),
                unit: '%',
                footer: 'Status: Low',
                color: AppColors.amber,
              ),
              MetricCard(
                title: 'Body Temperature',
                value: snapshot.bodyTempC.toStringAsFixed(1),
                unit: '°C',
                footer: 'Status: Normal',
                color: AppColors.teal,
              ),
              const MetricCard(
                title: 'Step Count',
                value: '12,973',
                unit: '',
                footer: '7 day avg: 8,322',
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: AppTheme.cardDecoration(context),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Alerts & Notifications',
                        style: TextStyle(
                          color: textColor,
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, AlertsScreen.routeName),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...controller.alerts
                    .take(2)
                    .map(
                      (alert) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _AlertTile(alert: alert),
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

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertEvent alert;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A515A)
        : const Color(0xFFF1F5F9);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            alert.title,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.message,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            alert.category,
            style: TextStyle(
              color: AppColors.secondaryText(context),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
