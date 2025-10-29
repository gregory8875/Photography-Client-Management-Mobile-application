// Shutterbook — section_card.dart
// A small reusable card wrapper used throughout the app for consistent
// padding, elevation and rounded corners. Use this for compact sections
// and lists to keep the UI consistent.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class SectionCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double elevation;

  const SectionCard({super.key, required this.child, this.padding = const EdgeInsets.all(12), this.elevation = UIStyles.cardElevation});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: theme.cardColor,
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
