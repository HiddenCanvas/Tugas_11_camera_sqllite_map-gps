import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  XFile? _imageFile;

  bool _isError = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() {});
        }
      } else {
        setState(() {
          _isError = true;
          _errorMessage = "Kamera fisik tidak terdeteksi pada perangkat ini.";
        });
      }
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = "Gagal menginisialisasi kamera: $e\n\nTips: Fitur kamera memerlukan emulator dengan kamera virtual aktif atau HP fisik asli.";
      });
    }
  }

  Future<void> _takePicture() async {
    if (_controller != null && _controller!.value.isInitialized) {
      final image = await _controller!.takePicture();
      setState(() {
        _imageFile = image;
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kamera'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: _isError
                ? Container(
                    color: Colors.grey.shade200,
                    padding: const EdgeInsets.all(24.0),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.videocam_off, color: Colors.grey, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            _errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.black54, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  )
                : (_controller != null && _controller!.value.isInitialized
                    ? CameraPreview(_controller!)
                    : const Center(child: CircularProgressIndicator())),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: _imageFile != null
                  ? Image.file(File(_imageFile!.path))
                  : const Text('Belum ada foto'),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isError ? null : _takePicture,
        backgroundColor: _isError ? Colors.grey : null,
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
