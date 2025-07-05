import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../config/network_config.dart';

class SignDetectionService {
  static const String baseUrl = NetworkConfig.baseUrl;

  /// Detects signs from a video with session-based sequential recording support
  /// Supports both single-word and multi-word detection
  Future<Map<String, dynamic>?> detectVideoSigns(
    List<int> videoBytes, {
    String? sessionId,
    int? sequenceNumber,
    bool? isFinal,
    bool flipCamera = false,
  }) async {
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

      // Add optional parameters
      if (sessionId != null) {
        request.fields['session_id'] = sessionId;
      }
      if (sequenceNumber != null) {
        request.fields['sequence_number'] = sequenceNumber.toString();
      }
      if (isFinal != null) {
        request.fields['is_final'] = isFinal.toString();
      }
      if (flipCamera) {
        request.fields['flip_camera'] = 'true';
      }

      final response = await request.send();

      print('=== SIGN DETECTION API RESPONSE ===');
      print('Status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();

        try {
          final jsonResponse = jsonDecode(responseBody);
          print(
            'Response: word="${jsonResponse['word']}", confidence=${jsonResponse['confidence']}',
          );
          print('=== END API RESPONSE ===');
          return jsonResponse;
        } catch (jsonError) {
          print('JSON parsing error: $jsonError');
          print('=== END API RESPONSE ===');
          return null;
        }
      } else {
        print('Video sign detection failed: ${response.statusCode}');
        final responseBody = await response.stream.bytesToString();
        print('Error response: $responseBody');
        print('=== END API RESPONSE ===');
        return null;
      }
    } catch (e) {
      print('Error detecting video signs: $e');
      print('=== END API RESPONSE ===');
      return null;
    }
  }

  /// Get session information
  Future<Map<String, dynamic>?> getSessionInfo(String sessionId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/session-info/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Get session info failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error getting session info: $e');
      return null;
    }
  }

  /// Clear a session
  Future<bool> clearSession(String sessionId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/clear-session/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error clearing session: $e');
      return false;
    }
  }

  /// List all active sessions
  Future<Map<String, dynamic>?> listSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/list-sessions'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('List sessions failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error listing sessions: $e');
      return null;
    }
  }

  /// Remove the last word from a session
  Future<Map<String, dynamic>?> removeLastWordFromSession(
    String sessionId,
  ) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/remove-last-word-from-session/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Remove last word from session failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error removing last word from session: $e');
      return null;
    }
  }

  /// Regenerate sentence from current session words using GPT
  Future<Map<String, dynamic>?> regenerateSentence(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/regenerate-sentence/$sessionId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Regenerate sentence failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error regenerating sentence: $e');
      return null;
    }
  }

  /// Convert text to speech using the backend TTS service
  Future<List<int>?> textToSpeech(String text) async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');

      final response = await http.post(
        Uri.parse('$baseUrl/tts'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        print('Text-to-speech failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('Error in text-to-speech: $e');
      return null;
    }
  }

  /// Generate a unique session ID
  String generateSessionId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
