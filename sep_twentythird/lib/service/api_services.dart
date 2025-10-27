import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../page/result.dart';


Future<void> uploadImageAndSurvey(
    String imagePath, Map<String, dynamic> surveyData, BuildContext context) async {
  try {
    // 第一步：上傳圖片給模型，取得初步分類
    final uri1 = Uri.parse("http://120.125.78.132:5000/analyze");
    final request1 = http.MultipartRequest("POST", uri1);
    request1.files.add(await http.MultipartFile.fromPath('image', imagePath));
    final response1 = await request1.send();
    final responseBody1 = await response1.stream.bytesToString();

    if (response1.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("圖片辨識失敗，請稍後再試。")),
      );
      return;
    }

    final result1 = jsonDecode(responseBody1);
    final String modelSummary = result1['prediction']?['summary'] ?? '';
    final List<dynamic> top3 = result1['prediction']?['top3'] ?? [];

    if (top3.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("未收到模型預測結果，請確認圖片是否清晰。")),
      );
      return;
    }


    // 第二步：組合 prompt，送進 LLM
    final uri2 = Uri.parse("http://120.125.78.132:11434/api/generate");
    final prompt = _buildPrompt(modelSummary, top3, surveyData);

    final response2 = await http.post(
  uri2,
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode({
    "model": "phi4",
    "temperature": 0.7,
    "stream": false,
    "prompt": prompt  // ✅ 正確格式
  }),
);


    if (response2.statusCode == 200) {
      final responseJson = jsonDecode(response2.body);
      final llmText = responseJson['response'] ?? '無診斷建議';
      debugPrint("診斷文字：$llmText"); // ← 建議加上這行確認內容

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultPage(
            disease: top3.first['label'] ?? '未知疾病',
            confidence: top3.first['confidence'] ?? 0.0,
            description: llmText,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("語言模型分析失敗，請稍後再試。")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("發生錯誤: $e")),
    );
  }
}

String _buildPrompt(String summary, List<dynamic> top3, Map<String, dynamic> survey) {
  final buffer = StringBuffer();

  buffer.writeln("你是一位皮膚科醫師助手。模型預測結果為：");
  for (int i = 0; i < top3.length; i++) {
    final label = top3[i]['label'] ?? '未知';
    final confidence = ((top3[i]['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
    buffer.writeln("${i + 1}. $label（$confidence%）");
  }

  buffer.writeln("\n使用者症狀：");
  buffer.writeln("- 紅腫程度: ${survey['rednessSeverity']}");
  buffer.writeln("- 是否脫屑: ${survey['hasScaling'] ? "是" : "否"}");
  buffer.writeln("- 是否癢感: ${survey['hasItching'] ? "是" : "否"}");
  if (survey['hasItching']) {
    buffer.writeln("- 癢感補充: ${survey['itchingNote']}");
  }
  buffer.writeln("- 是否有滲液: ${survey['hasFluid'] ? "是" : "否"}");
  buffer.writeln("- 發作頻率: ${survey['recurrence']}");
  buffer.writeln("- 病灶部位: ${survey['lesionLocation']}");
  buffer.writeln("- 已持續時間: ${survey['duration']}");
  buffer.writeln("- 曾使用藥膏: ${survey['usedMedication'] ? "是" : "否"}");
  if (survey['usedMedication']) {
    buffer.writeln("- 藥膏描述: ${survey['medicationNote']}");
  }
  buffer.writeln("- 其他補充: ${survey['note']}");

  buffer.writeln("\n請根據上述內容：");
  buffer.writeln("1. 推測最可能的診斷（可列兩項以上）");
  buffer.writeln("2. 解釋可能原因與差異");
  buffer.writeln("3. 提出後續建議（如是否應就醫）");
  buffer.writeln("4. 提供簡易居家照護方法，以及本地的推薦用藥");
  //buffer.writeln("5. 請務必知悉，模型辨識出的結果僅為外觀相似，並非代表一定為該疾病，須結合患者自述推斷可能的疾病。");
  buffer.writeln("請務必根據使用者填寫的症狀描述為**主要判斷依據**，僅在無法判斷時參考模型外觀辨識結果。");
  //buffer.writeln("請用繁體中文作答，且每個疾病名稱請附上對應的中文翻譯（例如：Actinic Keratosis（日光性角化症）），如無對應中文則保留原文，並且輸出刪除多餘贅詞符號。");
  buffer.writeln("若模型預測結果與症狀不符，請明確指出原因並修正診斷順序。");
  buffer.writeln("所有內容皆需以繁體中文呈現，疾病名稱請附中文翻譯（例如：Actinic Keratosis（日光性角化症））。");

  return buffer.toString();
}

