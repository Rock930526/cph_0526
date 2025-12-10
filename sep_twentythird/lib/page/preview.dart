// preview.dart
import 'dart:io';
import 'package:flutter/material.dart';
import '../service/api_services.dart';  // 記得路徑對

class PreviewPage extends StatelessWidget {
  final String imagePath;

  const PreviewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("預覽照片")),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              width: double.infinity,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () async {
                  // 🔥 這裡一定會印出來，用來確認有按到
                  debugPrint("👉 按下送出分析，準備呼叫 uploadImageOnly");
                  await uploadImageOnly(imagePath, context);
                },
                child: const Text("送出分析"),
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
