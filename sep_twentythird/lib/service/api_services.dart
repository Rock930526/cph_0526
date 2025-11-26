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

    // === 第二步：組合 prompt，送進 LLM ===
    final uri2 = Uri.parse("http://120.125.78.132:11434/api/generate");
    final prompt = _buildPrompt(modelSummary, top3, surveyData);

    // 🧪 驗證用：看清楚實際送出的 prompt
    debugPrint("===== LLM PROMPT START =====");
    debugPrint(prompt);
    debugPrint("===== LLM PROMPT END =====");

    final response2 = await http.post(
      uri2,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "model": "llama3:8b",
        "temperature": 0.7,
        "stream": false,
        "prompt": prompt,
      }),
    );

    // 🧪 驗證用：印出 Ollama 原始回應
    debugPrint("===== LLM RAW RESPONSE STATUS: ${response2.statusCode} =====");
    debugPrint(response2.body);

    if (response2.statusCode == 200) {
      final responseJson = jsonDecode(response2.body);
      final llmText = responseJson['response'] ?? '無診斷建議';
      debugPrint("診斷文字：$llmText");

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
    debugPrint("❌ uploadImageAndSurvey error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("發生錯誤: $e")),
    );
  }
}


String _buildPrompt({
  required String summary,
  required List<dynamic> top3,
  required Map<String, dynamic> survey,
  required List<dynamic> ragResults,
}) {
  final p = StringBuffer();

  // =============================
  // 🧠 系統角色和診斷邏輯（最重要）
  // =============================
  p.writeln("你是一套台灣皮膚科臨床輔助系統。推論必須依以下順序進行：");
  p.writeln("1. 患者自述症狀與問卷內容（最高權重）");
  p.writeln("2. RAG 提供的皮膚科醫學內容（唯一可引用的醫療知識）");
  p.writeln("3. 影像模型分類結果（僅做弱參考，不能主導診斷）");
  p.writeln();
  p.writeln("請嚴格遵守以下規則：");
  p.writeln("．禁止使用你本身的醫學知識，只能引用我提供的 RAG 文字內容。");
  p.writeln("．若某疾病未出現在 RAG 中，你才能允許搜尋相關知識。");
  p.writeln("．若模型分類與患者症狀/RAG 矛盾，必須完全忽略模型結果。");
  p.writeln("．所有輸出內容必須為繁體中文，不得包含英文、拼音或藥品商品名。");
  p.writeln("．藥物只能建議『含有某些成分』，不得提商品名。");
  p.writeln("．語氣需中立、專業、易懂，勿加入 AI、模型、系統等字眼。");

  // =============================
  // 🔥 1. 患者自述與問卷（主要證據）
  // =============================
  p.writeln("\n=== 患者自述與問卷資訊（主要判斷依據） ===");
  p.writeln("紅腫程度：${survey['rednessSeverity'] ?? '未填寫'}");
  p.writeln("癢感程度：${survey['itchSeverity'] ?? '未填寫'}");
  p.writeln("疼痛程度：${survey['painSeverity'] ?? '未填寫'}");
  p.writeln("是否脫屑：${survey['hasScaling'] == true ? '是' : '否'}");
  p.writeln("是否有滲液：${survey['hasFluid'] == true ? '是' : '否'}");
  p.writeln("是否癢感：${survey['hasItching'] == true ? '是' : '否'}");
  if (survey['itchingNote'] != null && survey['itchingNote'].toString().isNotEmpty) {
    p.writeln("癢感補充描述：${survey['itchingNote']}");
  }
  p.writeln("發作頻率：${survey['recurrence'] ?? '未填寫'}");
  p.writeln("病灶部位：${survey['lesionLocation'] ?? '未填寫'}");
  p.writeln("症狀持續時間：${survey['duration'] ?? '未填寫'}");
  p.writeln("是否曾使用藥物：${survey['usedMedication'] == true ? '是' : '否'}");
  if (survey['medicationNote'] != null && survey['medicationNote'].toString().isNotEmpty) {
    p.writeln("曾使用的藥物成分描述：${survey['medicationNote']}");
  }
  if (survey['note'] != null && survey['note'].toString().isNotEmpty) {
    p.writeln("其他補充說明：${survey['note']}");
  }

  // =============================
  // 📚 2. RAG 結果（唯一能引用的醫學知識）
  // =============================
  p.writeln("\n=== RAG 醫學資料（你唯一能引用的醫學知識） ===");

  if (ragResults.isEmpty) {
    p.writeln("（未找到相關 RAG 資料，若不足以判斷請明確說明不確定性）");
  } else {
    for (int i = 0; i < ragResults.length; i++) {
      final item = ragResults[i];
      final title =
          item['name_zh'] ?? item['disease'] ?? item['title'] ?? "未命名疾病";
      final content =
          item['content'] ?? item['text'] ?? item['snippet'] ?? "（無內容）";

      p.writeln("【資料 ${i + 1}：$title】");
      p.writeln(content);
      p.writeln();
    }
  }

  // =============================
  // 🖼 3. 模型結果（只能弱參考）
  // =============================
  p.writeln("\n=== 影像外觀模型結果（僅供參考，可能不準） ===");
  for (int i = 0; i < top3.length; i++) {
    final label = top3[i]['label'] ?? '未知';
    final confidence =
        ((top3[i]['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
    p.writeln("${i + 1}. $label（$confidence%）");
  }
  p.writeln("模型摘要：$summary");
  p.writeln("提醒：若模型結果與症狀或 RAG 衝突，你必須忽略模型結果。");

  // =============================
  // 🏥 4. 指令：請根據「症狀 + RAG」輸出結果
  // =============================
  p.writeln("\n=== 請依以下結構輸出評估結果（全部使用繁體中文） ===");

  p.writeln("一、可能診斷");
  p.writeln("．根據患者症狀 + RAG 內容列出 3–5 項最可能疾病（不得使用 RAG 以外的疾病）。");
  p.writeln("．每項需說明符合症狀與 RAG 哪些特徵。");

  p.writeln("\n二、鑑別診斷");
  p.writeln("．比較可能疾病之間的差異，如分布、外觀、癢感、急性或慢性特徵。");
  p.writeln("．指出目前最可能是哪幾個。");

  p.writeln("\n三、居家照護與外用建議");
  p.writeln("．提供清潔、保濕、避免刺激的方式。");
  p.writeln("．若需用藥，只能描述『含有 xx 成分的外用藥物』，不得寫商品名。");

  p.writeln("\n四、就醫建議");
  p.writeln("．依症狀嚴重度說明是否需要就醫。");
  p.writeln("．列出需要警覺的情況，如快速惡化、滲液、嚴重疼痛、臉部病灶等。");

  return p.toString();
}





