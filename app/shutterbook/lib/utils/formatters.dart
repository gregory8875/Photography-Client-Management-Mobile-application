// Shutterbook — formatters.dart
// Tiny, focused formatting helpers used across the app. Kept intentionally
// minimal to avoid pulling in heavy locale packages. Replace with `intl`
// if you need locale-aware formatting in the future.

/// Format a numeric value as South African Rand with two decimal places.
String formatRand(double value) {
  const currency = 'R';
  return '$currency${value.toStringAsFixed(2)}';
}

/// Format a DateTime as a readable date and time string (without seconds/milliseconds).
/// Example: "2025-10-28 14:30"
String formatDateTime(DateTime? dateTime) {
  if (dateTime == null) return 'N/A';
  
  final year = dateTime.year.toString();
  final month = dateTime.month.toString().padLeft(2, '0');
  final day = dateTime.day.toString().padLeft(2, '0');
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');
  
  return '$year-$month-$day / $hour:$minute';
}
