import 'package:flutter/material.dart';

class ManageQuotePage extends StatelessWidget {
  const ManageQuotePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Quotes'),
      ),
      body: Center(
        child: Text('Manage your quotes here'),
      ),
    );
  }
}
