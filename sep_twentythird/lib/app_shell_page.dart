// lib/app_shell_page.dart
import 'package:flutter/material.dart';
import 'page/home_page.dart';
import 'page/severity_calculator_page.dart';

class AppShellPage extends StatefulWidget {
  const AppShellPage({super.key});

  @override
  State<AppShellPage> createState() => _AppShellPageState();
}

class _AppShellPageState extends State<AppShellPage> {
  int _currentIndex = 0;

  final _pages = const [
    HomePage(),        // ✅ 首頁
    SeverityCalculatorPage(),     // PASI（之後）
    Placeholder(),     // 設定（之後）
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: Colors.black,
        selectedItemColor: Colors.cyanAccent,
        unselectedItemColor: Colors.white54,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: "首頁",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate),
            label: "特定疾病嚴重程度計算",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "設定",
          ),
        ],
      ),
    );
  }
}
