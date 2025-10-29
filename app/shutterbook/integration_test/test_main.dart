import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart' show WidgetsFlutterBinding, runApp;
import 'package:shutterbook/pages/theme_controller.dart';
import 'package:shutterbook/pages/authentication/models/auth_model.dart';
import 'package:shutterbook/main.dart' show MyApp;

// Test entrypoint: boots the app but forces AuthModel to `no password` so
// the app lands on DashboardHome without requiring login UI.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // initialize theme controller similarly to prod_main
  await ThemeController.instance.init();

  final authModel = AuthModel();
  // force unloaded settings such that hasPassword is false
  // we cannot directly mutate private fields; instead ensure loadSettings is called
  await authModel.loadSettings();
  // If any password exists in test environment, try to remove it (best-effort)
  try {
    await authModel.removePassword();
  } catch (_) {}

  final firstLaunch = false;

  runApp(MyApp(authModel: authModel, firstLaunch: firstLaunch));
}
