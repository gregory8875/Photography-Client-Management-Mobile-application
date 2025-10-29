// Shutterbook — password_field.dart
// Reusable password field with optional strength indicator and comparison
// support. Used on auth setup and login flows. Keep validation logic in the
// parent for reusability.
import 'package:flutter/material.dart';

typedef PasswordValidator = String? Function(String?);

class PasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final PasswordValidator? validator;
  final bool showStrength;
  final TextEditingController? compareWith;

  const PasswordField({
    super.key,
    required this.controller,
    required this.labelText,
    this.validator,
    this.showStrength = false,
    this.compareWith,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _visible = false;

  String _strengthLabel(String pwd) {
    if (pwd.isEmpty) return '';
    if (pwd.length < 6) return 'Weak';
    if (RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(pwd)) return 'Strong';
    return 'Okay';
  }

  double _strengthValue(String pwd) {
    if (pwd.isEmpty) return 0.0;
    if (pwd.length < 6) return 0.33;
    if (RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(pwd)) return 1.0;
    return 0.66;
  }

  Color _strengthColor(BuildContext context, String pwd) {
    final ThemeData t = Theme.of(context);
    if (pwd.isEmpty) return t.colorScheme.primary;
    if (pwd.length < 6) return t.colorScheme.error;
    if (RegExp(r'(?=.*[A-Z])(?=.*\d)').hasMatch(pwd)) return t.colorScheme.primary;
    return t.colorScheme.secondary;
  }

  @override
  Widget build(BuildContext context) {
    final pwd = widget.controller.text;
    final strength = _strengthValue(pwd);
    final label = _strengthLabel(pwd);
    final color = _strengthColor(context, pwd);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        TextFormField(
          controller: widget.controller,
          obscureText: !_visible,
          decoration: InputDecoration(
            labelText: widget.labelText,
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: Icon(_visible ? Icons.visibility_off : Icons.visibility),
              onPressed: () => setState(() => _visible = !_visible),
            ),
          ),
          validator: (v) {
            if (widget.compareWith != null) {
              if (v != widget.compareWith!.text) return 'Passwords do not match';
            }
            if (widget.validator != null) return widget.validator!(v);
            return null;
          },
          onChanged: (_) => setState(() {}),
        ),
        if (widget.showStrength) ...<Widget>[
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: strength,
            color: color,
            backgroundColor: color.withAlpha((0.18 * 255).round()),
          ),
          const SizedBox(height: 6),
          Align(alignment: Alignment.centerLeft, child: Text(label, style: TextStyle(color: color, fontSize: 12))),
        ],
      ],
    );
  }
}
