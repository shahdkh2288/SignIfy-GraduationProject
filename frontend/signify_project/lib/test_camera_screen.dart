import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

class CameraTestScreen extends StatefulWidget {
  @override
  _CameraTestScreenState createState() => _CameraTestScreenState();
}

class _CameraTestScreenState extends State<CameraTestScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  String _status = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras!.isEmpty) {
        setState(() => _status = "No cameras found");
        return;
      }

      setState(() => _status = "Found ${_cameras!.length} camera(s)");

      final frontCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(frontCamera, ResolutionPreset.medium);
      await _controller!.initialize();

      if (mounted) {
        setState(() => _status = "Camera ready!");
      }
    } catch (e) {
      setState(() => _status = "Error: $e");
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
      appBar: AppBar(title: Text('Camera Test')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(_status, style: TextStyle(fontSize: 16)),
          ),
          if (_controller != null && _controller!.value.isInitialized)
            Expanded(child: CameraPreview(_controller!))
          else
            Expanded(child: Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }
}
