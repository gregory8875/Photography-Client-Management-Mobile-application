import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class TestAuthState {
  bool hasPassword;
  bool isUnlocked;

  TestAuthState({required this.hasPassword, required this.isUnlocked});
}

void main() {
  testWidgets('Guard redirects to login when locked', (WidgetTester tester) async {
    final auth = TestAuthState(hasPassword: true, isUnlocked: false);

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        final routeMap = {
          '/dashboard': (BuildContext ctx) => const Scaffold(body: Center(child: Text('DASHBOARD'))),
        };
        final protected = auth.hasPassword && !auth.isUnlocked;
        if (protected) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('LOGIN'))));
        }
        final builder = (routeMap[settings.name] as WidgetBuilder?);
        if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);
        return null;
      },
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
              child: const Text('GO'),
            ),
          ),
        );
      }),
    ));

    // Tap the button to navigate
    await tester.tap(find.text('GO'));
    await tester.pumpAndSettle();

    // Should be redirected to LOGIN placeholder
    expect(find.text('LOGIN'), findsOneWidget);
    expect(find.text('DASHBOARD'), findsNothing);
  });

  testWidgets('Guard allows navigation when unlocked', (WidgetTester tester) async {
    final auth = TestAuthState(hasPassword: true, isUnlocked: true);

    await tester.pumpWidget(MaterialApp(
      onGenerateRoute: (settings) {
        final routeMap = {
          '/dashboard': (BuildContext ctx) => const Scaffold(body: Center(child: Text('DASHBOARD'))),
        };
        final protected = auth.hasPassword && !auth.isUnlocked;
        if (protected) {
          return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text('LOGIN'))));
        }
        final builder = (routeMap[settings.name] as WidgetBuilder?);
        if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);
        return null;
      },
      home: Builder(builder: (context) {
        return Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pushNamed('/dashboard'),
              child: const Text('GO'),
            ),
          ),
        );
      }),
    ));

    // Tap the button to navigate
    await tester.tap(find.text('GO'));
    await tester.pumpAndSettle();

    // Should reach the dashboard
    expect(find.text('DASHBOARD'), findsOneWidget);
    expect(find.text('LOGIN'), findsNothing);
  });
}
