import 'package:flutter/material.dart';

class QuoteOverviewScreen extends StatelessWidget {
  const QuoteOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quote Overview')),
      body: const Center(child: Text('Overview of the selected quote packages')),
    );
  }
}