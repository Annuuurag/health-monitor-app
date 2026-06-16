import 'package:flutter/material.dart';

String formatTimeOfDay(TimeOfDay time) {
  final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
  final minute = time.minute.toString().padLeft(2, '0');
  final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';
  return '$hour:$minute $suffix';
}

String formatHourLabel(DateTime dateTime) {
  final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
  final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
  return '$hour$suffix';
}

String formatShortDateTime(DateTime dateTime) {
  // Convert UTC timestamp to IST (UTC+5:30)
  final ist = dateTime.toUtc().add(const Duration(hours: 5, minutes: 30));
  final day = ist.day.toString().padLeft(2, '0');
  final month = ist.month.toString().padLeft(2, '0');
  final time = formatTimeOfDay(
    TimeOfDay(hour: ist.hour, minute: ist.minute),
  );
  return '$day/$month • $time';
}

