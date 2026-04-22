import 'package:flutter/material.dart';

import '../../app/state/app_controller.dart';
import '../../core/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/screen_scaffold.dart';

class CareScreen extends StatelessWidget {
  const CareScreen({super.key, required this.controller});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    const recommendations = [
      (
        title: 'Hydration',
        body: 'Drink water and recheck your oxygen level after resting.',
      ),
      (
        title: 'Recovery',
        body: 'Avoid high exertion until heart rate settles near baseline.',
      ),
      (
        title: 'Breathing',
        body: 'Use slow deep breathing for two minutes after an SpO2 dip.',
      ),
    ];

    return ScreenScaffold(
      title: 'Care',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionCard(
            title: 'Recommendations',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...recommendations.indexed.expand(
                  (entry) => [
                    _RecommendationTile(
                      title: entry.$2.title,
                      body: entry.$2.body,
                    ),
                    if (entry.$1 != recommendations.length - 1)
                      const SizedBox(height: 12),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Medication reminders',
            child: Column(
              children: controller.reminders
                  .map(
                    (reminder) => SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: reminder.enabled,
                      onChanged: (value) =>
                          controller.toggleReminder(reminder.id, value),
                      title: Text(
                        reminder.title,
                        style: TextStyle(color: AppColors.primaryText(context)),
                      ),
                      subtitle: Text(
                        '${reminder.dosage} • ${formatTimeOfDay(TimeOfDay(hour: reminder.hour, minute: reminder.minute))}',
                        style: TextStyle(
                          color: AppColors.secondaryText(context),
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          const SizedBox(height: 16),
          const _SectionCard(
            title: 'Precautions',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PrecautionLine(
                  text: 'Avoid long gaps between meals when activity is high.',
                ),
                SizedBox(height: 10),
                _PrecautionLine(
                  text: 'Keep your wearable charged before bedtime tracking.',
                ),
                SizedBox(height: 10),
                _PrecautionLine(
                  text: 'Review unusual readings again before acting on them.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  const _RecommendationTile({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: 0.04)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(body, style: TextStyle(color: AppColors.secondaryText(context))),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card(context),
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: AppColors.primaryText(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PrecautionLine extends StatelessWidget {
  const _PrecautionLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(top: 5),
          decoration: const BoxDecoration(
            color: AppColors.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
        ),
      ],
    );
  }
}
