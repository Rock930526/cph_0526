import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

Future<void> uploadImageAndSurvey(String imagePath, Map<String, dynamic> surveyData, BuildContext context) async {
  final uri = Uri.parse("http://你的伺服器位址/analyze");
  final request = http.MultipartRequest("POST", uri);

  request.files.add(await http.MultipartFile.fromPath('image', imagePath));
  request.fields['survey'] = jsonEncode(surveyData);

  final response = await request.send();
  final responseBody = await response.stream.bytesToString();

  if (response.statusCode == 200) {
    final result = jsonDecode(responseBody);
    // 你可以根據需要顯示分析結果或跳轉頁面
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("分析完成"),
        content: Text(result['summary'] ?? '無摘要'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("確定"))],
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("上傳失敗，請稍後再試。")),
    );
  }
}

}
