import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

import '../service/user_profile.dart';
import '../service/user_profile_dao.dart';
import '../service/llm_talk_dao.dart';

class LlmPage extends StatefulWidget {
  const LlmPage({super.key});

  @override
  State<LlmPage> createState() => _LlmPageState();
}

class _LlmPageState extends State<LlmPage> {
  final TextEditingController _controller = TextEditingController();
  final List<_ChatMessage> _messages = [];

  final _profileDao = UserProfileDao();
  final _talkDao = LlmTalkDao();

  UserProfile? _profile;
  late final String _uid;

  bool _isLoading = false;
  bool _initLoading = true;

  // =========================
  // init：載入使用者資料 + 歷史對話
  // =========================
  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _uid = user.uid;
    _profile = await _profileDao.getProfileByUid(_uid);

    final history = await _talkDao.getTalkHistory(_uid);

    for (final row in history) {
      _messages.add(_ChatMessage(row['user_input'], true));
      _messages.add(_ChatMessage(row['model_output'], false));
    }

    setState(() => _initLoading = false);
  }

  // =========================
  // Prompt（含個資）
  // =========================
  String _buildPrompt(String userInput) {
    final buffer = StringBuffer();

    buffer.writeln('你是一位皮膚科醫師助手。');

    if (_profile != null) {
      buffer.writeln('\n【使用者背景資料】');

      if (_profile!.gender != null) {
        buffer.writeln('性別：${_profile!.gender}');
      }
      if (_profile!.birthday != null) {
        buffer.writeln('生日：${_profile!.birthday}');
      }
      if (_profile!.heightCm != null && _profile!.weightKg != null) {
        buffer.writeln(
          '身高體重：${_profile!.heightCm} cm / ${_profile!.weightKg} kg',
        );
      }
      if (_profile!.chronicConditions != null &&
          _profile!.chronicConditions!.isNotEmpty) {
        buffer.writeln('慢性疾病：${_profile!.chronicConditions}');
      }
    }

    buffer.writeln('\n【使用者問題】');
    buffer.writeln(userInput);
    buffer.writeln('\n請以繁體中文回覆，並提醒此為輔助建議，非最終醫療判斷。');

    return buffer.toString();
  }

  // =========================
  // 發送訊息
  // =========================
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text, true));
      _isLoading = true;
      _controller.clear();
    });

    String answer;

    try {
      final response = await http.post(
        Uri.parse('http://120.125.78.132:5000/ask_llm'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "model": "deepseek-r1:14b",
          "prompt": _buildPrompt(text),
          "temperature": 0.7,
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        answer = data["answer"] ?? "（無回覆）";
      } else {
        answer = "⚠️ 伺服器錯誤 (${response.statusCode})";
      }
    } catch (_) {
      answer = "❌ 無法連線到 LLM 伺服器";
    }

    setState(() {
      _messages.add(_ChatMessage(answer, false));
      _isLoading = false;
    });

    // 寫入 SQLite
    await _talkDao.insertTalk(
      uid: _uid,
      userInput: text,
      modelOutput: answer,
    );
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    if (_initLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }
}
