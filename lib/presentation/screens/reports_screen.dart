import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.primaryText(context);
    final secondary = AppColors.secondaryText(context);

    return ScreenScaffold(
      title: 'Reports',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: AppTheme.cardDecoration(context),
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent trend',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'This chart area is ready for AWS-backed history in the next phase.',
                  style: TextStyle(color: secondary),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 128,
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      _TrendBar(heightFactor: 0.36, color: AppColors.teal),
                      _TrendBar(heightFactor: 0.52, color: AppColors.teal),
                      _TrendBar(heightFactor: 0.42, color: AppColors.amber),
                      _TrendBar(heightFactor: 0.64, color: AppColors.teal),
                      _TrendBar(heightFactor: 0.78, color: AppColors.teal),
                      _TrendBar(heightFactor: 0.48, color: AppColors.amber),
                      _TrendBar(heightFactor: 0.58, color: AppColors.teal),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Active time',
            style: TextStyle(
              color: textColor,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final chipWidth = (constraints.maxWidth - 15) / 2;
              return Wrap(
                spacing: 10,
                runSpacing: 10,
                children: controller.reports
                    .map(
                      (report) => _ReportChip(
                        label: report.periodLabel,
                        value: '${report.activeMinutes} min',
                        width: chipWidth,
                      ),
                    )
                    .toList(growable: false),
              );
            },
          ),
          const SizedBox(height: 18),
          ...controller.reports.map(
            (report) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                decoration: AppTheme.cardDecoration(context),
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      report.title,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      report.periodLabel,
                      style: TextStyle(color: secondary),
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final chipWidth = (constraints.maxWidth - 15) / 2;
                        return Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            _ReportChip(
                              label: 'Heart rate',
                              value:
                                  '${report.averageHeartRate.toStringAsFixed(1)} BPM',
                              width: chipWidth,
                            ),
                            _ReportChip(
                              label: 'SpO2',
                              value: '${report.averageSpo2.toStringAsFixed(1)} %',
                              width: chipWidth,
                            ),
                            _ReportChip(
                              label: 'Temp',
                              value:
                                  '${report.averageTemperature.toStringAsFixed(1)} °C',
                              width: chipWidth,
                            ),
                            _ReportChip(
                              label: 'Active',
                              value: '${report.activeMinutes} min',
                              width: chipWidth,
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Text(report.note, style: TextStyle(color: secondary)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrendBar extends StatelessWidget {
  const _TrendBar({required this.heightFactor, required this.color});

  final double heightFactor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          height: 86 * heightFactor,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }
}

class _ReportChip extends StatelessWidget {
  const _ReportChip({required this.label, required this.value, this.width});

  final String label;
  final String value;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? 155,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
