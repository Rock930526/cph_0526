// api_services.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../page/result.dart';

Future<void> uploadImageOnly(
    String imagePath, BuildContext context) async {
  try {
    debugPrint("👉 按下送出分析，準備呼叫 uploadImageOnly");
    debugPrint("STEP 0 — 函式開始執行");
    debugPrint("STEP 0.1 — imagePath = $imagePath");

    // ✅ 先用你 Postman 測過可用的那個 IP
    final uri = Uri.parse("http://120.125.78.132:5000/predict_combined");
    debugPrint("STEP 1 — URI 準備好了: $uri");

    final request = http.MultipartRequest("POST", uri);
    debugPrint("STEP 2 — 建立 MultipartRequest 成功");

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    debugPrint("STEP 3 — 圖片加入成功");

    // 加一個 timeout，避免永遠卡住
    debugPrint("STEP 4 — 準備送出 request（等待中）");
    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw Exception("連線逾時（30 秒內沒有回應）");
      },
    );

    debugPrint("STEP 5 — 收到伺服器回應，status = ${streamedResponse.statusCode}");
    final responseBody = await streamedResponse.stream.bytesToString();

    debugPrint("===== RAW RESPONSE START =====");
    debugPrint(responseBody);
    debugPrint("===== RAW RESPONSE END =====");

    if (streamedResponse.statusCode != 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("影像分析失敗（${streamedResponse.statusCode}）")),
      );
      return;
    }

    final result = jsonDecode(responseBody);
    final String top1 = result["top1"] ?? "無資料";
    final String report = result["report"] ?? "（無 LLM 回覆）";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          top1: top1,
          report: report,
        ),
      ),
    );
  } catch (e, st) {
    debugPrint("❌ uploadImageOnly error: $e");
    debugPrint("STACK: $st");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("發生錯誤: $e")),
    );
  }
}
