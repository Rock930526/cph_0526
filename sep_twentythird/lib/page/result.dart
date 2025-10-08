import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String disease;       // 皮膚病名稱
  final double confidence;    // 信心度
  final String description;   // Ollama 產生的描述

  const ResultPage({
    super.key,
    required this.disease,
    required this.confidence,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("辨識結果"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 疾病名稱
            Text(
              "疾病類型：$disease",
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // 信心度
            Text(
              "信心度：${(confidence * 100).toStringAsFixed(1)}%",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 20),

            // Ollama 敘述
            Text(
              "模型說明：",
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

            // 返回首頁按鈕
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.cyanAccent,
                  foregroundColor: Colors.black,
                ),
                onPressed: () {
                  Navigator.pop(context); // 回上一頁（相機或預覽）
                },
                child: const Text("返回"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
