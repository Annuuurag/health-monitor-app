import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/telemetry_sample.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key, required this.controller});

  final AppController controller;

  int _calculateStepsForSamples(List<TelemetrySample> daySamples) {
    if (daySamples.isEmpty) return 0;

    // Sort chronologically (oldest first)
    final sorted = List<TelemetrySample>.from(daySamples)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    int total = 0;
    int prevVal = 0;

    for (int i = 0; i < sorted.length; i++) {
      final curVal = sorted[i].stepCount;
      if (i == 0) {
        total = curVal;
      } else {
        if (curVal >= prevVal) {
          total += (curVal - prevVal);
        } else {
          // Reset detected
          total += curVal;
        }
      }
      prevVal = curVal;
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final textColor = AppColors.primaryText(context);
    final secondary = AppColors.secondaryText(context);

    // Calculate daily step counts for the past 7 days (including today) in IST
    final nowIst = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final todayDate = DateTime(nowIst.year, nowIst.month, nowIst.day);

    final List<DateTime> past7Days = List.generate(7, (i) => todayDate.subtract(Duration(days: 6 - i)));

    final displayBars = <Widget>[];
    if (controller.samples.isEmpty) {
      // Fallback mock step trend bars if no data is loaded yet
      const mockBars = [
        _TrendBar(heightFactor: 0.18, color: AppColors.amber, label: '900'),
        _TrendBar(heightFactor: 0.30, color: AppColors.teal, label: '1.5k'),
        _TrendBar(heightFactor: 0.56, color: AppColors.teal, label: '2.8k'),
        _TrendBar(heightFactor: 0.24, color: AppColors.amber, label: '1.2k'),
        _TrendBar(heightFactor: 0.72, color: AppColors.teal, label: '3.6k'),
        _TrendBar(heightFactor: 0.88, color: AppColors.teal, label: '4.4k'),
        _TrendBar(heightFactor: 0.48, color: AppColors.teal, label: '2.4k'),
      ];
      displayBars.addAll(mockBars);
    } else {
      for (final day in past7Days) {
        // Filter samples for this specific day in IST
        final daySamples = controller.samples.where((s) {
          final ist = s.timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
          return DateTime(ist.year, ist.month, ist.day) == day;
        }).toList();

        final steps = _calculateStepsForSamples(daySamples);

        // Normalise steps (relative to a 5,000 steps daily target)
        final double heightFactor = (steps / 5000.0).clamp(0.08, 1.0);
        // Teal for active day (>= 2500 steps), amber for low activity
        final color = steps >= 2500 ? AppColors.teal : AppColors.amber;

        String label;
        if (steps >= 1000) {
          label = '${(steps / 1000.0).toStringAsFixed(1)}k';
        } else {
          label = steps.toString();
        }

        displayBars.add(
          _TrendBar(
            heightFactor: heightFactor,
            color: color,
            label: label,
          ),
        );
      }
    }

    final chartSubtitle = controller.samples.isEmpty
        ? 'Showing baseline step count trend.'
        : 'Daily step count trends for the past 7 days.';

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
                  chartSubtitle,
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: displayBars,
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
  const _TrendBar({
    required this.heightFactor,
    required this.color,
    required this.label,
  });

  final double heightFactor;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            height: 70 * heightFactor,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
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
