// Shutterbook — Auth setup
// Screen used on first launch to configure a password lock and initial
// authentication settings.
import 'package:flutter/material.dart';
import 'models/auth_model.dart';
import '../dashboard_home.dart';
import '../../widgets/section_card.dart';
import '../../widgets/password_field.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class SetupScreen extends StatefulWidget {
  final AuthModel authModel;

  const SetupScreen({super.key, required this.authModel});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _usePassword = true;
  bool _showPasswordEditor = true; // show editor by default on initial setup

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    // Capture messenger and navigator before any awaits to avoid use_build_context_synchronously
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_usePassword) {
      if (!(_formKey.currentState?.validate() ?? false)) {
        messenger.showSnackBar(const SnackBar(content: Text('Please set a valid password')));
        return;
      }

      await widget.authModel.setPassword(_passwordController.text.trim());

      final available = await widget.authModel.isBiometricAvailable();
      if (available) {
        await widget.authModel.setBiometricEnabled(true);
      } else {
        await widget.authModel.setBiometricEnabled(false);
        if (mounted) {
          messenger.showSnackBar(const SnackBar(content: Text('Biometric authentication not available on this device')));
        }
      }
    } else {
      await widget.authModel.removePassword();
      await widget.authModel.setBiometricEnabled(false);
    }

    if (!mounted) return;
    navigator.pushReplacement(MaterialPageRoute(builder: (_) => DashboardHome(authModel: widget.authModel)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Initial Setup'), 0),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SwitchListTile(
                  title: const Text('Enable Password Lock'),
                  value: _usePassword,
                  onChanged: (v) => setState(() => _usePassword = v),
                ),
                if (_usePassword) ...[
                  SectionCard(
                    child: _showPasswordEditor
                        ? Form(
                            key: _formKey,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                PasswordField(
                                  controller: _passwordController,
                                  labelText: 'Set a password',
                                  showStrength: true,
                                ),
                                const SizedBox(height: 12),
                                PasswordField(
                                  controller: _confirmController,
                                  labelText: 'Confirm password',
                                  compareWith: _passwordController,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        style: UIStyles.primaryButton(context),
                                        onPressed: _continue,
                                        child: const Text('Save & Continue'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    OutlinedButton(
                                      style: UIStyles.outlineButton(context),
                                      onPressed: () {
                                        _passwordController.clear();
                                        _confirmController.clear();
                                        setState(() => _showPasswordEditor = false);
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          )
                        : ElevatedButton(
                            style: UIStyles.primaryButton(context),
                            onPressed: () => setState(() => _showPasswordEditor = true),
                            child: const Text('Set Password'),
                          ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (!_usePassword)
                  ElevatedButton(
                    style: UIStyles.primaryButton(context),
                    onPressed: _continue,
                    child: const Text('Continue'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
