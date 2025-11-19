// Shutterbook — formatters.dart
// Tiny, focused formatting helpers used across the app. Uses `intl` to
// provide consistent South African Rand (ZAR) formatting across the UI.
import 'package:intl/intl.dart';

/// Format a numeric value as South African Rand (ZAR) with two decimal places.
String formatRand(double value) {
  final fmt = NumberFormat.simpleCurrency(name: 'ZAR', decimalDigits: 2);
  return fmt.format(value);
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
