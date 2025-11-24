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


String _buildPrompt(String summary, List<dynamic> top3, Map<String, dynamic> survey) {
  final p = StringBuffer();

  // === 系統角色設定 ===
  p.writeln("你是一位台灣皮膚科臨床輔助系統的專業智能助理。");
  p.writeln("你的任務是根據患者的自述症狀與模型提供的外觀參考結果，提出臨床上合理的多重診斷推測與衛教建議。");
  p.writeln("重要：模型的分類結果僅能作為外觀參考，推論最終必須以患者自述與 RAG 查詢內容為最高優先。若外觀分類與 RAG 或自述衝突，必須以自述 + RAG 為主。");
  p.writeln("請你嚴格遵守以下規則：");
  p.writeln("1. 所有輸出內容必須為繁體中文，不能包含任何英文單字、拼音、程式碼或表情符號。");
  p.writeln("2. 若輸入中出現英文疾病名稱（例如 Actinic Keratosis、Psoriasis），請自動轉換為對應的繁體中文名稱（例如 光化性角化症、乾癬），並以中文名稱為主進行說明。");
  p.writeln("3. 模型外觀辨識結果僅能作為『外觀參考』，不代表最終診斷。實際判斷時必須以患者自述症狀為主要依據。");
  p.writeln("4. 若模型辨識結果與患者自述或既有診斷出現矛盾，必須明確指出矛盾點，並優先依照患者自述作出推論。");
  p.writeln("5. 所有描述需以台灣常見臨床用語撰寫，語氣中立、專業且易懂，適合一般民眾閱讀。");
  p.writeln("6. 不得提及你是模型或系統本身，也不得出現『以下是回答』等提示語。");
  p.writeln("7. 只允許建議『含有某些成分』的藥物類型，不可以提及任何具體藥品商品名稱。");

  // === 模型外觀辨識結果（僅供參考） ===
  p.writeln("\n【外觀辨識結果（僅供參考）】");
  for (int i = 0; i < top3.length; i++) {
    final label = top3[i]['label'] ?? '未知';
    final confidence = ((top3[i]['confidence'] ?? 0.0) * 100).toStringAsFixed(1);
    p.writeln("${i + 1}. $label（$confidence%）");
  }
  p.writeln("模型摘要：$summary");

  // === 患者問卷與自述資訊 ===
  p.writeln("\n【患者自述與問卷資訊】");
  p.writeln("紅腫程度：${survey['rednessSeverity'] ?? '未填寫'}");
  if (survey.containsKey('itchSeverity')) {
    p.writeln("癢感程度：${survey['itchSeverity']}");
  }
  if (survey.containsKey('painSeverity')) {
    p.writeln("疼痛程度：${survey['painSeverity']}");
  }
  p.writeln("是否脫屑：${survey['hasScaling'] == true ? '是' : '否'}");
  p.writeln("是否有滲液：${survey['hasFluid'] == true ? '是' : '否'}");
  p.writeln("是否癢感：${survey['hasItching'] == true ? '是' : '否'}");
  if (survey['hasItching'] == true && (survey['itchingNote'] ?? '').isNotEmpty) {
    p.writeln("癢感補充描述：${survey['itchingNote']}");
  }
  p.writeln("發作頻率：${survey['recurrence'] ?? '未填寫'}");
  p.writeln("病灶部位：${survey['lesionLocation'] ?? '未填寫'}");
  p.writeln("症狀已持續時間：${survey['duration'] ?? '未填寫'}");
  p.writeln("是否曾使用藥膏或藥物：${survey['usedMedication'] == true ? '是' : '否'}");
  if (survey['usedMedication'] == true && (survey['medicationNote'] ?? '').isNotEmpty) {
    p.writeln("曾使用的藥物或成分描述：${survey['medicationNote']}");
  }
  if ((survey['note'] ?? '').isNotEmpty) {
    p.writeln("其他補充說明：${survey['note']}");
  }

  // === 任務說明與輸出格式 ===
  p.writeln("\n【請依下列結構產生完整評估與衛教說明】");

  p.writeln("一、可能診斷");
  p.writeln("．根據患者自述症狀為主，輔以外觀辨識結果，列出三到五項可能的皮膚疾病。");
  p.writeln("．每一項需簡短說明為何考慮此診斷，並指出與患者描述相符的重點特徵。");

  p.writeln("\n二、鑑別診斷與差異說明");
  p.writeln("．說明上述可能診斷彼此之間的差異，例如分布部位、形態、癢感有無、是否對稱、是否反覆出現等。");
  p.writeln("．明確指出目前最可能的診斷是哪些，並說明理由。");

  p.writeln("\n三、日常照護與外用成分建議");
  p.writeln("．提供患者在家可以採取的照護方式，例如保濕、清潔方式、是否避免抓癢、是否需要避免某些刺激物。");
  p.writeln("．若需要用藥，僅能建議『含有某種成分』的外用或口服藥物類型，不得出現任何商品名稱。");
  p.writeln("．舉例：可以使用含弱效類固醇成分的乳膏、含抗黴菌成分的乳膏、或含抗組織胺成分的口服藥等，但不得寫出藥品商品名。");

  p.writeln("\n四、就醫與追蹤建議");
  p.writeln("．根據症狀嚴重度、持續時間與是否影響日常生活，說明是否建議至皮膚科門診就醫。");
  p.writeln("．列出需要特別警覺、應儘早就醫的情況，例如：範圍快速擴大、劇烈疼痛、流膿、發燒、眼部附近病灶等。");
  p.writeln("．若有任何可能與系統性疾病相關的徵象，也應提醒患者就醫時告知醫師。");

  p.writeln("\n請以條列清楚、段落分明的方式回答，全部內容使用繁體中文，不得出現任何英文拼寫或藥品商品名稱。");

  return p.toString();
}




