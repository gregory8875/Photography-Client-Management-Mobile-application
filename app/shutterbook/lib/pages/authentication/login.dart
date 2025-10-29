// Shutterbook — Login screen
// Lightweight login page used when the app is protected by a password.
// Authentication is handled by AuthModel and the services under the
// authentication/services directory.
import 'package:flutter/material.dart';
import 'models/auth_model.dart';
import '../dashboard_home.dart';
import '../../widgets/section_card.dart';
import '../../widgets/password_field.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class LoginScreen extends StatefulWidget {
  final AuthModel authModel;

  const LoginScreen({super.key, required this.authModel});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Attempt biometrics after the first frame so context and platform are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricLogin();
    });
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricLogin() async {
    final shouldTry = widget.authModel.biometricEnabled && widget.authModel.hasPassword;
    if (shouldTry) {
      final navigator = Navigator.of(context);
      // only try authentication if biometrics are available on the device
      final available = await widget.authModel.isBiometricAvailable();
      if (!available) return;

      // brief delay to let platform channels settle
      await Future.delayed(const Duration(milliseconds: 150));

      if (!mounted) return;
      setState(() => _isLoading = true);
      bool success = false;
      try {
        success = await widget.authModel.unlockWithBiometrics();
      } catch (e) {
        // swallow errors on automatic attempt
        success = false;
      }
      if (!mounted) return;
      setState(() => _isLoading = false);

      if (success) {
        navigator.pushReplacement(
          MaterialPageRoute(builder: (_) => DashboardHome(authModel: widget.authModel)),
        );
      }
    } else {
      // not using biometrics or no password set; simply continue
    }
  }

  Future<void> _loginWithPassword() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (mounted) setState(() => _isLoading = true);
    final valid = await widget.authModel.verifyPassword(password);
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (valid) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardHome(authModel: widget.authModel)),
      );
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Incorrect password')));
    }
  }

  // navigation is performed inline to avoid using BuildContext across async gaps

  Future<void> _loginWithBiometric() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (mounted) setState(() => _isLoading = true);
    final success = await widget.authModel.unlockWithBiometrics();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      navigator.pushReplacement(
        MaterialPageRoute(builder: (_) => DashboardHome(authModel: widget.authModel)),
      );
    } else {
      messenger.showSnackBar(const SnackBar(content: Text('Biometric authentication failed')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final biometricsOn =
        widget.authModel.hasPassword && widget.authModel.biometricEnabled;

    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Login'), 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                SectionCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Welcome Back!',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      PasswordField(
                        controller: _passwordController,
                        labelText: 'Enter password',
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (_isLoading)
                  const CircularProgressIndicator()
                else ...[
                  ElevatedButton(
                    style: UIStyles.primaryButton(context),
                    onPressed: _loginWithPassword,
                    child: const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  if (biometricsOn)
                    Column(
                      children: [
                        IconButton(
                          onPressed: _loginWithBiometric,
                          icon: const Icon(Icons.fingerprint, size: 40),
                          tooltip: 'Use biometrics',
                        ),
                        const Text('Use biometrics to unlock'),
                      ],
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
