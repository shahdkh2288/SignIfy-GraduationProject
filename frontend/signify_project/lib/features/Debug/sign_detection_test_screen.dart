import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../../services/sign_detection_service.dart';
import '../../config/network_config.dart';

class SignDetectionTestScreen extends StatefulWidget {
  const SignDetectionTestScreen({super.key});

  @override
  State<SignDetectionTestScreen> createState() =>
      _SignDetectionTestScreenState();
}

class _SignDetectionTestScreenState extends State<SignDetectionTestScreen> {
  final SignDetectionService _signService = SignDetectionService();
  String _testResults = 'Ready to test sign detection';
  bool _isLoading = false;

  Future<void> _testSignDetectionWithDummyVideo() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Creating dummy video for sign detection test...\n';
    });

    try {
      // Create a simple dummy video file (simulated)
      // In real app, this would be actual video bytes
      final Uint8List dummyVideoBytes = Uint8List.fromList([
        // Minimal MP4 header simulation - this is just for testing
        0x00, 0x00, 0x00, 0x20, 0x66, 0x74, 0x79, 0x70, // ftyp box
        0x69, 0x73, 0x6F, 0x6D, 0x00, 0x00, 0x02, 0x00, // isom brand
        0x69, 0x73, 0x6F, 0x6D, 0x69, 0x73, 0x6F, 0x32, // compatibility
        0x61, 0x76, 0x63, 0x31, 0x6D, 0x70, 0x34, 0x31, // brands
      ]);

      setState(() {
        _testResults +=
            'Dummy video created (${dummyVideoBytes.length} bytes)\\n';
        _testResults +=
            'Sending to ${NetworkConfig.baseUrl}/detect-video-signs\\n';
        _testResults += 'Testing with debug mode enabled...\\n\\n';
      });

      // Test the sign detection service
      final result = await _signService.detectVideoSigns(
        dummyVideoBytes,
        debug: true,
      );

      setState(() {
        if (result != null) {
          _testResults += '✅ SUCCESS! Backend responded:\\n';
          _testResults += 'Word: ${result['word']}\\n';
          _testResults += 'Confidence: ${result['confidence']}\\n';
          _testResults +=
              'Frames processed: ${result['frames_processed']}\\n\\n';

          if (result['debug_info'] != null) {
            final debugInfo = result['debug_info'] as List;
            _testResults +=
                '📊 Debug info received: ${debugInfo.length} frames\\n';

            if (debugInfo.isNotEmpty) {
              final firstFrame = debugInfo[0];
              _testResults +=
                  'First frame landmarks shape: ${firstFrame['landmarks_shape']}\\n';
              _testResults +=
                  'First frame landmarks mean: ${firstFrame['landmarks_mean']}\\n';
            }
          }

          if (result['sequence_shape'] != null) {
            _testResults += '\\n🔍 Sequence processing:\\n';
            _testResults += 'Original shape: ${result['sequence_shape']}\\n';
            _testResults += 'Padded shape: ${result['padded_shape']}\\n';
            _testResults +=
                'Model input shape: ${result['model_input_shape']}\\n';
          }

          _testResults += '\\n✅ Sign detection is working correctly!';
        } else {
          _testResults += '❌ FAILED: No response from backend\\n';
          _testResults += '\\n🔧 Possible issues:\\n';
          _testResults += '• Backend server not running\\n';
          _testResults += '• Network connectivity problems\\n';
          _testResults += '• Wrong IP address configuration\\n';
          _testResults += '• Firewall blocking connections\\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '💥 ERROR: $e\\n';
        _testResults += '\\n🔧 This suggests:\\n';
        _testResults += '• Network connection failed\\n';
        _testResults += '• Backend server is not accessible\\n';
        _testResults += '• Check IP address: ${NetworkConfig.serverIP}\\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _testLandmarkDetection() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing landmark detection with dummy image...\\n';
    });

    try {
      // Create a simple dummy image (1x1 JPEG simulation)
      final Uint8List dummyImageBytes = Uint8List.fromList([
        0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46, // JPEG header
        0x49, 0x46, 0x00, 0x01, 0x01, 0x01, 0x00, 0x48,
        0x00, 0x48, 0x00, 0x00, 0xFF, 0xDB, 0x00, 0x43,
        0x00, 0xFF, 0xD9, // JPEG end
      ]);

      setState(() {
        _testResults +=
            'Dummy image created (${dummyImageBytes.length} bytes)\\n';
        _testResults += 'Testing landmark detection...\\n\\n';
      });

      final result = await _signService.detectLandmarks(dummyImageBytes);

      setState(() {
        if (result != null && result['landmarks'] != null) {
          final landmarks = result['landmarks'];
          _testResults += '✅ Landmark detection working!\\n';
          _testResults += 'Landmarks received: ${landmarks.length} points\\n';

          if (landmarks.isNotEmpty) {
            _testResults += 'First landmark: ${landmarks[0]}\\n';
          }
        } else {
          _testResults +=
              '⚠️ Landmark detection returned null or no landmarks\\n';
          _testResults += 'This is expected with dummy data\\n';
        }
      });
    } catch (e) {
      setState(() {
        _testResults += '❌ Landmark detection failed: $e\\n';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sign Detection Test',
          style: TextStyle(fontFamily: 'LeagueSpartan'),
        ),
        backgroundColor: const Color(0xFF005FCE),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign Detection Testing',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This will test the sign detection service with dummy data to verify connectivity and processing.',
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _testLandmarkDetection,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Test Landmarks'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading
                                    ? null
                                    : _testSignDetectionWithDummyVideo,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF005FCE),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Test Video Signs'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'Test Results',
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Spacer(),
                          if (_isLoading)
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
