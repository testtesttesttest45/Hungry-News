import 'package:flutter/material.dart';

class PastNewsPage extends StatelessWidget {
  const PastNewsPage({super.key}); 

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Past news'),
      ),
      body: const Center(
        child: Text('Past news content goes here'),
      ),
    );
  }
}
