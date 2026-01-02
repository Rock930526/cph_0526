import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart';

import 'preview.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage>
    with WidgetsBindingObserver {
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _cameraIndex = 0;

  double _currentZoom = 1.0;
  double _baseZoom = 1.0;

  FlashMode _flashMode = FlashMode.off;

  static const MethodChannel _channel =
      MethodChannel('media_store');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_controller == null) return;
    if (state == AppLifecycleState.resumed) {
      _startCamera(_cameraIndex);
    }
  }

  Future<void> _initCamera() async {
    _cameras = await availableCameras();
    if (_cameras.isEmpty) return;
    await _startCamera(_cameraIndex);
  }

  Future<void> _startCamera(int index) async {
    _controller?.dispose();

    _controller = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await _controller!.initialize();
    await _controller!.setFlashMode(_flashMode);

    _currentZoom = await _controller!.getMinZoomLevel();
    setState(() {});
  }

  void _switchCamera() {
    if (_cameras.length < 2) return;
    _cameraIndex = (_cameraIndex + 1) % _cameras.length;
    _startCamera(_cameraIndex);
  }

  void _toggleFlash() async {
    if (_controller == null) return;

    setState(() {
      _flashMode =
          _flashMode == FlashMode.off ? FlashMode.torch : FlashMode.off;
    });

    await _controller!.setFlashMode(_flashMode);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewPage(imagePath: image.path),
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_controller == null) return;

    final image = await _controller!.takePicture();

    // 🔥 自動存進系統相簿（Android MediaStore）
    try {
      await _channel.invokeMethod(
        'saveImage',
        {'path': image.path},
      );
    } catch (e) {
      debugPrint('❌ 儲存相簿失敗: $e');
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewPage(imagePath: image.path),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('拍照分析'),
        actions: [
          IconButton(
            icon: Icon(
              _flashMode == FlashMode.off
                  ? Icons.flash_off
                  : Icons.flash_on,
            ),
            onPressed: _toggleFlash,
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: _switchCamera,
          ),
        ],
      ),
      body: _controller == null || !_controller!.value.isInitialized
    ? const Center(child: CircularProgressIndicator())
    : LayoutBuilder(
        builder: (context, constraints) {
          final previewSize = _controller!.value.previewSize!;
          final screenRatio =
              constraints.maxHeight / constraints.maxWidth;
          final previewRatio =
              previewSize.height / previewSize.width;

          return Center(
            child: ClipRect(
              child: OverflowBox(
                maxHeight: screenRatio > previewRatio
                    ? constraints.maxHeight
                    : constraints.maxWidth * previewRatio,
                maxWidth: screenRatio > previewRatio
                    ? constraints.maxHeight / previewRatio
                    : constraints.maxWidth,
                child: GestureDetector(
                  onScaleStart: (_) => _baseZoom = _currentZoom,
                  onScaleUpdate: (details) async {
                    final minZoom =
                        await _controller!.getMinZoomLevel();
                    final maxZoom =
                        await _controller!.getMaxZoomLevel();
                    _currentZoom =
                        (_baseZoom * details.scale)
                            .clamp(minZoom, maxZoom);
                    await _controller!.setZoomLevel(_currentZoom);
                  },
                  child: CameraPreview(_controller!),
                ),
              ),
            ),
          );
        },
      ),

      bottomNavigationBar: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.photo_library, color: Colors.white),
              iconSize: 32,
              onPressed: _pickFromGallery,
            ),
            FloatingActionButton(
              backgroundColor: Colors.cyanAccent,
              foregroundColor: Colors.black,
              onPressed: _takePicture,
              child: const Icon(Icons.camera_alt, size: 28),
            ),
            const SizedBox(width: 32),
          ],
        ),
      ),
    );
  }
}
