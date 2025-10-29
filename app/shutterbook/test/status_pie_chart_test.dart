import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shutterbook/pages/bookings/stats_page.dart';

void main() {
  testWidgets('StatusPieChart renders without overflow for multiple datasets', (tester) async {
    final small = {'confirmed': 2, 'cancelled': 1};
    final three = {'confirmed': 3, 'cancelled': 1, 'pending': 2};
    final many = {'a': 1, 'b': 2, 'c': 3, 'd': 1, 'e': 2};

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusPieChart(bookingsByStatus: small))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'No exceptions for small dataset');

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusPieChart(bookingsByStatus: three))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'No exceptions for three-item dataset');

    await tester.pumpWidget(MaterialApp(home: Scaffold(body: StatusPieChart(bookingsByStatus: many))));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'No exceptions for many-item dataset');
  });

  testWidgets('StatusPieChart legend remains readable on narrow widths', (tester) async {
    final three = {'confirmed': 3, 'cancelled': 1, 'pending': 2};

    // Constrain width to simulate a small tile (e.g. phone in portrait)
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(width: 240, child: StatusPieChart(bookingsByStatus: three)),
        ),
      ),
    ));

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull, reason: 'No exceptions when legend is constrained to narrow width');
  });
}
