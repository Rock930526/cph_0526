import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LlmPage extends StatefulWidget {
  const LlmPage({super.key});

  @override
  State<LlmPage> createState() => _LlmPageState();
}

class _LlmPageState extends State<LlmPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;

  /// ⭐ 封裝 prompt（之後你可以在這裡塞模型結果、問卷、病史）
  String _buildPrompt(String userInput) {
    return '''
你是一位皮膚科醫師助手。

使用者問題：
$userInput

請以繁體中文回覆，並提醒模型結果僅供輔助，非最終根據。
''';
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isLoading = true;
      _controller.clear();
    });

    final payload = {
      "model": "deepseek-r1:14b",
      "prompt": _buildPrompt(text),
      "temperature": 0.7,
      "stream": false,
    };

    try {
      final response = await http.post(
        Uri.parse('http://120.125.78.132:5000/ask_llm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data["answer"] ?? "（無回覆）";

        setState(() {
          _messages.add(_ChatMessage(answer, false));
        });
      } else {
        setState(() {
          _messages.add(
            _ChatMessage("⚠️ 伺服器錯誤 (${response.statusCode})", false),
          );
        });
      }
    } catch (e) {
      setState(() {
        _messages.add(_ChatMessage("❌ 無法連線到 LLM 伺服器", false));
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("衛教聊天機器人"),
        backgroundColor: Colors.black,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _messages.length,
              itemBuilder: (_, i) => _messages[i],
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      color: Colors.grey[900],
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "請輸入問題（例如：什麼是乾癬？）",
                hintStyle: TextStyle(color: Colors.white38),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.blueAccent),
            onPressed: _sendMessage,
          )
        ],
      ),
    );
  }
}

class _ChatMessage extends StatelessWidget {
  final String text;
  final bool isUser;

  const _ChatMessage(this.text, this.isUser);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        constraints: const BoxConstraints(maxWidth: 300),
        decoration: BoxDecoration(
          color: isUser ? Colors.blueAccent : Colors.grey[800],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
