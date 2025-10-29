// Shutterbook — stat_grid.dart
// Simple responsive grid and card widgets for the small statistic tiles
// used on the dashboard. Keeps layout logic local to this component.
import 'package:flutter/material.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class StatItem {
  final String label;
  final String value;
  final IconData icon;

  StatItem({required this.label, required this.value, required this.icon});
}

class StatCard extends StatelessWidget {
  final StatItem item;
  final bool compact;

  const StatCard({super.key, required this.item, this.compact = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pad = compact ? 6.0 : 10.0;
    final iconSize = compact ? 20.0 : 26.0;
    final titleStyle = compact ? theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold) : theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold);
    final labelStyle = theme.textTheme.bodySmall;

    return Card(
      elevation: UIStyles.cardElevation,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: theme.colorScheme.secondaryContainer,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad),
        child: Row(
          children: [
            Icon(item.icon, size: iconSize, color: theme.colorScheme.onSecondaryContainer),
            SizedBox(width: compact ? 8 : 12),
            Flexible(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.value, style: titleStyle?.copyWith(color: theme.colorScheme.onSecondaryContainer)),
                  SizedBox(height: compact ? 2 : 4),
                  Text(item.label, style: labelStyle?.copyWith(color: theme.colorScheme.onSecondaryContainer), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StatGrid extends StatelessWidget {
  final List<StatItem> items;

  const StatGrid({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      // Be more aggressive about compacting stats on narrow screens.
      final crossAxisCount = width >= 700 ? 4 : (width >= 360 ? 2 : 2);

      // Calculate a target width for each card so they fit neatly.
      final spacing = 8.0;
      final cols = crossAxisCount;
      final itemWidth = (width - (cols - 1) * spacing) / cols;

      return Wrap(
        spacing: spacing,
        runSpacing: spacing,
        children: items.map((it) {
          return SizedBox(
            width: itemWidth.clamp(120.0, width),
            child: StatCard(item: it, compact: cols >= 3),
          );
        }).toList(),
      );
    });
  }
}
