import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'preview.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  Future<void>? _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    availableCameras().then((cameras) {
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        _initializeControllerFuture = _controller!.initialize().catchError((e) {
          debugPrint("Camera init error: $e");
        });
        setState(() {});
      } else {
        debugPrint("No cameras available");
      }
    }).catchError((e) {
      debugPrint("Error getting cameras: $e");
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("AI Skin Scanner")),
      body: (_initializeControllerFuture != null)
          ? FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done && _controller != null) {
                  return CameraPreview(_controller!);
                } else if (snapshot.hasError) {
                  return Center(child: Text('相機初始化失敗'));
                } else {
                  return const Center(child: CircularProgressIndicator());
                }
              },
            )
          : const Center(child: Text('正在初始化相機...')),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.camera_alt, size: 30),
        onPressed: () async {
          if (_controller == null || _initializeControllerFuture == null) return;
          try {
            await _initializeControllerFuture;
            final image = await _controller!.takePicture();
            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PreviewPage(imagePath: image.path),
              ),
            );
          } catch (e) {
            debugPrint("Error: $e");
          }
        },
      ),
    );
  }
}
