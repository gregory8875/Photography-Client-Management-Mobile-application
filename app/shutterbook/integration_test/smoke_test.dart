import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'test_main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('app basic navigation smoke', (tester) async {
    // Launch the real app (uses device/emulator DB)
    await app.main();
    // Give the app some time to initialize and settle
    await tester.pumpAndSettle(const Duration(seconds: 4));

    // Helper to wait for a widget to appear up to a timeout
    Future<bool> waitFor(Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
      final sw = Stopwatch()..start();
      while (sw.elapsed < timeout) {
        await tester.pumpAndSettle(const Duration(milliseconds: 500));
        if (finder.evaluate().isNotEmpty) return true;
      }
      return false;
    }

    // Try dismissing common transient dialogs or onboarding screens
    Future<void> tryDismissDialogs() async {
      final dismissTexts = ['OK', 'Ok', 'Cancel', 'Close', 'Skip', 'Continue', 'Later', "Not now"];
      for (final t in dismissTexts) {
        final f = find.text(t);
        if (f.evaluate().isNotEmpty) {
          await tester.tap(f.first);
          await tester.pumpAndSettle(const Duration(seconds: 1));
        }
      }
    }

    // Helper to tap bottom navigation icons and verify the AppBar title
    Future<void> navigateAndExpect(int tabIndex, String expectedTitle) async {
      final bottomFinder = find.byType(BottomNavigationBar);
      expect(bottomFinder, findsOneWidget);
      // compute tap position for the tab by index
      final bottomBox = tester.renderObject<RenderBox>(bottomFinder);
      final topLeft = bottomBox.localToGlobal(Offset.zero);
      final itemWidth = bottomBox.size.width / 5.0; // 5 tabs
      final dx = topLeft.dx + itemWidth * (tabIndex + 0.5);
      final dy = topLeft.dy + bottomBox.size.height / 2.0;
      await tester.tapAt(Offset(dx, dy));
      // allow animations and possible DB loads
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Match the title inside an AppBar to avoid duplicate text matches elsewhere
      final appBarTitle = find.descendant(
        of: find.byType(AppBar),
        matching: find.text(expectedTitle),
      );
      expect(appBarTitle, findsOneWidget);
    }

    // Ensure the bottom navigation exists (wait and try to dismiss overlays)
    final found = await waitFor(find.byType(BottomNavigationBar));
    if (!found) {
      await tryDismissDialogs();
    }

    // If a BottomNavigationBar exists, navigate the tabs. Otherwise accept landing on Dashboard AppBar.
    if (await waitFor(find.byType(BottomNavigationBar), timeout: const Duration(seconds: 10))) {
      // Dashboard (tab 0)
      await navigateAndExpect(0, 'Dashboard');

      // Bookings (tab 1)
      await navigateAndExpect(1, 'Bookings');

      // Clients (tab 2)
      await navigateAndExpect(2, 'Clients');

      // Quotes (tab 3)
      await navigateAndExpect(3, 'Quotes');

      // Inventory (tab 4)
      await navigateAndExpect(4, 'Inventory');
    } else if (await waitFor(find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')), timeout: const Duration(seconds: 10))) {
      // App landed directly on Dashboard with no bottom nav (acceptable)
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('Dashboard')), findsOneWidget);
    } else {
      expect(false, isTrue, reason: 'Could not find BottomNavigationBar or Dashboard AppBar to proceed with smoke test');
    }

  // Bookings (tab 1)
  await navigateAndExpect(1, 'Bookings');

  // Clients (tab 2)
  await navigateAndExpect(2, 'Clients');

  // Quotes (tab 3)
  await navigateAndExpect(3, 'Quotes');

  // Inventory (tab 4)
  await navigateAndExpect(4, 'Inventory');

    // If quotes list is present, try tapping first quote item to open manage screen
    final quoteTiles = find.byIcon(Icons.description_outlined);
    if (quoteTiles.evaluate().isNotEmpty) {
      await tester.tap(quoteTiles.first);
      await tester.pumpAndSettle(const Duration(seconds: 2));
      // Manage screen shows "Quote #" in the title
      expect(find.textContaining('Quote #'), findsWidgets);
      // Go back
      await tester.pageBack();
      await tester.pumpAndSettle(const Duration(seconds: 1));
    }

  // If bookings list is present, try switching back and forth
  await navigateAndExpect(1, 'Bookings');
  await navigateAndExpect(0, 'Dashboard');
  }, timeout: const Timeout(Duration(minutes: 3)));
}
