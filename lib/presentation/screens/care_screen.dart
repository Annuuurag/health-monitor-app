import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/state/app_controller.dart';
import '../../app/theme/app_theme.dart';
import '../../core/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/screen_scaffold.dart';
import '../widgets/reminder_dialog.dart';

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
            trailing: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(Icons.add_circle_outline, color: AppColors.teal),
              onPressed: () async {
                final newReminder = await ReminderDialog.show(context);
                if (newReminder != null) {
                  controller.addReminder(newReminder);
                }
              },
            ),
            child: controller.reminders.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      'No reminders set. Tap the + icon to add one.',
                      style: TextStyle(color: AppColors.secondaryText(context)),
                    ),
                  )
                : Column(
                    children: controller.reminders
                        .map(
                          (reminder) => Dismissible(
                            key: ValueKey(reminder.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red.shade400,
                              child: const Icon(Icons.delete, color: Colors.white),
                            ),
                            onDismissed: (_) =>
                                controller.removeReminder(reminder.id),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
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
                              trailing: Switch(
                                value: reminder.enabled,
                                onChanged: (value) =>
                                    controller.toggleReminder(reminder.id, value),
                                activeThumbColor: AppColors.teal,
                              ),
                              onTap: () async {
                                final updated = await ReminderDialog.show(
                                  context,
                                  reminder: reminder,
                                );
                                if (updated != null) {
                                  controller.updateReminder(updated);
                                }
                              },
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Medical appointments',
            child: _CalendarWidget(controller: controller),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Emergency & SOS',
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.sensors, color: AppColors.amber),
                  title: Text('Auto Fall Detection', style: TextStyle(color: AppColors.primaryText(context))),
                  subtitle: Text('Uses MPU6050 to detect falls and alert contacts', style: TextStyle(color: AppColors.secondaryText(context), fontSize: 12)),
                  trailing: Switch(value: true, onChanged: (_) {}, activeThumbColor: AppColors.teal),
                ),
                const Divider(),
                const _EmergencyContactList(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: 'Caregiver access',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Allow your doctor or family members to securely view your AWS IoT vital stream in real-time.',
                  style: TextStyle(color: AppColors.secondaryText(context), fontSize: 13),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.share),
                    label: const Text('Share Live Stream Link'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.teal,
                      side: const BorderSide(color: AppColors.teal),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
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
  const _SectionCard({required this.title, required this.child, this.trailing});

  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: AppColors.primaryText(context),
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              ?trailing,
            ],
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

class _EmergencyContactList extends StatelessWidget {
  const _EmergencyContactList();

  Future<void> _makeCall(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch dialer: $e');
    }
  }

  Future<void> _sendSms(String number) async {
    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: <String, String>{
        'body': 'EMERGENCY: Fall detected by Health Monitor App! Need immediate assistance.',
      },
    );
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint('Could not launch SMS: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildContact(context, 'Ayushamn', '+916901067583'),
        const Divider(),
        _buildContact(context, 'Subasana', '+918822628485'),
        const Divider(),
        _buildContact(context, 'Tasdeeque', '+919401079809'),
      ],
    );
  }

  Widget _buildContact(BuildContext context, String name, String number) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.contact_phone, color: AppColors.danger),
      title: Text(name, style: TextStyle(color: AppColors.primaryText(context))),
      subtitle: Text(number, style: TextStyle(color: AppColors.secondaryText(context))),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.message, color: AppColors.amber),
            onPressed: () => _sendSms(number),
          ),
          IconButton(
            icon: const Icon(Icons.call, color: AppColors.teal),
            onPressed: () => _makeCall(number),
          ),
        ],
      ),
    );
  }
}

class _CalendarWidget extends StatefulWidget {
  const _CalendarWidget({required this.controller});
  final AppController controller;

  @override
  State<_CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<_CalendarWidget> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
  }

  List<String> _getEventsForDay(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return widget.controller.appointments[normalized] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    final events = _getEventsForDay(_selectedDay!);

    return Column(
      children: [
        TableCalendar<String>(
          firstDay: DateTime.utc(2020, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          eventLoader: _getEventsForDay,
          calendarStyle: const CalendarStyle(
            markerDecoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            selectedDecoration: BoxDecoration(color: AppColors.teal, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: AppColors.amber, shape: BoxShape.circle),
          ),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(color: AppColors.primaryText(context), fontSize: 16),
            leftChevronIcon: Icon(Icons.chevron_left, color: AppColors.primaryText(context)),
            rightChevronIcon: Icon(Icons.chevron_right, color: AppColors.primaryText(context)),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(color: AppColors.primaryText(context)),
            weekendStyle: const TextStyle(color: AppColors.danger),
          ),
          startingDayOfWeek: StartingDayOfWeek.monday,
        ),
        const SizedBox(height: 10),
        if (events.isNotEmpty)
          ...events.map((e) => ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.event, color: AppColors.teal),
            title: Text(e, style: TextStyle(color: AppColors.primaryText(context))),
          )),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _showAddEventDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Appointment'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.teal,
              side: const BorderSide(color: AppColors.teal),
            ),
          ),
        ),
      ],
    );
  }

  void _showAddEventDialog(BuildContext context) {
    final textController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Appointment'),
        content: TextField(
          controller: textController,
          decoration: const InputDecoration(hintText: 'e.g. Cardiology Checkup'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (textController.text.isNotEmpty) {
                widget.controller.addAppointment(_selectedDay!, textController.text.trim());
              }
              Navigator.pop(context);
              setState(() {});
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
