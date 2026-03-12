
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
  // Go json.Unmarshal into time.Time requires RFC3339 (ISO-8601) format.
  return date.toUtc().toIso8601String();
}

