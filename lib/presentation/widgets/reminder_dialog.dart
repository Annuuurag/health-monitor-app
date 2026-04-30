import 'package:flutter/material.dart';

import '../../core/app_colors.dart';
import '../../domain/models/medication_reminder.dart';

class ReminderDialog extends StatefulWidget {
  const ReminderDialog({super.key, this.reminder});

  final MedicationReminder? reminder;

  static Future<MedicationReminder?> show(BuildContext context,
      {MedicationReminder? reminder}) {
    return showDialog<MedicationReminder>(
      context: context,
      builder: (context) => ReminderDialog(reminder: reminder),
    );
  }

  @override
  State<ReminderDialog> createState() => _ReminderDialogState();
}

class _ReminderDialogState extends State<ReminderDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _dosageController;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.reminder?.title);
    _dosageController = TextEditingController(text: widget.reminder?.dosage);
    _time = widget.reminder != null
        ? TimeOfDay(hour: widget.reminder!.hour, minute: widget.reminder!.minute)
        : TimeOfDay.now();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dosageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
    );
    if (picked != null && picked != _time) {
      setState(() {
        _time = picked;
      });
    }
  }

  void _save() {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    final newReminder = MedicationReminder(
      id: widget.reminder?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: _titleController.text.trim(),
      dosage: _dosageController.text.trim(),
      hour: _time.hour,
      minute: _time.minute,
      enabled: widget.reminder?.enabled ?? true,
    );

    Navigator.of(context).pop(newReminder);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AlertDialog(
      backgroundColor: AppColors.card(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(
        widget.reminder == null ? 'Add Reminder' : 'Edit Reminder',
        style: TextStyle(
          color: AppColors.primaryText(context),
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              style: TextStyle(color: AppColors.primaryText(context)),
              decoration: InputDecoration(
                labelText: 'Title / Reason',
                labelStyle: TextStyle(color: AppColors.secondaryText(context)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondaryText(context).withOpacity(0.3)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.teal),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dosageController,
              style: TextStyle(color: AppColors.primaryText(context)),
              decoration: InputDecoration(
                labelText: 'Dosage or Additional Info',
                labelStyle: TextStyle(color: AppColors.secondaryText(context)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.secondaryText(context).withOpacity(0.3)),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: AppColors.teal),
                ),
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Time',
                  style: TextStyle(
                    color: AppColors.primaryText(context),
                    fontSize: 16,
                  ),
                ),
                TextButton(
                  onPressed: _selectTime,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.teal,
                  ),
                  child: Text(
                    _time.format(context),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColors.secondaryText(context)),
          ),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
