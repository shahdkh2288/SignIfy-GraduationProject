import 'dart:convert';
import 'package:http/http.dart' as http;

class SignDetectionService {
  static const String baseUrl = 'http://10.0.2.2:5000';

  /// Detects hand landmarks from a frame image
  /// Returns landmarks data or null if detection fails
  Future<Map<String, dynamic>?> detectLandmarks(List<int> frameBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-landmarks'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'frame',
          frameBytes,
          filename: 'frame.jpg',
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        print('Landmark detection failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error detecting landmarks: $e');
      return null;
    }
  }

  /// Predicts sign from hand landmarks
  /// Takes a list of 21 landmarks with x, y, z coordinates
  Future<Map<String, dynamic>?> detectSign(List<List<double>> landmarks) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/detect-sign'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'landmarks': landmarks}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Sign detection failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error detecting sign: $e');
      return null;
    }
  }

  /// Detects signs from a video sequence
  /// For dynamic signs that require temporal context
  Future<Map<String, dynamic>?> detectVideoSigns(List<int> videoBytes) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-video-signs'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          videoBytes,
          filename: 'video.mp4',
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        print('Video sign detection failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error detecting video signs: $e');
      return null;
    }
  }

  /// Combined method: detects landmarks and then predicts sign from a single frame
  /// Convenience method for real-time frame processing
  Future<String?> detectSignFromFrame(List<int> frameBytes) async {
    try {
      // First detect landmarks
      final landmarkResult = await detectLandmarks(frameBytes);
      if (landmarkResult == null || landmarkResult['landmarks'] == null) {
        return null;
      }

      // Convert landmarks to the expected format
      final landmarks = List<List<double>>.from(
        landmarkResult['landmarks'].map((lm) => List<double>.from(lm)),
      );

      // Then predict sign
      final signResult = await detectSign(landmarks);
      return signResult?['word'];
    } catch (e) {
      print('Error in combined sign detection: $e');
      return null;
    }
  }

  /// Detects multiple signs from a video sequence with automatic segmentation
  /// Returns a map with individual words, complete sentence, and segment details
  Future<Map<String, dynamic>?> detectMultipleSigns(
    List<int> videoBytes,
  ) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/detect-multiple-signs'),
      );
      request.files.add(
        http.MultipartFile.fromBytes(
          'video',
          videoBytes,
          filename: 'video.mp4',
        ),
      );

      final response = await request.send();
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        return jsonDecode(responseBody);
      } else {
        print('Multiple signs detection failed: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        print('Error response: $responseBody');
        return null;
      }
    } catch (e) {
      print('Error detecting multiple signs: $e');
      return null;
    }
  }
}
