// === api_services.dart ===

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../page/result.dart';

Future<void> uploadImageAndSurvey(
    String imagePath, Map<String, dynamic> surveyData, BuildContext context) async {
  try {
    // ============================================
    // 1️⃣ 上傳圖片 + 問卷 → 後端 Flask 伺服器
    // ============================================

    final uri1 = Uri.parse("http://120.125.78.132:5000/predict_combined");

    final request1 = http.MultipartRequest("POST", uri1);

    // 上傳圖片
    request1.files.add(await http.MultipartFile.fromPath('image', imagePath));

    // 問卷 JSON
    request1.fields['survey'] = jsonEncode(surveyData);

    // 送出請求
    final response1 = await request1.send();
    final responseBody1 = await response1.stream.bytesToString();

    if (response1.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("圖片或問卷分析失敗，請稍後再試。")),
      );
      return;
    }

    final result1 = jsonDecode(responseBody1);

    // ============================================
    // 2️⃣ 後端回傳欄位（新版）
    //  - final_top1: LLM 最終判斷出的主要疾病（字串）
    //  - final_text: LLM 產生的完整敘述（字串）
    //  - final_candidates: LLM 內部使用候選列表（前端不顯示）
    // ============================================

    final String llmTop1 = result1["final_top1"] ?? "無法判定";
    final String llmText = result1["final_text"] ?? "（無內容）";

    // ============================================
    // 3️⃣ 導向結果頁
    // ============================================

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          disease: llmTop1,
          description: llmText,
        ),
      ),
    );
  } catch (e) {
    debugPrint("❌ uploadImageAndSurvey error: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("發生錯誤: $e")),
    );
  }
}
