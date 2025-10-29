// Shutterbook — Settings
// App-level settings such as password lock and theme preferences.
import 'package:flutter/material.dart';
import '../authentication/models/auth_model.dart';
import '../authentication/auth_setup.dart';
import '../theme_controller.dart';
import '../../widgets/section_card.dart';
import 'package:shutterbook/theme/ui_styles.dart';

class SettingsScreen extends StatefulWidget {
  final AuthModel authModel;

  const SettingsScreen({super.key, required this.authModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _usePassword = false;
  bool _useBiometric = false;
  bool _useDark = false;
  bool _showPasswordEditor = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  @override
  void initState() {
    super.initState();
    _load();
    ThemeController.instance.isDark.addListener(_themeListener);
  }

  void _themeListener() {
    if (!mounted) return;
    setState(() => _useDark = ThemeController.instance.isDark.value);
  }

  @override
  void dispose() {
    ThemeController.instance.isDark.removeListener(_themeListener);
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  final _pwFormKey = GlobalKey<FormState>();

  Future<void> _load() async {
    await widget.authModel.loadSettings();
    // ThemeController should be initialized in main(), but read current value here:
    setState(() {
      _usePassword = widget.authModel.hasPassword;
      _useBiometric = widget.authModel.biometricEnabled;
      _useDark = ThemeController.instance.isDark.value;
    });
  }

  // password change flow handled inline in the UI save handler

  Future<void> _togglePassword(bool value) async {
    if (!value) {
      // Capture navigator and messenger before awaiting operations so we
      // don't use BuildContext across async gaps (avoids use_build_context_synchronously).
      final navigator = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);

      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
            title: const Text('Disable password lock?'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('This will remove the password and disable biometrics.'),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Disable'),
              ),
            ],
          ),
      );

  if (ok != true) return;

  await widget.authModel.removePassword();
  await widget.authModel.setBiometricEnabled(false);

      if (!mounted) return;
      setState(() {
        _usePassword = false;
        _useBiometric = false;
      });

      // Ensure we don't leave sensitive screens on the stack. Pop to first route
      // (the app home) so the user is returned to a non-sensitive screen.
      navigator.popUntil((route) => route.isFirst);
      messenger.showSnackBar(const SnackBar(content: Text('Password disabled')));
    } else {
      // Replace settings with setup so the user cannot navigate back into
      // settings while the initial password setup is in progress.
      if (!mounted) return;
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SetupScreen(authModel: widget.authModel),
        ),
      );
    }
  }

  Future<void> _toggleBiometric(bool value) async {
    if (!widget.authModel.hasPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enable password lock first to use biometrics'),
        ),
      );
      return;
    }
    await widget.authModel.setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _useBiometric = value);
  }

  Future<void> _toggleDark(bool value) async {
    await ThemeController.instance.setDark(value);
    if (!mounted) return;
    setState(() => _useDark = value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: UIStyles.accentAppBar(context, const Text('Settings'), 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Enable Password Lock'),
              value: _usePassword,
              onChanged: _togglePassword,
            ),
            if (_usePassword) ...[
              SectionCard(
                child: _showPasswordEditor
                    ? Form(
                        key: _pwFormKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            TextFormField(
                              controller: _newPasswordController,
                              obscureText: !_showNewPassword,
                              decoration: InputDecoration(
                                labelText: 'New password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_showNewPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showNewPassword = !_showNewPassword),
                                ),
                              ),
                              validator: (v) {
                                final s = v ?? '';
                                if (s.trim().length < 4) return 'At least 4 characters';
                                return null;
                              },
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 8),
                            Builder(builder: (context) {
                              final pwd = _newPasswordController.text;
                              String strengthLabel = '';
                              Color strengthColor = Theme.of(context).colorScheme.primary;
                              if (pwd.isEmpty) {
                                strengthLabel = '';
                              } else if (pwd.length < 6) {
                                strengthLabel = 'Weak';
                                strengthColor = Theme.of(context).colorScheme.error;
                              } else if (RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(pwd)) {
                                strengthLabel = 'Strong';
                                strengthColor = Theme.of(context).colorScheme.primary;
                              } else {
                                strengthLabel = 'Okay';
                                strengthColor = Theme.of(context).colorScheme.secondary;
                              }
                              return strengthLabel.isEmpty
                                  ? const SizedBox.shrink()
                                  : Padding(
                                      padding: const EdgeInsets.only(bottom: 8.0),
                                      child: Text(
                                        'Strength: $strengthLabel',
                                        style: TextStyle(color: strengthColor, fontSize: 12),
                                      ),
                                    );
                            }),
                            TextFormField(
                              controller: _confirmPasswordController,
                              obscureText: !_showConfirmPassword,
                              decoration: InputDecoration(
                                labelText: 'Confirm password',
                                border: const OutlineInputBorder(),
                                suffixIcon: IconButton(
                                  icon: Icon(_showConfirmPassword ? Icons.visibility_off : Icons.visibility),
                                  onPressed: () => setState(() => _showConfirmPassword = !_showConfirmPassword),
                                ),
                              ),
                              validator: (v) {
                                if (v != _newPasswordController.text) return 'Passwords do not match';
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton(
                                    style: UIStyles.primaryButton(context),
                                    onPressed: () async {
                                      if (!(_pwFormKey.currentState?.validate() ?? false)) return;
                                      final messenger = ScaffoldMessenger.of(context);
                                      final newPw = _newPasswordController.text.trim();
                                      await widget.authModel.changePassword(newPw);
                                      _newPasswordController.clear();
                                      _confirmPasswordController.clear();
                                      if (!mounted) return;
                                      setState(() {
                                        _showPasswordEditor = false;
                                      });
                                      messenger.showSnackBar(const SnackBar(content: Text('Password changed')));
                                    },
                                    child: const Text('Save'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                OutlinedButton(
                                  onPressed: () {
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                    setState(() {
                                      _showPasswordEditor = false;
                                    });
                                  },
                                  child: const Text('Cancel'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          ElevatedButton(
                            style: UIStyles.primaryButton(context),
                            onPressed: () {
                              setState(() => _showPasswordEditor = true);
                            },
                            child: const Text('Change Password'),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Enable Biometrics'),
                value: _useBiometric,
                onChanged: _toggleBiometric,
              ),
            ],
            const SizedBox(height: 24),
            SwitchListTile(
              title: const Text('Dark Mode'),
              value: _useDark,
              onChanged: _toggleDark,
            ),
          ],
        ),
      ),
    );
  }
}
