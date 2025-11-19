import 'package:flutter/foundation.dart';
// Shutterbook — Quote overview
// Final review screen in the create-quote flow showing totals and
// allowing the user to save or adjust items.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
  
import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/utils/formatters.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class QuoteOverviewScreen extends StatelessWidget {
final double total;
final Client client;
final Map<Package, int> packages;

  const QuoteOverviewScreen({
    super.key,
    required this.client,
    required this.total,
    required this.packages,
  });

  Future<void> _insertQuote() async {
    final String packageDescription = packages.entries
        .map((entry) => '${entry.key.name} x${entry.value}')
        .join(', ');
    final table = QuoteTable();
    final quote = Quote(
      clientId: client.id!,
      totalPrice: total,
      description: packageDescription,
    );

    await table.insertQuote(quote);
    if (kDebugMode) debugPrint('Inserted quote:${quote.toMap()}');
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) debugPrint('QuoteOverviewScreen built for client ${client.id} total $total');
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Quote Overview'), 3),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Client: ${client.firstName} ${client.lastName}\nTotal: ${formatRand(total)}'),
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map(
              (entry) => Text(
                '${entry.key.name} x${entry.value} - ${formatRand(entry.key.price * entry.value)}',
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () async {
                final nav = Navigator.of(context);
                await _insertQuote();
                if (nav.mounted) {
                  ScaffoldMessenger.of(nav.context).showSnackBar(const SnackBar(content: Text('Quote saved')));
                    //no touch
                    nav.pushNamedAndRemoveUntil( '/home', (route) => false); 
                }
              },
              style: UIStyles.primaryButton(context),
              child: const Text("Save"),
            ),
             ElevatedButton(
               onPressed: () async {
                 final nav = Navigator.of(context);
                 if (nav.mounted) {
                  //no touch
                   nav.pushNamedAndRemoveUntil( '/home', (route) => false); 
                 }
               },
               style: UIStyles.destructiveButton(context),
               child: const Text("Cancel"),
             )
            ,
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}