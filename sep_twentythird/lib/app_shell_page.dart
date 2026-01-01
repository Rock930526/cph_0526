import 'package:flutter/material.dart';

import 'page/home_page.dart';
import 'page/map_page.dart';
import 'page/severity_calculator_page.dart';
import 'page/llm_page.dart';
import 'widget/camera_page.dart';
import 'page/user_page.dart';
import 'page/Camera.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),               // 0 首頁
    MapPage(),                // 1 就醫地圖
    SizedBox(),               // 2 相機（佔位）
    SeverityCalculatorPage(), // 3 計算
    LlmPage(),                // 4 衛教機器人
  ];

  void _onTap(int index) {
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CameraPage()),
      );
    } else {
      setState(() => _currentIndex = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],

      bottomNavigationBar: BottomAppBar(
        color: Colors.black,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home, '首頁', 0),
                _navItem(Icons.map, '就醫地圖', 1),
                _cameraItem(),
                _navItem(Icons.calculate, '計算', 3),
                _navItem(Icons.smart_toy, '衛教機器人', 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final selected = _currentIndex == index;
    final color = selected ? Colors.cyanAccent : Colors.white54;

    return InkWell(
      onTap: () => _onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _cameraItem() {
    return InkWell(
      onTap: () => _onTap(2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: const [
          CircleAvatar(
            radius: 26,
            backgroundColor: Colors.cyanAccent,
            child: Icon(Icons.camera_alt, color: Colors.black, size: 28),
          ),
          SizedBox(height: 4),
          Text('相機', style: TextStyle(color: Colors.cyanAccent, fontSize: 12)),
        ],
      ),
    );
  }
}
