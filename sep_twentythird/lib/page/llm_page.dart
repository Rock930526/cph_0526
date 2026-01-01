import 'package:flutter/material.dart';

class LlmPage extends StatelessWidget {
  const LlmPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Text(
          '衛教機器人 / LLM（開發中）',
          style: TextStyle(color: Colors.white70, fontSize: 18),
        ),
      ),
    );
  }
}
