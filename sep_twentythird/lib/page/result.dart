// === result.dart ===
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String top1;   // 模型第一名分類結果
  final String report; // LLM 生成的敘述

  const ResultPage({
    super.key,
    required this.top1,
    required this.report,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 病灶分析結果"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ================================
            // 🔥 顯示第一名分類結果
            // ================================
            Text(
              "主要分類結果：",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),

            Text(
              top1,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 24),

            // ================================
            // 🔥 LLM 報告
            // ================================
            Text(
              "綜合分析報告：",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  report,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white,
                        height: 1.4,
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
