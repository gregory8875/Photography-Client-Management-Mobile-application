import 'package:flutter/material.dart';

/// Small shared dialog helpers used across the app.
/// Keeps wording, button order and destructive affordances consistent.

Future<bool> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
}) async {
  final nav = Navigator.of(context);
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(onPressed: () => nav.pop(false), child: Text(cancelLabel)),
        ElevatedButton(onPressed: () => nav.pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}
