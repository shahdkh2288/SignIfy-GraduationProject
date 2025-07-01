import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:signify_project/services/sign_detection_service.dart';

// Provider for camera state management
final cameraControllerProvider = StateProvider<CameraController?>(
  (ref) => null,
);
final isRecordingProvider = StateProvider<bool>((ref) => false);
final detectionResultProvider = StateProvider<String?>((ref) => null);
final isProcessingProvider = StateProvider<bool>((ref) => false);

class VideoRecordingScreen extends ConsumerStatefulWidget {
  const VideoRecordingScreen({super.key});

  @override
  ConsumerState<VideoRecordingScreen> createState() =>
      _VideoRecordingScreenState();
}

class _VideoRecordingScreenState extends ConsumerState<VideoRecordingScreen>
    with WidgetsBindingObserver {
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  final SignDetectionService _signDetectionService = SignDetectionService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isInitialized) {
      return;
    }
    if (state == AppLifecycleState.inactive) {
      _disposeCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initializeCamera();
    }
  }

  Future<void> _initializeCamera() async {
    try {
      cameras = await availableCameras();
      if (cameras == null || cameras!.isEmpty) {
        _showErrorSnackBar('No cameras available');
        return;
      }

      // Use front camera for sign language detection
      final frontCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false, // We don't need audio for sign detection
      );

      await controller.initialize();

      if (mounted) {
        ref.read(cameraControllerProvider.notifier).state = controller;
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  void _disposeCamera() {
    final controller = ref.read(cameraControllerProvider);
    controller?.dispose();
    ref.read(cameraControllerProvider.notifier).state = null;
    setState(() {
      _isCameraInitialized = false;
    });
  }

  Future<void> _startRecording() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isInitialized) {
      _showErrorSnackBar('Camera not initialized');
      return;
    }

    try {
      if (controller.value.isRecordingVideo) {
        return; // Already recording
      }

      // Clear previous result
      ref.read(detectionResultProvider.notifier).state = null;

      await controller.startVideoRecording();
      ref.read(isRecordingProvider.notifier).state = true;

      // Show recording indicator
      _showRecordingDialog();
    } catch (e) {
      print('Start recording error: $e');
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording() async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isRecordingVideo) {
      return;
    }

    try {
      // Stop recording and get the video file
      final videoFile = await controller.stopVideoRecording();
      ref.read(isRecordingProvider.notifier).state = false;

      // Close recording dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      // Process the video for sign detection
      await _processVideoForSignDetection(videoFile);
    } catch (e) {
      print('Stop recording error: $e');
      ref.read(isRecordingProvider.notifier).state = false;
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _processVideoForSignDetection(XFile videoFile) async {
    try {
      ref.read(isProcessingProvider.notifier).state = true;

      // Show processing dialog
      _showProcessingDialog();

      // Read video file as bytes
      final videoBytes = await videoFile.readAsBytes();

      // Send to backend for processing
      final result = await _signDetectionService.detectVideoSigns(
        videoBytes,
        debug: true,
      );

      if (result != null && result['word'] != null) {
        ref.read(detectionResultProvider.notifier).state = result['word'];

        // Print debug information
        print('=== FLUTTER DEBUG INFO ===');
        print('Predicted word: ${result['word']}');
        print('Confidence: ${result['confidence']}');
        print('Frames processed: ${result['frames_processed']}');

        if (result['debug_info'] != null) {
          final debugInfo = result['debug_info'] as List;
          print('Debug frames count: ${debugInfo.length}');
          for (int i = 0; i < math.min(3, debugInfo.length); i++) {
            final frameDebug = debugInfo[i];
            print(
              'Frame ${frameDebug['frame_number']}: shape=${frameDebug['landmarks_shape']}, mean=${frameDebug['landmarks_mean']}',
            );
          }
        }

        if (result['sequence_shape'] != null) {
          print('Sequence shape: ${result['sequence_shape']}');
          print('Padded shape: ${result['padded_shape']}');
          print('Model input shape: ${result['model_input_shape']}');
        }
        print('=== END DEBUG INFO ===');

        // Close processing dialog
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Show result dialog
        _showResultDialog(result);
      } else {
        throw Exception('No sign detected or invalid response');
      }
    } catch (e) {
      print('Video processing error: $e');
      ref.read(detectionResultProvider.notifier).state = null;

      // Close processing dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      _showErrorSnackBar('Failed to process video: $e');
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;

      // Clean up the video file
      try {
        await File(videoFile.path).delete();
      } catch (e) {
        print('Failed to delete video file: $e');
      }
    }
  }

  void _showRecordingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(color: Color(0xFF005FCE)),
                const SizedBox(height: 16),
                const Text(
                  'Recording Sign Language...',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perform your sign clearly',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _stopRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text(
                    'Stop Recording',
                    style: TextStyle(fontFamily: 'LeagueSpartan'),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  void _showProcessingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => const AlertDialog(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF005FCE)),
                SizedBox(height: 16),
                Text(
                  'Processing Video...',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Analyzing your sign language',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 14),
                ),
              ],
            ),
          ),
    );
  }

  void _showResultDialog(Map<String, dynamic> result) {
    final word = result['word'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 0.0;
    final framesProcessed = result['frames_processed'] ?? 0;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Sign Detected!',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontWeight: FontWeight.bold,
                color: Color(0xFF005FCE),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.gesture, color: Color(0xFF005FCE)),
                    const SizedBox(width: 8),
                    Text(
                      'Word: $word',
                      style: const TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Confidence: ${(confidence * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Frames processed: $framesProcessed',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Copy result to main screen text input
                  Navigator.of(context).pop(word);
                },
                child: const Text(
                  'Use Word',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF005FCE),
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Close',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    color: Colors.grey,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(cameraControllerProvider);
    final isRecording = ref.watch(isRecordingProvider);
    final isProcessing = ref.watch(isProcessingProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Sign Language Detection',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Camera Preview
          if (_isCameraInitialized && controller != null)
            Positioned.fill(child: CameraPreview(controller))
          else
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Initializing Camera...',
                    style: TextStyle(
                      color: Colors.white,
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),

          // Instructions overlay
          if (_isCameraInitialized && !isRecording && !isProcessing)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.white, size: 32),
                    SizedBox(height: 8),
                    Text(
                      'Position your hands clearly in the camera view',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap the record button and perform your sign',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Recording indicator
          if (isRecording)
            Positioned(
              top: 50,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fiber_manual_record,
                      color: Colors.white,
                      size: 24,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'RECORDING',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Camera controls
          if (_isCameraInitialized)
            Positioned(
              bottom: 100,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Cancel button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),

                  // Record button
                  GestureDetector(
                    onTap:
                        _isCameraInitialized && !isProcessing
                            ? (isRecording ? _stopRecording : _startRecording)
                            : null,
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: isRecording ? Colors.red : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isRecording ? Colors.white : Colors.red,
                          width: 4,
                        ),
                      ),
                      child: Icon(
                        isRecording ? Icons.stop : Icons.videocam,
                        color: isRecording ? Colors.white : Colors.red,
                        size: 40,
                      ),
                    ),
                  ),

                  // Switch camera button (placeholder)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Switch camera implementation would go here
                        _showErrorSnackBar(
                          'Camera switching not implemented yet',
                        );
                      },
                      icon: const Icon(
                        Icons.flip_camera_ios,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
