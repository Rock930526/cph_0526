import 'package:flutter/material.dart';

class UserPage extends StatelessWidget {
  const UserPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('使用者')),
      body: const Center(
        child: Text(
          '使用者資訊 / 登出（佔位）',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
