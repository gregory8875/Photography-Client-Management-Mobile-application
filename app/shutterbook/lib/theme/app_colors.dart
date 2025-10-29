import 'package:flutter/material.dart';

/// Centralized app colors used for subtle tab accents.
class AppColors {
  // keep these subtle and accessible
  static const List<Color> tabColors = [
    Color(0xFF1565C0), // Dashboard - blue
    Color(0xFF00796B), // Bookings - teal
    Color(0xFF6A1B9A), // Clients - purple
    Color(0xFFF57C00), // Quotes - orange
    Color(0xFF2E7D32), // Inventory - green
  ];

  /// Returns a tab accent color for [index]. When in dark mode we slightly
  /// lighten the base color so the small accent is visible against dark
  /// surfaces (improves contrast without changing the hue dramatically).
  static Color colorForIndex(BuildContext context, int index) {
    final color = tabColors[index % tabColors.length];
    final brightness = Theme.of(context).brightness;
    if (brightness == Brightness.dark) {
      // Blend a small amount of white into the color to raise perceived
      // luminance on dark backgrounds. 0.22 is subtle but improves contrast.
      return Color.lerp(color, Colors.white, 0.22) ?? color;
    }
    return color;
  }
}
