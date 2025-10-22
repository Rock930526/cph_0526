import 'dart:io';
import 'package:flutter/material.dart';
import '../pages/questionnaire_page.dart';

class PreviewPage extends StatelessWidget {
  final String imagePath;
  const PreviewPage({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('預覽照片')),
      body: Column(
        children: [
          Expanded(
            child: Image.file(
              File(imagePath),
              fit: BoxFit.cover,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ElevatedButton.icon(
                  icon: const Icon(Icons.edit_note),
                  label: const Text("前往填寫症狀問卷"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => QuestionnairePage(imagePath: imagePath),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text("重新拍攝"),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}