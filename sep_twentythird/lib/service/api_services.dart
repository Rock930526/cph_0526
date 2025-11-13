import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../page/result.dart';


Future<void> uploadImageAndSurvey(
    String imagePath, Map<String, dynamic> surveyData, BuildContext context) async {
  try {
    // 第一步：上傳圖片給模型，取得初步分類
    final uri1 = Uri.parse("http://120.125.78.132:5000/predict_combined");
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
    final String modelSummary = result1['summary'] ?? '';
    final List<dynamic> top3 = result1['disease']?['top3'] ?? [];


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
    //"model": "phi4",
    "model": "llama3:8b",
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

  // === 系統角色設定 ===
  buffer.writeln("你是一位台灣皮膚科臨床輔助系統的專業智能助理。");
  buffer.writeln("你的任務是：根據患者的問卷自述與模型辨識結果，提出臨床上合理的多重診斷推測。");
  buffer.writeln("請你**絕對遵守以下規則**：");
  buffer.writeln("1️⃣ 所有輸出內容必須是繁體中文，不能包含任何英文單字、符號或翻譯。");
  buffer.writeln("2️⃣ 若輸入中包含英文疾病名稱（如 Actinic Keratosis、Psoriasis 等），請自動轉換成繁體中文（如『光化性角化症』、『乾癬』）。");
  buffer.writeln("3️⃣ 模型辨識結果僅供外觀參考，不代表最終診斷，請優先依照患者自述判斷。");
  buffer.writeln("4️⃣ 若模型結果與患者自述衝突，請明確說明衝突原因並以患者自述為主。");
  buffer.writeln("5️⃣ 所有建議需中立、臨床化且用語簡潔，內容應適合台灣地區使用。");
  buffer.writeln("6️⃣ 不得輸出英文、emoji、表情符號或代碼，需保持正式臨床敘述風格。");
  buffer.writeln("7️⃣ 若患者症狀明確，請主動列出所有可能的診斷（可超過模型預測範圍），並依照可能性排序。");
  buffer.writeln("8️⃣ 若有需要立即就醫的情況，請於結尾以『⚠️建議立即就醫』明確提示。");
  buffer.writeln("9️⃣ 不得出現任何提示語或模型內部描述（例如：我是AI、以下是回答等）。");
  buffer.writeln("10️⃣ 以台灣常見醫療用語撰寫。");

  // === 模型外觀辨識結果 ===
  buffer.writeln("\n--- 模型外觀辨識結果（僅供參考） ---");
  for (int i = 0; i < top3.length; i++) {
    final label = top3[i]['label'] ?? '未知';
    final confidence = ((top3[i]['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
    buffer.writeln("${i + 1}. $label（$confidence%）");
  }
  buffer.writeln("模型摘要：$summary");

  // === 患者問卷與自述資訊 ===
  buffer.writeln("\n--- 患者問卷與自述資訊 ---");
  buffer.writeln("- 紅腫程度: ${survey['rednessSeverity'] ?? '未填寫'}");
  buffer.writeln("- 是否脫屑: ${survey['hasScaling'] == true ? '是' : '否'}");
  buffer.writeln("- 是否癢感: ${survey['hasItching'] == true ? '是' : '否'}");
  if (survey['hasItching'] == true && (survey['itchingNote'] ?? '').isNotEmpty) {
    buffer.writeln("- 癢感補充: ${survey['itchingNote']}");
  }
  buffer.writeln("- 是否有滲液: ${survey['hasFluid'] == true ? '是' : '否'}");
  buffer.writeln("- 發作頻率: ${survey['recurrence'] ?? '未填寫'}");
  buffer.writeln("- 病灶部位: ${survey['lesionLocation'] ?? '未填寫'}");
  buffer.writeln("- 已持續時間: ${survey['duration'] ?? '未填寫'}");
  buffer.writeln("- 曾使用藥膏: ${survey['usedMedication'] == true ? '是' : '否'}");
  if (survey['usedMedication'] == true && (survey['medicationNote'] ?? '').isNotEmpty) {
    buffer.writeln("- 藥膏描述: ${survey['medicationNote']}");
  }
  if ((survey['note'] ?? '').isNotEmpty) {
    buffer.writeln("- 其他補充: ${survey['note']}");
  }

  // === 任務說明 ===
  buffer.writeln("\n--- 任務說明 ---");
  buffer.writeln("請根據上述資料，以繁體中文生成完整臨床回覆，必須包含以下結構：");
  buffer.writeln("【一、診斷推測】列出多個可能的疾病（最多五項），每項包含簡要原因與判斷依據。");
  buffer.writeln("【二、差異分析】說明這些疾病之間的差異，指出與患者自述最相符者。");
  buffer.writeln("【三、照護建議】提供居家照護方法、注意事項與可能用藥。");
  buffer.writeln("【四、就醫建議】明確說明是否應就醫及緊急程度。");
  buffer.writeln("若模型預測與患者症狀不符，請在開頭指出模型誤差的可能原因（例如光線、皮膚顏色、拍攝角度等）。");
  buffer.writeln("請務必確保內容完全以繁體中文撰寫，禁止包含任何英文或拼音。");
  buffer.writeln("回答須條理清晰、段落分明、格式整齊，適合直接呈現在行動裝置螢幕上。");

  return buffer.toString();
}

