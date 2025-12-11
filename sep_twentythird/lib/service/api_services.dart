// === api_services.dart ===
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../page/result.dart';

Future<void> uploadImageOnly(String imagePath, BuildContext context) async {
  print("👉 呼叫 uploadImageOnly 開始");

  final url = "http://120.125.78.132:5000/predict_combined";
  final uri = Uri.parse(url);

  try {
    print("👉 建立 MultipartRequest...");
    final request = http.MultipartRequest("POST", uri);

    request.files.add(await http.MultipartFile.fromPath('image', imagePath));
    print("👉 圖片加入成功");

    print("👉 正在送出 request（無 timeout）...");
    final response = await request.send();       // ❌ 不再 timeout！
    print("👉 request 已送出，等待後端回應…");

    // ❗ 這裡也不設 timeout，等待後端完整回應
    final responseBody = await response.stream.bytesToString();
    print("👉 後端回應完成");

    print("=====🔥 RAW RESPONSE =====");
    print(responseBody);

    if (response.statusCode != 200) {
      print("❌ 後端回應非 200: ${response.statusCode}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("後端錯誤: ${response.statusCode}")),
      );
      return;
    }

    final result = jsonDecode(responseBody);

    final top1 = result["top1"] ?? "無資料";
    final report = result["report"] ?? "（無 LLM 回覆）";

    print("👉 解 JSON 成功，準備跳轉頁面");

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(top1: top1, report: report),
      ),
    );

  } catch (e) {
    print("❌ 發生錯誤: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("錯誤: $e")),
    );
  }
}
