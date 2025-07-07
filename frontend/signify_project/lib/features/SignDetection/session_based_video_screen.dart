import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import 'package:signify_project/services/sign_detection_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

// Providers for session-based recording
final cameraControllerProvider = StateProvider<CameraController?>(
  (ref) => null,
);
final isRecordingProvider = StateProvider<bool>((ref) => false);
final detectedWordsProvider = StateProvider<List<String>>((ref) => []);
final sessionSignsProvider = StateProvider<List<Map<String, dynamic>>>(
  (ref) => [],
);
final isProcessingProvider = StateProvider<bool>((ref) => false);
final currentSessionProvider = StateProvider<String?>((ref) => null);
final sequenceNumberProvider = StateProvider<int>((ref) => 1);
final completeSentenceProvider = StateProvider<String>((ref) => '');

class SessionBasedVideoScreen extends ConsumerStatefulWidget {
  const SessionBasedVideoScreen({super.key});

  @override
  ConsumerState<SessionBasedVideoScreen> createState() =>
      _SessionBasedVideoScreenState();
}

class _SessionBasedVideoScreenState
    extends ConsumerState<SessionBasedVideoScreen>
    with WidgetsBindingObserver {
  List<CameraDescription>? cameras;
  bool _isCameraInitialized = false;
  final SignDetectionService _signDetectionService = SignDetectionService();
  bool _flipCamera = false;
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _audioPlayer = AudioPlayer();
    _initializeCamera();

    // Delay session initialization to avoid modifying providers during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startNewSession();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeCamera();
    _audioPlayer.dispose();
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

  void _startNewSession() {
    final sessionId = _signDetectionService.generateSessionId();
    ref.read(currentSessionProvider.notifier).state = sessionId;
    ref.read(sequenceNumberProvider.notifier).state = 1;
    ref.read(detectedWordsProvider.notifier).state = [];
    ref.read(completeSentenceProvider.notifier).state = '';
    print('Started new session: $sessionId');
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
        // Use addPostFrameCallback to avoid modifying provider during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(cameraControllerProvider.notifier).state = controller;
          setState(() {
            _isCameraInitialized = true;
          });
        });
      }
    } catch (e) {
      print('Camera initialization error: $e');
      _showErrorSnackBar('Failed to initialize camera: $e');
    }
  }

  void _disposeCamera() {
    final controller = ref.read(cameraControllerProvider);
    if (controller != null) {
      controller.dispose();
      // Use addPostFrameCallback to safely update provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(cameraControllerProvider.notifier).state = null;
          setState(() {
            _isCameraInitialized = false;
          });
        }
      });
    }
  }

  Future<void> _startRecording() async {
    final controller = ref.read(cameraControllerProvider);

    if (controller == null || !controller.value.isInitialized) {
      _showErrorSnackBar('Camera not initialized');
      return;
    }

    try {
      if (controller.value.isRecordingVideo) {
        return;
      }

      // Show countdown dialog first
      await _showCountdownDialog();

      // After countdown, start actual recording
      await controller.startVideoRecording();
      Future.delayed(Duration.zero, () {
        ref.read(isRecordingProvider.notifier).state = true;
      });

      _showRecordingDialog();
    } catch (e) {
      print('Start recording error: $e');
      _showErrorSnackBar('Failed to start recording: $e');
    }
  }

  Future<void> _stopRecording({bool isFinal = false}) async {
    final controller = ref.read(cameraControllerProvider);
    if (controller == null || !controller.value.isRecordingVideo) {
      return;
    }

    try {
      final videoFile = await controller.stopVideoRecording();
      Future.delayed(Duration.zero, () {
        ref.read(isRecordingProvider.notifier).state = false;
      });

      // Close recording dialog
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }

      await _processVideoWithSession(videoFile, isFinal: isFinal);
    } catch (e) {
      print('Stop recording error: $e');
      Future.delayed(Duration.zero, () {
        ref.read(isRecordingProvider.notifier).state = false;
      });
      _showErrorSnackBar('Failed to stop recording: $e');
    }
  }

  Future<void> _processVideoWithSession(
    XFile videoFile, {
    bool isFinal = false,
  }) async {
    try {
      Future.delayed(Duration.zero, () {
        ref.read(isProcessingProvider.notifier).state = true;
      });

      final sessionId = ref.read(currentSessionProvider);
      final sequenceNumber = ref.read(sequenceNumberProvider);

      if (sessionId == null) {
        throw Exception('No active session');
      }

      final videoBytes = await videoFile.readAsBytes();
      final result = await _signDetectionService.detectVideoSigns(
        videoBytes,
        sessionId: sessionId,
        sequenceNumber: sequenceNumber,
        isFinal: isFinal,
        flipCamera: _flipCamera,
      );

      if (result != null) {
        print('=== SESSION PROCESSING RESULT ===');
        print('Session ID: $sessionId');
        print('Sequence Number: $sequenceNumber');
        print('Is Final: $isFinal');
        print('Result: $result');
        print('=== END SESSION PROCESSING ===');

        // Check if we got a valid word (even if it's 'unknown' or 'sign_detected')
        final detectedWord = result['word'];
        if (detectedWord != null && detectedWord != 'error') {
          // Use Future.delayed to avoid modifying provider during build
          Future.delayed(Duration.zero, () {
            final currentWords = ref.read(detectedWordsProvider);
            final newWords = <String>[...currentWords, detectedWord];
            ref.read(detectedWordsProvider.notifier).state = newWords;

            // Show quick feedback - even for 'unknown' or 'sign_detected'
            if (detectedWord == 'unknown') {
              _showQuickFeedback('Sign detected (unrecognized)');
            } else if (detectedWord == 'sign_detected') {
              _showQuickFeedback('Sign detected');
            } else {
              _showQuickFeedback(detectedWord);
            }

            // Increment sequence number for next recording
            ref.read(sequenceNumberProvider.notifier).state =
                sequenceNumber + 1;
          });
        } else {
          // Handle case where we got an error or no word
          print('No valid word detected: $detectedWord');
          _showErrorSnackBar('Could not recognize sign in this video');
        }

        // Handle complete response (final sentence)
        if (result['complete_sentence'] != null) {
          Future.delayed(Duration.zero, () {
            final gptSentence =
                result['gpt_sentence'] ?? result['complete_sentence'];
            final rawSentence =
                result['raw_sentence'] ?? result['complete_sentence'];
            final words = result['words'] ?? [];

            ref.read(completeSentenceProvider.notifier).state = gptSentence;
            _showCompleteSentenceDialog(gptSentence, rawSentence, words);
          });
        }
      } else {
        print('API returned null result');
        _showErrorSnackBar('No response from sign detection service');
      }
    } catch (e) {
      print('Video processing error: $e');
      _showErrorSnackBar('Failed to process video: $e');
    } finally {
      Future.delayed(Duration.zero, () {
        ref.read(isProcessingProvider.notifier).state = false;
      });
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
          (context) => Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(
                bottom: 120,
              ), // Position lower so user can see themselves
              width:
                  MediaQuery.of(context).size.width *
                  0.85, // Make dialog smaller
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF005FCE)),
                      const SizedBox(height: 12),
                      const Text(
                        'Recording Sign...',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Consumer(
                        builder: (context, ref, child) {
                          final sequenceNumber = ref.watch(
                            sequenceNumberProvider,
                          );
                          return Text(
                            'Sign #$sequenceNumber',
                            style: const TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () => _stopRecording(isFinal: false),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, // Changed to red
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Stop',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'LeagueSpartan',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => _stopRecording(isFinal: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Finish',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'LeagueSpartan',
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
    );
  }

  void _showQuickFeedback(String word) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Detected: $word',
          style: const TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Color(0xFF005FCE),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showCompleteSentenceDialog(
    String gptSentence,
    String rawSentence,
    List<dynamic> words,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text(
              'Complete Sentence',
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
                const Text(
                  'Enhanced Sentence:',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  gptSentence,
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Detected Words:',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rawSentence,
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Individual words: ${words.join(', ')}',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  // Remove last word without closing dialog
                  await _removeLastWordFromSession();
                },
                child: const Text(
                  'Undo Last Word',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              TextButton(
                onPressed: () async {
                  // Regenerate sentence with current words
                  Navigator.of(context).pop();
                  await _regenerateSentence();
                },
                child: const Text(
                  'Regenerate Sentence',
                  style: TextStyle(color: Colors.orange),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  // Use Future.delayed to safely update providers after dialog closes
                  Future.delayed(Duration(milliseconds: 100), () {
                    _startNewSession(); // Start a new session for next sentence
                  });
                },
                child: const Text(
                  'Start New Sentence',
                  style: TextStyle(color: Color(0xFF005FCE)),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text(
                  'Continue Session',
                  style: TextStyle(color: Color(0xFF005FCE)),
                ),
              ),
            ],
          ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _clearCurrentSession() async {
    final sessionId = ref.read(currentSessionProvider);
    if (sessionId != null) {
      await _signDetectionService.clearSession(sessionId);
    }
    // Use Future.delayed to safely update providers
    Future.delayed(Duration.zero, () {
      _startNewSession();
    });
  }

  Future<void> _regenerateSentence() async {
    final sessionId = ref.read(currentSessionProvider);
    if (sessionId == null) {
      _showErrorSnackBar('No active session');
      return;
    }

    try {
      // Call backend to regenerate sentence
      final result = await _signDetectionService.regenerateSentence(sessionId);

      if (result != null && result['complete_sentence'] != null) {
        final gptSentence =
            result['gpt_sentence'] ?? result['complete_sentence'];
        final rawSentence =
            result['raw_sentence'] ?? result['complete_sentence'];
        final resultWords = result['words'] ?? [];

        // Show the updated completion dialog
        _showCompleteSentenceDialog(gptSentence, rawSentence, resultWords);
      } else {
        _showErrorSnackBar('Failed to regenerate sentence');
      }
    } catch (e) {
      print('Error regenerating sentence: $e');
      _showErrorSnackBar('Error regenerating sentence: $e');
    }
  }

  Future<void> _removeLastWordFromSession() async {
    final sessionId = ref.read(currentSessionProvider);
    if (sessionId == null) {
      _showErrorSnackBar('No active session');
      return;
    }

    try {
      final result = await _signDetectionService.removeLastWordFromSession(
        sessionId,
      );

      if (result != null) {
        print('Last word removed successfully: $result');

        // Update the detected words list
        final words = result['words'] as List<dynamic>? ?? [];
        final wordStrings = words.map((w) => w.toString()).toList();

        Future.delayed(Duration.zero, () {
          ref.read(detectedWordsProvider.notifier).state = wordStrings;

          // Decrement sequence number so user can re-record the same sign
          final currentSequence = ref.read(sequenceNumberProvider);
          if (currentSequence > 1) {
            final newSequence = currentSequence - 1;
            ref.read(sequenceNumberProvider.notifier).state = newSequence;

            // Show feedback with the removed word and sequence info
            final removedWord = result['removed_word'] ?? 'word';
            _showQuickFeedback(
              'Removed: $removedWord. Record sign #$newSequence again',
            );
          } else {
            // Show feedback with just the removed word
            final removedWord = result['removed_word'] ?? 'word';
            _showQuickFeedback('Removed: $removedWord');
          }
        });
      } else {
        _showErrorSnackBar('Failed to remove last word');
      }
    } catch (e) {
      print('Error removing last word: $e');
      _showErrorSnackBar('Error removing last word: $e');
    }
  }

  Future<void> _showCountdownDialog() async {
    // Show countdown dialog for 3 seconds
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const CountdownDialog(),
    );
  }

  Future<void> _playTextToSpeech(String text) async {
    try {
      final audioBytes = await _signDetectionService.textToSpeech(text);
      if (audioBytes != null) {
        // Save audio to temporary file
        final tempDir = await getTemporaryDirectory();
        final audioFile = File('${tempDir.path}/tts_audio.mp3');
        await audioFile.writeAsBytes(audioBytes);

        // Play the audio
        await _audioPlayer.play(DeviceFileSource(audioFile.path));

        _showQuickFeedback('Playing audio...');
      } else {
        _showErrorSnackBar('Failed to generate speech');
      }
    } catch (e) {
      print('Error playing text-to-speech: $e');
      _showErrorSnackBar('Error playing speech: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRecording = ref.watch(isRecordingProvider);
    final isProcessing = ref.watch(isProcessingProvider);
    final detectedWords = ref.watch(detectedWordsProvider);
    final completeSentence = ref.watch(completeSentenceProvider);
    final sequenceNumber = ref.watch(sequenceNumberProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Sign Recording',
          style: TextStyle(
            fontFamily: 'LeagueSpartan',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF005FCE),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _clearCurrentSession,
            tooltip: 'Clear Session',
          ),
          IconButton(
            icon: Icon(
              _flipCamera ? Icons.flip_camera_ios : Icons.flip_camera_android,
            ),
            onPressed: () {
              setState(() {
                _flipCamera = !_flipCamera;
              });
            },
            tooltip: 'Toggle Camera Flip',
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera Preview - Fixed structure to prevent shifting
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              child:
                  _isCameraInitialized
                      ? Stack(
                        children: [
                          // Camera preview - positioned to fill the entire container
                          Positioned.fill(
                            child: ClipRect(
                              child: Consumer(
                                builder: (context, ref, child) {
                                  final controller = ref.watch(
                                    cameraControllerProvider,
                                  );
                                  return controller != null
                                      ? CameraPreview(controller)
                                      : const Center(
                                        child: CircularProgressIndicator(
                                          color: Color(0xFF005FCE),
                                        ),
                                      );
                                },
                              ),
                            ),
                          ),
                          // Recording indicator overlay - positioned independently
                          Consumer(
                            builder: (context, ref, child) {
                              final isRecording = ref.watch(
                                isRecordingProvider,
                              );
                              final sequenceNumber = ref.watch(
                                sequenceNumberProvider,
                              );

                              if (!isRecording) return const SizedBox.shrink();

                              return Positioned(
                                top: 20,
                                left: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'REC #$sequenceNumber',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontFamily: 'LeagueSpartan',
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      )
                      : const Center(
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

          // Status Panel
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Session Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Next Sign: #$sequenceNumber',
                      style: const TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF005FCE),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _flipCamera ? Colors.orange : Colors.grey,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _flipCamera ? 'Flip ON' : 'Flip OFF',
                        style: const TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Detected Words
                Text(
                  'Detected Words:',
                  style: const TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                if (detectedWords.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Tap × on last word to undo',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 11,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child:
                      detectedWords.isEmpty
                          ? Text(
                            'No words detected yet',
                            style: const TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          )
                          : Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children:
                                detectedWords.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final word = entry.value;

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFF005FCE).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: Color(
                                          0xFF005FCE,
                                        ).withOpacity(0.3),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            left: 12,
                                            top: 6,
                                            bottom: 6,
                                          ),
                                          child: Text(
                                            word,
                                            style: const TextStyle(
                                              fontFamily: 'LeagueSpartan',
                                              fontSize: 14,
                                              color: Color(0xFF005FCE),
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        // Only show remove button for the last word
                                        if (index == detectedWords.length - 1)
                                          InkWell(
                                            onTap:
                                                () =>
                                                    _removeLastWordFromSession(),
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: Padding(
                                              padding: const EdgeInsets.all(4),
                                              child: Icon(
                                                Icons.close,
                                                size: 16,
                                                color: Colors.red[600],
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                          ),
                ),

                if (completeSentence.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Complete Sentence:',
                    style: const TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            completeSentence,
                            style: const TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 18,
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: () => _playTextToSpeech(completeSentence),
                          icon: const Icon(
                            Icons.volume_up,
                            color: Colors.green,
                            size: 24,
                          ),
                          tooltip: 'Play Audio',
                          constraints: const BoxConstraints(
                            minWidth: 40,
                            minHeight: 40,
                          ),
                          padding: const EdgeInsets.all(4),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Undo Last Word Button (only show if there are words)
                if (detectedWords.isNotEmpty)
                  Center(
                    child: SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed:
                            (isRecording || isProcessing)
                                ? null
                                : _removeLastWordFromSession,
                        icon: const Icon(Icons.undo, size: 18),
                        label: Text(
                          'Undo Last Word (${detectedWords.last})',
                          style: const TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (detectedWords.isNotEmpty) const SizedBox(height: 12),

                // Recording Button
                Center(
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed:
                          (isRecording || isProcessing)
                              ? null
                              : _startRecording,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isRecording
                                ? Colors.red
                                : (isProcessing
                                    ? Colors.grey
                                    : Color(0xFF005FCE)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child:
                          isProcessing
                              ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text(
                                    'Processing...',
                                    style: TextStyle(
                                      fontFamily: 'LeagueSpartan',
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              )
                              : Text(
                                isRecording
                                    ? 'Recording Sign #$sequenceNumber'
                                    : 'Record Sign #$sequenceNumber',
                                style: const TextStyle(
                                  fontFamily: 'LeagueSpartan',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
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

class CountdownDialog extends StatelessWidget {
  const CountdownDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Get Ready!',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Recording will start in:',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          CountdownTimer(),
          const SizedBox(height: 24),
          const Text(
            'Stay still and sign!',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class CountdownTimer extends StatefulWidget {
  const CountdownTimer({Key? key}) : super(key: key);

  @override
  _CountdownTimerState createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  int _start = 3;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    Future.delayed(const Duration(seconds: 1), () {
      if (_start > 1) {
        setState(() {
          _start--;
        });
        _startCountdown();
      } else {
        Navigator.of(context).pop(); // Close the dialog after countdown
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black54,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$_start',
            style: const TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'seconds',
            style: TextStyle(
              fontFamily: 'LeagueSpartan',
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}
