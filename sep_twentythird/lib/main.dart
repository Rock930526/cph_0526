import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'page/ImagePickerPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI skin scanner', // ← app 名稱更改
      theme: appTheme,
      home: const HomeWithLogo(),
    );
  }
}

// 新增首頁，含 logo 與 ImagePickerPage
class HomeWithLogo extends StatelessWidget {
  const HomeWithLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 這裡用 Icon 作為 logo，若有圖片可改成 Image.asset(...)
            const Icon(Icons.face_retouching_natural, size: 32, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            const Text('skin scanner'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: const ImagePickerPage(),
    );
  }
}

