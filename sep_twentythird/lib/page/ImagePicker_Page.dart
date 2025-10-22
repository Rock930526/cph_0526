import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // 新增
import 'package:permission_handler/permission_handler.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _image;
  static const platform = MethodChannel('com.example.save_image'); // 新增

  Future<void> _pickImage(ImageSource source) async {
    // 新增：請求權限
    await Permission.storage.request();
    await Permission.photos.request();

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      // 原生存相簿
      await _saveImageToGallery(pickedFile.path);
    }
  }

  Future<void> _saveImageToGallery(String path) async {
    try {
      await platform.invokeMethod('saveImage', {'path': path});
    } catch (e) {
      debugPrint('儲存失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('選取或拍照')),
      body: Center(
        child: _image == null
            ? const Text('尚未選取圖片')
            : Image.file(_image!),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'camera',
            child: const Icon(Icons.camera_alt),
            onPressed: () => _pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'gallery',
            child: const Icon(Icons.photo),
            onPressed: () => _pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
