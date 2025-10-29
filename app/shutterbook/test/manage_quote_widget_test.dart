import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shutterbook/pages/quotes/manage/manage_quote_screen.dart';

class FakeQuoteTable {
  Quote? lastUpdated;
  int? deletedId;
  Future<Quote?> getQuoteById(int id) async => Quote(id: id, clientId: 1, totalPrice: 100.0, description: 'Original', createdAt: DateTime.now());
  Future<void> updateQuote(Quote q) async {
    lastUpdated = q;
  }

  Future<int> deleteQuotes(int id) async {
    deletedId = id;
    return 1;
  }
}

void main() {
  setUpAll(() {
    // Initialize sqflite for tests running on the Dart VM
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });
  testWidgets('ManageQuotePage edit and save flow', (tester) async {
    final quote = Quote(id: 42, clientId: 7, totalPrice: 120.0, description: 'Initial', createdAt: DateTime.now());
    final fake = FakeQuoteTable();

    await tester.pumpWidget(MaterialApp(home: ManageQuotePage(initialQuote: quote, quoteTable: fake)));
    await tester.pumpAndSettle();

  // open edit (disambiguate when multiple edit icons exist)
  expect(find.text('Quote #42'), findsOneWidget);
  // Tap the AppBar edit icon (it's an IconButton) to enter edit mode
  await tester.tap(find.widgetWithIcon(IconButton, Icons.edit).first);
    await tester.pumpAndSettle();

    // change values
    await tester.enterText(find.byType(TextFormField).first, '250.00');
    await tester.enterText(find.byType(TextFormField).at(1), 'Updated description');

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    // verify fake table was called
    expect(fake.lastUpdated, isNotNull);
    expect(fake.lastUpdated!.totalPrice, 250.00);
    expect(fake.lastUpdated!.description, 'Updated description');
  });
}
