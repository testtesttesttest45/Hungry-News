import 'package:flutter/material.dart';

class PreferenceNewsPage extends StatelessWidget {
  const PreferenceNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preference'),
      ),
      body: const Center(
        child: Text('Preference content goes here'),
      ),
    );
  }
}
