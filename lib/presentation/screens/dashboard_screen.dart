import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/metric_card.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/alert_event.dart';
import '../../domain/models/telemetry_sample.dart';
import 'alerts_screen.dart';

// ── Temperature offset ────────────────────────────────────────────────────────
// The MPU6050 reports its own chip temperature (~48-50°C).
// Subtracting 11°C gives an approximate body temperature reading (37-39°C).
const double _tempOffset = -11.0;

// ── Health score calculation ──────────────────────────────────────────────────

/// Computes a 0–100 health score from live vitals.
/// Returns null when no finger is detected (no meaningful vitals).
///
/// Deductions from 100:
///   HR mildly out of range (60-59 or 101-120 BPM) → -5
///   HR severely out of range (<50 or >120 BPM)    → -15
///   SpO2 mildly low (92–94%)                      → -5
///   SpO2 critically low (<92%)                    → -20
///   Body temp mild fever (37.5–38°C)              → -5
///   Body temp high fever (>38°C)                  → -15
///   ML anomaly flag                               → -10
///   Result clamped to [0, 100].
int? _calcHealthScore({
  required double hr,
  required double spo2,
  required double displayTemp,
  required bool isAnomaly,
}) {
  if (hr == 0 && spo2 == 0) return null; // no finger → no score

  int score = 100;

  // Heart rate deductions
  if (hr > 0) {
    if (hr < 50 || hr > 120) {
      score -= 15;
    } else if (hr < 60 || hr > 100) {
      score -= 5;
    }
  }

  // SpO2 deductions
  if (spo2 > 0) {
    if (spo2 < 92) {
      score -= 20;
    } else if (spo2 < 95) {
      score -= 5;
    }
  }

  // Temperature deductions
  if (displayTemp > 38.0) {
    score -= 15;
  } else if (displayTemp > 37.5) {
    score -= 5;
  }

  // ML anomaly penalty
  if (isAnomaly) score -= 10;

  return score.clamp(0, 100);
}

/// Returns a grade label + colour for a numeric health score.
(String, Color) _scoreGrade(int score) {
  if (score >= 90) return ('Excellent', const Color(0xFF2ECC71));
  if (score >= 75) return ('Good', const Color(0xFF27AE60));
  if (score >= 60) return ('Fair', const Color(0xFFF39C12));
  return ('Poor', const Color(0xFFE74C3C));
}

// ─────────────────────────────────────────────────────────────────────────────

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.controller});

  final AppController controller;

  // ── Step helpers ──────────────────────────────────────────────────────────

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

  int _todaySteps(List<TelemetrySample> samples) {
    final now =
        DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    final today = DateTime(now.year, now.month, now.day);
    final todaySamples = samples.where((s) {
      final ist =
          s.timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
      return DateTime(ist.year, ist.month, ist.day) == today;
    }).toList();
    return _calculateStepsForSamples(todaySamples);
  }

  int? _sevenDayAvgSteps(List<TelemetrySample> samples) {
    if (samples.isEmpty) return null;

    final Map<DateTime, List<TelemetrySample>> dailySamplesMap = {};
    for (final s in samples) {
      final ist =
          s.timestamp.toUtc().add(const Duration(hours: 5, minutes: 30));
      final day = DateTime(ist.year, ist.month, ist.day);
      dailySamplesMap.putIfAbsent(day, () => []).add(s);
    }

    if (dailySamplesMap.isEmpty) return null;

    int totalStepsSum = 0;
    for (final daySamples in dailySamplesMap.values) {
      totalStepsSum += _calculateStepsForSamples(daySamples);
    }

    return (totalStepsSum / dailySamplesMap.length).round();
  }

  // ── Alert helpers ─────────────────────────────────────────────────────────

  List<AlertEvent> _liveAlerts() {
    final snapshot = controller.snapshot;
    if (snapshot == null) return controller.alerts;

    final List<AlertEvent> live = [];
    final now = snapshot.timestamp;

    if (snapshot.isAnomaly) {
      live.add(AlertEvent(
        id: 'anomaly_${now.millisecondsSinceEpoch}',
        title: 'Health anomaly detected',
        message: snapshot.summary,
        severity: AlertSeverity.high,
        timestamp: now,
        category: 'Vitals',
        isAcknowledged: false,
      ));
    }

    final hr = snapshot.heartRateBpm;
    if (hr > 0 && (hr < 50 || hr > 120)) {
      live.add(AlertEvent(
        id: 'hr_${now.millisecondsSinceEpoch}',
        title: hr > 120 ? 'High heart rate detected' : 'Low heart rate detected',
        message:
            'Heart rate is ${hr.toStringAsFixed(0)} BPM. '
            '${hr > 120 ? 'Consider resting.' : 'Consider consulting a doctor.'}',
        severity: AlertSeverity.high,
        timestamp: now,
        category: 'Vitals',
        isAcknowledged: false,
      ));
    }

    final spo2 = snapshot.spo2Percent;
    if (spo2 > 0 && spo2 < 94) {
      live.add(AlertEvent(
        id: 'spo2_${now.millisecondsSinceEpoch}',
        title: 'SpO2 below normal detected',
        message:
            'Blood oxygen is ${spo2.toStringAsFixed(0)}%. '
            'Check breathing and rest.',
        severity: AlertSeverity.high,
        timestamp: now,
        category: 'Vitals',
        isAcknowledged: false,
      ));
    }

    final temp = snapshot.bodyTempC + _tempOffset;
    if (temp > 38.0) {
      live.add(AlertEvent(
        id: 'temp_${now.millisecondsSinceEpoch}',
        title: 'Elevated body temperature',
        message:
            'Temperature is ${temp.toStringAsFixed(1)}°C. '
            '${temp > 39.0 ? 'High fever — seek medical attention.' : 'Mild fever — rest and stay hydrated.'}',
        severity: temp > 39.0 ? AlertSeverity.high : AlertSeverity.medium,
        timestamp: now,
        category: 'Vitals',
        isAcknowledged: false,
      ));
    }

    return live.isNotEmpty ? live : controller.alerts;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

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
    final summaryBadgeColor =
        snapshot.isAnomaly ? AppColors.amber : AppColors.success;

    // ── Adjusted temperature ─────────────────────────────────────────────
    final displayTemp = snapshot.bodyTempC + _tempOffset;

    // ── Dynamic card values ──────────────────────────────────────────────
    final hr = snapshot.heartRateBpm;
    final spo2 = snapshot.spo2Percent;

    final hrColor =
        (hr > 0 && (hr < 50 || hr > 120)) ? AppColors.amber : AppColors.teal;
    final hrFooter = hr == 0
        ? 'No finger detected'
        : (hr < 50 || hr > 120)
            ? 'Status: Abnormal'
            : 'Status: Normal';

    final spo2Color =
        (spo2 > 0 && spo2 < 94) ? AppColors.amber : AppColors.teal;
    final spo2Footer = spo2 == 0
        ? 'No finger detected'
        : spo2 < 94
            ? 'Status: Low'
            : 'Status: Normal';

    final tempColor =
        (displayTemp < 35.5 || displayTemp > 38.0)
            ? AppColors.amber
            : AppColors.teal;
    final tempFooter = displayTemp > 38.0
        ? 'Status: Fever'
        : displayTemp < 35.5
            ? 'Status: Low'
            : 'Status: Normal';

    // ── Health score ─────────────────────────────────────────────────────
    final healthScore = _calcHealthScore(
      hr: hr,
      spo2: spo2,
      displayTemp: displayTemp,
      isAnomaly: snapshot.isAnomaly,
    );
    final scoreLabel = healthScore == null ? '--' : '$healthScore';
    final (gradeLabel, gradeColor) = healthScore == null
        ? ('No data', Colors.grey)
        : _scoreGrade(healthScore);

    // ── Step count ───────────────────────────────────────────────────────
    final todaySteps = _todaySteps(controller.samples);
    final sevenDayAvg = _sevenDayAvgSteps(controller.samples);
    final stepFooter =
        sevenDayAvg != null ? '7 day avg: $sevenDayAvg' : '7 day avg: --';

    // ── Live alerts ──────────────────────────────────────────────────────
    final alerts = _liveAlerts();

    return ScreenScaffold(
      title: 'Dashboard',
      actions: [
        IconButton(
          onPressed: () =>
              Navigator.pushNamed(context, AlertsScreen.routeName),
          icon: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.notifications_none, color: Colors.white),
              if (alerts.isNotEmpty)
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
                      alerts.length.toString(),
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
          // ── Today's summary card ───────────────────────────────────────
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
                        style:
                            TextStyle(color: secondaryText, height: 1.35),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Activity: ${snapshot.activityLabel}',
                        style: TextStyle(color: secondaryText),
                      ),
                      Text(
                        'Last updated: ${formatShortDateTime(snapshot.timestamp)} IST',
                        style: TextStyle(
                            color: secondaryText, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // ── Health score circle ──────────────────────────────
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: healthScore == null
                        ? (Theme.of(context).brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.12)
                            : AppColors.cream)
                        : gradeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: healthScore != null
                        ? Border.all(color: gradeColor, width: 2.5)
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          color:
                              healthScore != null ? gradeColor : textColor,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        gradeLabel,
                        style: TextStyle(
                          color: healthScore != null
                              ? gradeColor
                              : secondaryText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Key vitals heading ─────────────────────────────────────────
          Text(
            'Key vitals',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),

          // ── Vitals grid ────────────────────────────────────────────────
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
                value: hr.toStringAsFixed(0),
                unit: 'BPM',
                footer: hrFooter,
                color: hrColor,
              ),
              MetricCard(
                title: 'SPO2',
                value: spo2.toStringAsFixed(0),
                unit: '%',
                footer: spo2Footer,
                color: spo2Color,
              ),
              MetricCard(
                title: 'Body Temperature',
                value: displayTemp.toStringAsFixed(1),
                unit: '°C',
                footer: tempFooter,
                color: tempColor,
              ),
              MetricCard(
                title: 'Step Count',
                value: todaySteps.toString(),
                unit: '',
                footer: stepFooter,
                color: AppColors.teal,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Alerts & Notifications ─────────────────────────────────────
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
                      onPressed: () => Navigator.pushNamed(
                          context, AlertsScreen.routeName),
                      child: const Text('View all'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (alerts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No active alerts. All vitals look normal.',
                      style: TextStyle(color: secondaryText),
                    ),
                  )
                else
                  ...alerts.take(2).map(
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

// ── Alert tile ────────────────────────────────────────────────────────────────

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertEvent alert;

  @override
  Widget build(BuildContext context) {
    final background = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF4A515A)
        : const Color(0xFFF1F5F9);

    final borderColor = alert.severity == AlertSeverity.high
        ? AppColors.danger
        : alert.severity == AlertSeverity.medium
            ? AppColors.amber
            : AppColors.success;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
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
