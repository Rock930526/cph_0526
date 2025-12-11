import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../page/result.dart';
import '../widget/loading_overlay.dart';

Future<void> uploadImageOnly(String imagePath, BuildContext context) async {
  print("👉 呼叫 uploadImageOnly 開始");

  LoadingOverlay.show(context);

  final uri = Uri.parse("http://120.125.78.132:5000/predict_combined");

  try {
    final request = http.MultipartRequest("POST", uri);
    request.files.add(await http.MultipartFile.fromPath('image', imagePath));

    final streamed = await request.send();
    final responseBody = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      LoadingOverlay.hide(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("後端錯誤: ${streamed.statusCode}")),
      );
      return;
    }

    final result = jsonDecode(responseBody);
    final top1 = result["top1"] ?? "無資料";
    final report = result["report"] ?? "（無 LLM 回覆）";

    LoadingOverlay.hide(context);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(top1: top1, report: report),
      ),
    );

  } catch (e) {
    LoadingOverlay.hide(context);
    print("❌ ERROR: $e");
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("錯誤: $e")),
    );
  }
}
