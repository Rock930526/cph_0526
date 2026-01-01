import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  /// =======================
  /// 使用者小選單（右上角）
  /// =======================
  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF2B2B2B),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 使用者資訊
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Colors.cyanAccent,
                  child: Icon(Icons.person, color: Colors.black),
                ),
                title: const Text(
                  'x幻月 凜空',
                  style: TextStyle(color: Colors.white),
                ),
                subtitle: const Text(
                  '@rock.chen12345613',
                  style: TextStyle(color: Colors.white54),
                ),
              ),

              const Divider(color: Colors.white24),

              _menuItem(Icons.auto_fix_high, '個人化', () {
                Navigator.pop(context);
              }),

              _menuItem(Icons.settings, '設定', () {
                Navigator.pop(context);
              }),

              _menuItem(Icons.info_outline, '說明', () {
                Navigator.pop(context);
              }),

              const Divider(color: Colors.white24),

              _menuItem(
                Icons.logout,
                '登出',
                () {
                  Navigator.pop(context);
                  // TODO: 之後接登出邏輯
                },
                color: Colors.redAccent,
              ),
            ],
          ),
        );
      },
    );
  }

  /// 單一選單項目
  static Widget _menuItem(
    IconData icon,
    String text,
    VoidCallback onTap, {
    Color color = Colors.white,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(text, style: TextStyle(color: color)),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text('AI Skin Scanner'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => _showUserMenu(context),
          ),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🔄 輪播區（placeholder）
              Container(
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Center(
                  child: Text(
                    '輪播區（衛教 / 教學）',
                    style: TextStyle(color: Colors.white54),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 📊 分數卡
              Row(
                children: [
                  _scoreCard('上一次乾癬分數', '--'),
                  const SizedBox(width: 12),
                  _scoreCard('上一次濕疹分數', '--'),
                ],
              ),

              const SizedBox(height: 16),

              // 🔍 辨識結果
              const Text(
                '上次辨識結果：尚無資料',
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _scoreCard(String title, String score) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white54)),
            const SizedBox(height: 8),
            Text(
              score,
              style: const TextStyle(
                color: Colors.cyanAccent,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
