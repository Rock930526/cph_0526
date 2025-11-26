// === result.dart ===
import 'package:flutter/material.dart';

class ResultPage extends StatelessWidget {
  final String disease;       // ← 現在預期是 LLM 推論第一名
  final String description;   // ← LLM 給的完整建議內容

  const ResultPage({
    super.key,
    required this.disease,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 皮膚診斷結果"),
        backgroundColor: Colors.black,
      ),
      backgroundColor: Colors.black,
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================================
            // 🔥 顯示 LLM 推測第一名疾病
            // ================================
            Text(
              "最可能診斷：",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              disease,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),

            const SizedBox(height: 20),

            // ================================
            // 🔥 診斷詳解（LLM）
            // ================================
            Text(
              "綜合分析報告：",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.cyanAccent,
                  ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: SingleChildScrollView(
                child: Text(
                  description,
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
