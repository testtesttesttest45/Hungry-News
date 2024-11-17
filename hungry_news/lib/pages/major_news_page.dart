import 'package:flutter/material.dart';

class MajorNewsPage extends StatelessWidget {
  const MajorNewsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Major news'),
      ),
      body: const Center(
        child: Text('Major news content goes here'),
      ),
    );
  }
}
