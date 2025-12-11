import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../page/preview.dart';

class ImagePickerPage extends StatefulWidget {
  const ImagePickerPage({super.key});

  @override
  State<ImagePickerPage> createState() => _ImagePickerPageState();
}

class _ImagePickerPageState extends State<ImagePickerPage> {
  File? _image;

  Future<void> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile == null) return;

    setState(() {
      _image = File(pickedFile.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("選取或拍照")),
      body: Center(
        child: _image == null
            ? const Text("尚未選擇照片")
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.file(_image!),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    child: const Text("使用這張"),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              PreviewPage(imagePath: _image!.path),
                        ),
                      );
                    },
                  )
                ],
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'cam',
            child: const Icon(Icons.camera_alt),
            onPressed: () => pickImage(ImageSource.camera),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: 'gal',
            child: const Icon(Icons.photo),
            onPressed: () => pickImage(ImageSource.gallery),
          ),
        ],
      ),
    );
  }
}
  