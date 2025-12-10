import 'package:flutter/material.dart';
import 'theme/app_theme.dart';
import 'page/ImagePicker_Page.dart';   // ← 保留你的檔名，不改！！

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI skin scanner',
      theme: appTheme,
      home: const HomeWithLogo(),
    );
  }
}

class HomeWithLogo extends StatelessWidget {
  const HomeWithLogo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.face_retouching_natural, size: 32, color: Colors.cyanAccent),
            const SizedBox(width: 12),
            const Text('skin scanner'),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      // 🟦 這裡一定要用 class 名稱，不是檔名
      body: const ImagePickerPage(),
    );
  }
}
