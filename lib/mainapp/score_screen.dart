import 'package:flutter/material.dart';

class ScoreScreen extends StatelessWidget {
  const ScoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Score')),
      body: const Center(
        child: Text('Score placeholder', style: TextStyle(fontSize: 16)),
      ),
    );
  }
}