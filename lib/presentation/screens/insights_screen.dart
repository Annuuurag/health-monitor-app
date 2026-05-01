import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../../domain/models/insight_result.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ScreenScaffold(
      title: 'Insights',
      body: Column(
        children: controller.insights
            .map(
              (insight) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _InsightCard(insight: insight),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight});

  final InsightResult insight;

  @override
  Widget build(BuildContext context) {
    final severityColor = switch (insight.severity) {
      InsightSeverity.high => AppColors.danger,
      InsightSeverity.moderate => AppColors.amber,
      InsightSeverity.low => AppColors.success,
    };

    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  insight.title,
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 18,
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
                  '${(insight.confidence * 100).round()}%',
                  style: TextStyle(
                    color: severityColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            insight.summary,
            style: TextStyle(color: AppColors.primaryText(context)),
          ),
          const SizedBox(height: 10),
          Text(
            insight.suggestion,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
        ],
      ),
    );
  }
}
