import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../page/preview.dart'; // 確保你有這個檔案

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _selectedImage = File(picked.path));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("選擇相片")),
      body: Center(
        child: _selectedImage == null
            ? const Text("尚未選擇圖片")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_selectedImage!),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text("使用此圖片"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              PreviewPage(imagePath: _selectedImage!.path),
                        ),
                      );
                    },
                  )
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickImage,
        child: const Icon(Icons.photo_library),
      ),
    );
  }
}
