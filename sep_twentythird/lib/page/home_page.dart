import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'Camera.dart';
import 'preview.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("AI Skin Scanner"),
        centerTitle: true,
      ),

      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [

            const Icon(
              Icons.face_retouching_natural,
              size: 90,
              color: Colors.cyanAccent,
            ),

            const SizedBox(height: 20),

            const Text(
              "AI Skin Scanner",
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 40),

            // 📸 拍照分析
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.cyanAccent,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.camera_alt),
              label: const Text("拍照分析"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CameraPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 16),

            // 🖼️ 從相簿選擇
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.cyanAccent,
                side: const BorderSide(color: Colors.cyanAccent),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
              ),
              icon: const Icon(Icons.photo_library),
              label: const Text("從相簿選擇"),
              onPressed: () async {
                final picker = ImagePicker();
                final image =
                    await picker.pickImage(source: ImageSource.gallery);
                if (image == null) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PreviewPage(imagePath: image.path),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
