import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'test_main.dart' as app;
import 'package:integration_test/integration_test.dart';
import 'package:shutterbook/data/tables/quote_table.dart';
import 'package:shutterbook/data/tables/booking_table.dart';
import 'package:shutterbook/data/tables/client_table.dart';
import 'package:shutterbook/data/models/client.dart';
import 'package:shutterbook/data/models/quote.dart';
import 'package:shutterbook/pages/quotes/manage/manage_quote_screen.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('create quote -> book from quote -> booking present', (tester) async {
    await app.main();
    await tester.pumpAndSettle(const Duration(seconds: 3));

  // Navigate to Quotes screen using the app's navigator (more reliable)
  final navigatorState = tester.state<NavigatorState>(find.byType(Navigator));
  navigatorState.pushNamed('/quotes');
  await tester.pumpAndSettle(const Duration(seconds: 2));

    // For reliability: insert a test client and a test quote directly
  final client = Client(firstName: 'Test', lastName: 'User', email: 'test.user@example.com', phone: '0000000000');
    final clientId = await ClientTable().insertClient(client);
    final savedClient = (await ClientTable().getClientById(clientId))!;

    final quote = Quote(clientId: savedClient.id!, totalPrice: 123.45, description: 'Integration test quote');
    await QuoteTable().insertQuote(quote);
    final quotes = await QuoteTable().getAllQuotes();
    expect(quotes, isNotEmpty);
    final q = quotes.first;

  // Mount the ManageQuotePage directly so the test interacts with just that screen.
  await tester.pumpWidget(MaterialApp(home: ManageQuotePage(initialQuote: q)));
  await tester.pumpAndSettle(const Duration(seconds: 2));

  // We're on ManageQuotePage. Tap the Book button text directly
  final bookText = find.text('Book');
  expect(bookText, findsWidgets);
  await tester.tap(bookText.first);
    await tester.pumpAndSettle(const Duration(seconds: 1));

    // On CreateBookingPage: select date/time by tapping the Select Date & Time button
    final selectBtn = find.textContaining('Select Date & Time');
    if (selectBtn.evaluate().isNotEmpty) {
      await tester.tap(selectBtn.first);
      await tester.pumpAndSettle(const Duration(seconds: 1));
      // For the DatePicker, accept the default date by tapping OK if present
      final ok = find.text('OK');
      if (ok.evaluate().isNotEmpty) {
        await tester.tap(ok.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
      // For TimePicker, accept default time
      final ok2 = find.text('OK');
      if (ok2.evaluate().isNotEmpty) {
        await tester.tap(ok2.first);
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
      }
    }

    // Tap Save Booking
    final saveBooking = find.text('Save Booking');
    expect(saveBooking, findsWidgets);
    await tester.tap(saveBooking.first);
    await tester.pumpAndSettle(const Duration(seconds: 2));

    // Finally, query BookingTable for bookings by client
    final bookings = await BookingTable().getBookingsByClient(q.clientId);
    expect(bookings, isNotEmpty);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
