// === result.dart ===
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String disease;
  final double confidence;
  final String description;

  const ResultPage({
    super.key,
    required this.disease,
    required this.confidence,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("辨識結果")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "疾病類型：$disease",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              "信心度：${(confidence * 100).toStringAsFixed(1)}%",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 20),
            Text(
              "模型僅供外觀參考摘要：",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.cyanAccent,
                  ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                      ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () => Navigator.pop(context),
                child: const Text("返回"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


