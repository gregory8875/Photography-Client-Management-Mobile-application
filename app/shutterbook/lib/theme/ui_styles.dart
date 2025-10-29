import 'package:flutter/material.dart';
import 'package:shutterbook/theme/app_colors.dart';

/// Centralized UI styles for small, low-risk consistency fixes.
/// Keep this file deliberately small: it provides a few button styles
/// and spacing constants used across screens.
class UIStyles {
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 12, vertical: 8);
  // Slight elevation so cards appear lifted and not completely flat.
  // Increased to improve visual separation from the scaffold background.
  static const double cardElevation = 4.0;

  static ButtonStyle primaryButton(BuildContext context) {
    final t = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: t.colorScheme.primary,
      foregroundColor: t.colorScheme.onPrimary,
      textStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  static ButtonStyle destructiveButton(BuildContext context) {
    final t = Theme.of(context);
    return ElevatedButton.styleFrom(
      backgroundColor: t.colorScheme.error,
      foregroundColor: t.colorScheme.onError,
      textStyle: const TextStyle(fontSize: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  static ButtonStyle outlineButton(BuildContext context) {
    final t = Theme.of(context);
    return OutlinedButton.styleFrom(
      foregroundColor: t.colorScheme.onSurface,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    );
  }

  /// AppBar with a small left color accent and thin underline matching
  /// the tab color at [tabIndex]. Use this for full-screen pages so the
  /// active tab color appears consistently across screens.
  static PreferredSizeWidget accentAppBar(BuildContext context, Widget title, int tabIndex, {List<Widget>? actions}) {
    final color = AppColors.colorForIndex(context, tabIndex);
    return AppBar(
      title: Row(
        children: [
          Container(
            width: 6,
            height: 20,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: color.withAlpha((0.95 * 255).round()),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Allow callers to pass a Text or more complex title widget
          Flexible(child: title),
        ],
      ),
      actions: actions,
      // subtle underline to indicate the active tab
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(3.0),
        child: Container(height: 3.0, color: color.withAlpha((0.6 * 255).round())),
      ),
    );
  }
}
