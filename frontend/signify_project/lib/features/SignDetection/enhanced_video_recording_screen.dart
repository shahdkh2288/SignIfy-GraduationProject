import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:signify_project/services/sign_detection_service.dart';

// Enhanced providers for multi-word detection
final cameraControllerProvider = StateProvider<CameraController?>(
  (ref) => null,
);
final isRecordingProvider = StateProvider<bool>((ref) => false);
final detectedWordsProvider = StateProvider<List<String>>((ref) => []);
final isProcessingProvider = StateProvider<bool>((ref) => false);
final recordingModeProvider = StateProvider<RecordingMode>(
  (ref) => RecordingMode.single,
);

enum RecordingMode { single, continuous }

class EnhancedVideoRecordingScreen extends ConsumerStatefulWidget {
  const EnhancedVideoRecordingScreen({super.key});

  @override
  ConsumerState<EnhancedVideoRecordingScreen> createState() =>
      _EnhancedVideoRecordingScreenState();
}

class _EnhancedVideoRecordingScreenState
    extends ConsumerState<EnhancedVideoRecordingScreen>
    with WidgetsBindingObserver {
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  final SignDetectionService _signDetectionService = SignDetectionService();
  List<XFile> _videoSegments = [];

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
    _cleanupVideoSegments();
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

      final frontCamera = cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras!.first,
      );

      final controller = CameraController(
        frontCamera,
        ResolutionPreset.medium,
        enableAudio: false,
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

  void _cleanupVideoSegments() {
    for (final segment in _videoSegments) {
      try {
        File(segment.path).deleteSync();
      } catch (e) {
        print('Failed to delete video segment: $e');
      }
    }
    _videoSegments.clear();
  }

  Future<void> _startRecording() async {
    final controller = ref.read(cameraControllerProvider);
    final mode = ref.read(recordingModeProvider);

    if (controller == null || !controller.value.isInitialized) {
      _showErrorSnackBar('Camera not initialized');
      return;
    }

    try {
      if (controller.value.isRecordingVideo) {
        return;
      }

      // Clear previous results
      ref.read(detectedWordsProvider.notifier).state = [];
      _cleanupVideoSegments();

      await controller.startVideoRecording();
      ref.read(isRecordingProvider.notifier).state = true;

      if (mode == RecordingMode.single) {
        _showSingleRecordingDialog();
      } else {
        _showContinuousRecordingDialog();
      }
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
      final videoFile = await controller.stopVideoRecording();
      ref.read(isRecordingProvider.notifier).state = false;

      // Close recording dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      final mode = ref.read(recordingModeProvider);
      if (mode == RecordingMode.single) {
        await _processSingleVideo(videoFile);
      } else {
        _videoSegments.add(videoFile);
        await _processVideoSegment(videoFile);
      }
    } catch (e) {
      print('Stop recording error: $e');
      ref.read(isRecordingProvider.notifier).state = false;
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _processSingleVideo(XFile videoFile) async {
    try {
      ref.read(isProcessingProvider.notifier).state = true;
      _showProcessingDialog();

      final videoBytes = await videoFile.readAsBytes();
      final result = await _signDetectionService.detectMultipleSigns(
        videoBytes,
      );

      if (result != null) {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }

        // Check if multiple signs were detected
        if (result['words'] != null && result['words'] is List) {
          final words = List<String>.from(result['words']);
          final sentence = result['sentence'] ?? words.join(' ');
          final segments = result['segments'] ?? [];

          ref.read(detectedWordsProvider.notifier).state = words;
          _showMultipleSignsDialog(words, sentence, segments);
        } else if (result['word'] != null) {
          // Fallback to single word detection
          final words = <String>[result['word']];
          ref.read(detectedWordsProvider.notifier).state = words;
          _showResultDialog(result, isFinal: true);
        } else {
          throw Exception('No signs detected');
        }
      } else {
        throw Exception('No signs detected');
      }
    } catch (e) {
      print('Video processing error: $e');
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      _showErrorSnackBar('Failed to process video: $e');
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
      try {
        await File(videoFile.path).delete();
      } catch (e) {
        print('Failed to delete video file: $e');
      }
    }
  }

  Future<void> _processVideoSegment(XFile videoFile) async {
    try {
      ref.read(isProcessingProvider.notifier).state = true;

      final videoBytes = await videoFile.readAsBytes();
      final result = await _signDetectionService.detectVideoSigns(videoBytes);

      if (result != null && result['word'] != null) {
        final currentWords = ref.read(detectedWordsProvider);
        final newWords = <String>[...currentWords, result['word']];
        ref.read(detectedWordsProvider.notifier).state = newWords;

        // Show quick feedback
        _showQuickFeedback(result['word']);
      }
    } catch (e) {
      print('Video segment processing error: $e');
    } finally {
      ref.read(isProcessingProvider.notifier).state = false;
    }
  }

  void _showSingleRecordingDialog() {
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
                  'Recording Sign...',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perform one clear sign',
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

  void _showContinuousRecordingDialog() {
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
                  'Recording Continuous Signs...',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Perform multiple signs in sequence',
                  style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 14),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: _recordNextSign,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF005FCE),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Next Sign',
                        style: TextStyle(fontFamily: 'LeagueSpartan'),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _finishContinuousRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text(
                        'Finish',
                        style: TextStyle(fontFamily: 'LeagueSpartan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _recordNextSign() async {
    await _stopRecording();
    // Small delay before starting next recording
    await Future.delayed(const Duration(milliseconds: 500));
    await _startRecording();
  }

  Future<void> _finishContinuousRecording() async {
    await _stopRecording();
    final words = ref.read(detectedWordsProvider);

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    _showFinalResultDialog(words);
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
              ],
            ),
          ),
    );
  }

  void _showQuickFeedback(String word) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detected: $word',
          style: const TextStyle(fontFamily: 'LeagueSpartan'),
        ),
        duration: const Duration(seconds: 1),
        backgroundColor: const Color(0xFF005FCE),
      ),
    );
  }

  void _showResultDialog(Map<String, dynamic> result, {bool isFinal = false}) {
    final word = result['word'] ?? 'Unknown';
    final confidence = result['confidence'] ?? 0.0;

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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
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

  void _showFinalResultDialog(List<String> words) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Multiple Signs Detected!',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontWeight: FontWeight.bold,
                color: Color(0xFF005FCE),
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  children: [
                    Icon(Icons.list, color: Color(0xFF005FCE)),
                    SizedBox(width: 8),
                    Text(
                      'Detected Words:',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    words.join(' '),
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Total words: ${words.length}',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(words.join(' '));
                },
                child: const Text(
                  'Use All Words',
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

  void _showMultipleSignsDialog(
    List<String> words,
    String sentence,
    List<dynamic> segments,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Multiple Signs Detected!',
              style: TextStyle(
                fontFamily: 'LeagueSpartan',
                fontWeight: FontWeight.bold,
                color: Color(0xFF005FCE),
              ),
            ),
            content: Container(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Complete sentence
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Complete Sentence:',
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sentence,
                          style: const TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF005FCE),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Individual words breakdown
                  const Text(
                    'Individual Signs:',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Scrollable list of detected signs
                  Container(
                    height: math.min(200, segments.length * 60.0),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: segments.length,
                      itemBuilder: (context, index) {
                        final segment = segments[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              // Sign number
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF005FCE),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(width: 12),

                              // Sign details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      segment['word'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontFamily: 'LeagueSpartan',
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Confidence: ${((segment['confidence'] ?? 0.0) * 100).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        fontFamily: 'LeagueSpartan',
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Summary
                  Text(
                    'Total: ${words.length} sign${words.length != 1 ? 's' : ''} detected',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop(sentence);
                },
                child: const Text(
                  'Use Sentence',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF005FCE),
                    fontWeight: FontWeight.bold,
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
    final recordingMode = ref.watch(recordingModeProvider);
    final detectedWords = ref.watch(detectedWordsProvider);

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
        actions: [
          // Mode toggle button
          IconButton(
            onPressed: () {
              final newMode =
                  recordingMode == RecordingMode.single
                      ? RecordingMode.continuous
                      : RecordingMode.single;
              ref.read(recordingModeProvider.notifier).state = newMode;
            },
            icon: Icon(
              recordingMode == RecordingMode.single
                  ? Icons.looks_one
                  : Icons.queue,
              color: Colors.white,
            ),
          ),
        ],
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

          // Mode indicator
          Positioned(
            top: 20,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF005FCE).withOpacity(0.8),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                recordingMode == RecordingMode.single
                    ? 'Single Word'
                    : 'Multiple Words',
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'LeagueSpartan',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          // Detected words display (for continuous mode)
          if (recordingMode == RecordingMode.continuous &&
              detectedWords.isNotEmpty)
            Positioned(
              top: 60,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detected Words:',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      detectedWords.join(' '),
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Instructions overlay
          if (_isCameraInitialized && !isRecording && !isProcessing)
            Positioned(
              bottom: 200,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Colors.white,
                      size: 32,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      recordingMode == RecordingMode.single
                          ? 'Single Word Mode'
                          : 'Smart Detection Mode',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      recordingMode == RecordingMode.single
                          ? 'Record one sign at a time'
                          : 'Record multiple signs with pauses between them',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontFamily: 'LeagueSpartan',
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Camera controls
          if (_isCameraInitialized)
            Positioned(
              bottom: 50,
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

                  // Mode toggle button
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: () {
                        final newMode =
                            recordingMode == RecordingMode.single
                                ? RecordingMode.continuous
                                : RecordingMode.single;
                        ref.read(recordingModeProvider.notifier).state =
                            newMode;
                      },
                      icon: Icon(
                        recordingMode == RecordingMode.single
                            ? Icons.looks_one
                            : Icons.queue,
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
