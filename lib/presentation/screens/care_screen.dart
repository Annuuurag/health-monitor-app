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
                _RecommendationTile(
                  title: 'Hydration',
                  body:
                      'Drink water and recheck your oxygen level after resting.',
                ),
                const SizedBox(height: 12),
                _RecommendationTile(
                  title: 'Recovery',
                  body:
                      'Avoid high exertion until heart rate settles near baseline.',
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
        borderRadius: BorderRadius.circular(20),
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
