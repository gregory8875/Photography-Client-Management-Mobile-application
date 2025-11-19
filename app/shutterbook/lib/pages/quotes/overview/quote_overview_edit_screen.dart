import 'package:flutter/material.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/data/tables/quote_table.dart';

import 'package:shutterbook/data/models/package.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'package:shutterbook/utils/formatters.dart';



class QuoteOverviewEditScreen extends StatelessWidget {
final int quoteNum;
final String clientName;
final double total;


final Map<Package, int> packages;

  const QuoteOverviewEditScreen({super.key, required this.total, required this.packages, required this.quoteNum, required this.clientName});


  Future<void> _updateQuote() async
  {
     final String packageDescription = packages.entries
         .map((entry) => '${entry.key.name} x${entry.value}')
         .join(', ');


     final quoteInfo = await QuoteTable().getQuoteById(quoteNum);
     int clientInfoId = 0;

     if (quoteInfo != null) {
       // quoteInfo is a single Quote, not an iterable; extract clientId directly.
       clientInfoId = quoteInfo.clientId;
     }

    

    final quote = Quote(
      id: quoteNum,
      clientId: clientInfoId,
      totalPrice: total,
      description: packageDescription,
    );
    final table = QuoteTable();
    await table.updateQuote(quote);

    debugPrint('Updated quote:${quote.toMap()}');
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Quote Overview'), 3),
      
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Quote #$quoteNum\n$clientName\nTotal: ${formatRand(total)}'),            
            const SizedBox(height: 20),
            const Text('Selected Packages:'),
            ...packages.entries.map((entry) => Text('${entry.key.name} x${entry.value} - ${formatRand(entry.key.price * entry.value)}')),
           const SizedBox(height: 30,),
          ElevatedButton(
              style: UIStyles.primaryButton(context),
              onPressed: () async {
                try {
                  final nav = Navigator.of(context);
                  final messenger = ScaffoldMessenger.of(context);

                  await _updateQuote();
                  
                  if (nav.mounted) {
                    messenger.showSnackBar(const SnackBar(content: Text('Quote updated')));
                    //no touch
                      nav.pushNamedAndRemoveUntil( '/home', (route) => false); 
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to save quote: $e')),
                    );
                  }
                }
              },
              child: const Text("Update"),
            ),
           const SizedBox(height: 10),
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
           ),
           
          ],
        ),
      ),
    );
  }
}