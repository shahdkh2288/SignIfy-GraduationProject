import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'package:signify_project/services/sign_detection_service.dart';

class SignDetectionScreen extends StatefulWidget {
  @override
  _SignDetectionScreenState createState() => _SignDetectionScreenState();
}

class _SignDetectionScreenState extends State<SignDetectionScreen> {
  CameraController? _controller;
  List<CameraDescription> cameras = [];
  bool _isProcessing = false;
  String _predictedWord = '';
  String _confidence = '';
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras.isNotEmpty) {
        _controller = CameraController(
          cameras[0],
          ResolutionPreset.medium,
          enableAudio: false,
        );
        await _controller!.initialize();

        if (mounted) {
          setState(() {
            _isInitialized = true;
          });

          // Start image stream for real-time detection
          _controller!.startImageStream(_processImage);
        }
      }
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  Future<void> _processImage(CameraImage image) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      // Convert CameraImage to JPEG bytes
      final bytes = await _convertCameraImage(image);
      if (bytes != null) {
        final signDetectionService = SignDetectionService();

        // Use the combined method for simplicity
        final predictedWord = await signDetectionService.detectSignFromFrame(
          bytes,
        );

        if (predictedWord != null && mounted) {
          setState(() {
            _predictedWord = predictedWord;
            _confidence = '1.00'; // Placeholder confidence
          });
        }
      }
    } catch (e) {
      print('Error processing image: $e');
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<int>?> _convertCameraImage(CameraImage image) async {
    try {
      // For simplicity, we'll convert YUV420 to RGB
      // This is a basic conversion - in production, you might want more sophisticated handling
      final int width = image.width;
      final int height = image.height;

      // Get Y plane (luminance)
      final Uint8List yPlane = image.planes[0].bytes;

      // Create a simple grayscale to RGB conversion for demo
      final img.Image grayscaleImage = img.Image(width: width, height: height);

      int pixelIndex = 0;
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          final int yValue = yPlane[pixelIndex];
          grayscaleImage.setPixelRgb(x, y, yValue, yValue, yValue);
          pixelIndex++;
        }
      }

      // Resize for better performance
      final resizedImage = img.copyResize(
        grayscaleImage,
        width: 640,
        height: 480,
      );

      // Convert to JPEG
      final jpegBytes = img.encodeJpg(resizedImage, quality: 80);
      return jpegBytes;
    } catch (e) {
      print('Error converting camera image: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Sign Language Detection',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF005FCE),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child:
                  _isInitialized && _controller != null
                      ? CameraPreview(_controller!)
                      : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(color: Color(0xFF005FCE)),
                            SizedBox(height: 16),
                            Text(
                              'Initializing Camera...',
                              style: TextStyle(
                                fontFamily: 'LeagueSpartan',
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Detected Sign',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _predictedWord.isNotEmpty
                        ? _predictedWord
                        : 'Show your hand to detect signs',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF005FCE),
                    ),
                  ),
                  SizedBox(height: 4),
                  if (_confidence.isNotEmpty)
                    Text(
                      'Confidence: $_confidence',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInfoChip(
                        'Real-time',
                        _isProcessing ? 'Processing...' : 'Ready',
                      ),
                      _buildInfoChip('Mode', 'Static Signs'),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFF005FCE), width: 1),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 10,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005FCE),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}
