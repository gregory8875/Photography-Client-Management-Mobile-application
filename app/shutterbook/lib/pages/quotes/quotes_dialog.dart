// Shutterbook — Quotes dialog
// Small modal that lists quotes and allows quick selection for actions
// such as creating a booking.
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/utils/formatters.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class QuotesDialog extends StatefulWidget {
  const QuotesDialog({super.key});

  @override
  State<QuotesDialog> createState() => _QuotesDialogState();
}

class _QuotesDialogState extends State<QuotesDialog> {
  late Future<List<Quote>> _quotesFuture;

  @override
  void initState() {
    super.initState();
    _quotesFuture = QuoteTable().getAllQuotes();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('All Quotes'),
      content: LayoutBuilder(builder: (context, constraints) {
        final maxAvailable = MediaQuery.of(context).size.height;
        final maxHeight = math.min(420.0, maxAvailable * 0.75);
        return SizedBox(
          width: double.maxFinite,
          height: maxHeight,
          child: FutureBuilder<List<Quote>>(
            future: _quotesFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return const Center(child: Text('Failed to load quotes.'));
              }
              final quotes = snapshot.data ?? const <Quote>[];
              if (quotes.isEmpty) {
                return const Center(child: Text('No quotes found.'));
              }
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: ListView.separated(
                  itemCount: quotes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final q = quotes[index];
                    final title = 'Quote #${q.id}';
                    final subtitle = 'Total: ${formatRand(q.totalPrice)} • ${formatDateTime(q.createdAt)}';
                    return Semantics(
                      label: 'Quote ${q.id} ${q.description}',
                      button: true,
                      child: ListTile(
                        contentPadding: UIStyles.tilePadding,
                        leading: const Icon(Icons.description_outlined),
                        title: Text(title),
                        subtitle: Text(
                          '${q.description}\n$subtitle',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Tooltip(
                          message: 'Book from quote ${q.id}',
                          child: OutlinedButton.icon(
                            style: UIStyles.outlineButton(context),
                            onPressed: () => Navigator.of(context).pop<Quote>(q),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Book'),
                          ),
                        ),
                        onTap: () => Navigator.of(context).pop<Quote>(q),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        );
      }),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
