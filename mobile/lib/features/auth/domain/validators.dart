import 'package:intl/intl.dart';

bool isValidEmail(String value) {
  final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  return emailRegex.hasMatch(value.trim());
}

bool isValidPassword(String value) {
  return value.length >= 8;
}

bool isAtLeast18YearsOld(DateTime date) {
  final now = DateTime.now();
  final eighteenYearsAgo = DateTime(now.year - 18, now.month, now.day);
  return date.isBefore(eighteenYearsAgo) || date.isAtSameMomentAs(eighteenYearsAgo);
}

String formatBirthDate(DateTime date) {
  final formatter = DateFormat('yyyy-MM-dd');
  return formatter.format(date);
}

