// Shutterbook — main.dart
// Entry point for the Shutterbook app. Sets up theme, routing and the
// initial authentication flow. Small, focused file — keep app wiring here.
// Tip: For theme tweaks, edit ThemeController or the ThemeData builders
// used below rather than changing app wiring.
import 'package:flutter/material.dart';
import 'package:shutterbook/data/db/database_helper.dart';
import 'pages/theme_controller.dart';
import 'pages/bookings/dashboard.dart';
import 'pages/authentication/models/auth_model.dart';
import 'pages/authentication/login.dart';
import 'pages/authentication/auth_setup.dart';
import 'pages/dashboard_home.dart';
import 'pages/quotes/quotes.dart';
import 'package:shutterbook/theme/ui_styles.dart';
import 'pages/bookings/bookings.dart';
import 'pages/clients/clients.dart';
import 'pages/quotes/create/create_quote.dart';
import 'pages/quotes/manage/manage_quote_screen.dart';
import 'pages/inventory/inventory.dart';
import 'data/services/data_cache.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await DatabaseHelper.instance.database;
  await ThemeController.instance.init();

  final authModel = AuthModel();
  await authModel.loadSettings();

  final firstLaunch = await authModel.isFirstLaunch();


  // Prefetch commonly-used caches (non-blocking) to warm the app and
  // reduce perceived latency when navigating to client/booking screens.
  DataCache.instance.getClients();
  DataCache.instance.getBookings();
  runApp(MyApp(authModel: authModel, firstLaunch: firstLaunch));
}

class MyApp extends StatelessWidget {
  final AuthModel authModel;
  final bool firstLaunch;

  const MyApp({super.key, required this.authModel, required this.firstLaunch});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeController.instance.isDark,
      builder: (context, isDark, _) {
  // Palette: Slate Blue seed with coral accent (Option A)
  const seed = Color(0xFF4B6B9A); // slate blue
  const coral = Color(0xFFFF6B6B);
  final baseLight = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light);
  final baseDark = ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.dark);
  final lightScheme = baseLight.copyWith(secondary: coral);
  final darkScheme = baseDark.copyWith(secondary: coral);

        final lightTheme = ThemeData(
          colorScheme: lightScheme,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: lightScheme.primary,
            foregroundColor: lightScheme.onPrimary,
            elevation: 2,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: UIStyles.primaryButton(context),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: UIStyles.outlineButton(context),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: lightScheme.primary),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: lightScheme.secondary,
            foregroundColor: lightScheme.onSecondary,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: lightScheme.surfaceContainerHighest,
            contentTextStyle: TextStyle(color: lightScheme.onSurface),
          ),
          listTileTheme: ListTileThemeData(
            // Use transparent ListTile backgrounds — cards provide the elevated surface.
            shape: null,
            contentPadding: UIStyles.tilePadding,
            tileColor: Colors.transparent,
            iconColor: lightScheme.primary,
          ),
          cardTheme: CardThemeData(color: lightScheme.surfaceContainerHighest, elevation: UIStyles.cardElevation, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          cardColor: lightScheme.surfaceContainerHighest,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: lightScheme.surfaceContainerHighest,
          ),
          scaffoldBackgroundColor: lightScheme.surface,
          textTheme: ThemeData.light()
              .textTheme
              .apply(bodyColor: lightScheme.onSurface, displayColor: lightScheme.onSurface),
        );

        final darkTheme = ThemeData(
          colorScheme: darkScheme,
          useMaterial3: true,
          appBarTheme: AppBarTheme(
            backgroundColor: darkScheme.surfaceContainerHighest,
            foregroundColor: darkScheme.onSurface,
            elevation: 2,
            centerTitle: true,
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: UIStyles.primaryButton(context),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: UIStyles.outlineButton(context),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: darkScheme.primary),
          ),
          floatingActionButtonTheme: FloatingActionButtonThemeData(
            backgroundColor: darkScheme.secondary,
            foregroundColor: darkScheme.onSecondary,
          ),
          snackBarTheme: SnackBarThemeData(
            backgroundColor: darkScheme.surfaceContainerHighest,
            contentTextStyle: TextStyle(color: darkScheme.onSurface),
          ),
          listTileTheme: ListTileThemeData(
            shape: null,
            contentPadding: UIStyles.tilePadding,
            tileColor: Colors.transparent,
            iconColor: darkScheme.primary,
          ),
          cardTheme: CardThemeData(color: darkScheme.surfaceContainerHighest, elevation: UIStyles.cardElevation, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          cardColor: darkScheme.surfaceContainerHighest,
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: darkScheme.surfaceContainerHighest,
          ),
          scaffoldBackgroundColor: darkScheme.surface,
          textTheme: ThemeData.dark()
              .textTheme
              .apply(bodyColor: darkScheme.onSurface, displayColor: darkScheme.onSurface),
        );

        // Build a reusable routes map so onGenerateRoute can reference it.
        final routeMap = {
            '/home': (context) => DashboardHome(authModel: authModel),
            '/quotes': (context) => const QuotePage(),
            '/clients': (context) => const ClientsPage(),
            '/bookings': (context) => const BookingsPage(),
            '/quotes/create': (context) => const CreateQuotePage(),
            '/quotes/manage': (context) => const ManageQuotePage(),
            '/dashboard': (context) => const DashboardPage(),
            '/inventory': (context) => const InventoryPage(),
        };

        return MaterialApp(
          title: 'Local Auth App',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
          // Route guard: when password lock is enabled and the session is not
          // unlocked, redirect navigation attempts to the login screen.
          onGenerateRoute: (settings) {
            // If authModel requires a password and hasn't been unlocked,
            // send the user to LoginScreen first.
            final protected = authModel.hasPassword && !authModel.isUnlocked;
            if (protected) {
              return MaterialPageRoute(
                builder: (_) => LoginScreen(authModel: authModel),
                settings: settings,
              );
            }

            // Fall back to the default routes map if defined
            final builder = (routeMap[settings.name] as WidgetBuilder?);
            if (builder != null) return MaterialPageRoute(builder: builder, settings: settings);
            return null;
          },
          home: Builder(
            builder: (context) {
              if (firstLaunch) {
                return SetupScreen(authModel: authModel);
              }

              if (authModel.hasPassword) {
                return LoginScreen(authModel: authModel);
              }

              // Make the dashboard the landing/home screen for flow
              return DashboardHome(authModel: authModel);
            },
          ),
        );
      },
    );
  }
} 
