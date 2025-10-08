import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  final String baseUrl = "http://192.168.1.100:5000"; // TODO: 換成你的伺服器 IP

  Future<Map<String, dynamic>> uploadImage(String imagePath) async {
    var request = http.MultipartRequest("POST", Uri.parse("$baseUrl/predict"));
    request.files.add(await http.MultipartFile.fromPath("file", imagePath));

    var response = await request.send();
    if (response.statusCode == 200) {
      final body = await response.stream.bytesToString();
      return json.decode(body);
    } else {
      throw Exception("上傳失敗：${response.statusCode}");
    }
  }
}
