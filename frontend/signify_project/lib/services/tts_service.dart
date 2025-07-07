import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';
import '../config/network_config.dart';

class TTSService {
  static const _baseUrl = NetworkConfig.baseUrl;
  static const _storage = FlutterSecureStorage();

  // Direct audio download method
  static Future<String?> getTtsAudioDirect(String text) async {
    final token = await _storage.read(key: 'access_token');
    final url = Uri.parse('$_baseUrl/tts');

    print('Sending direct TTS request to: $url');
    print('Text: $text');

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'text': text}),
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              print('TTS request timed out after 30 seconds');
              throw Exception('TTS request timed out');
            },
          );

      print('Direct TTS Response status: ${response.statusCode}');
      print(
        'Direct TTS Response content type: ${response.headers['content-type']}',
      );
      print('Direct TTS Response content length: ${response.contentLength}');

      if (response.statusCode == 200) {
        // Check if response is actually audio data
        final contentType = response.headers['content-type'];
        if (contentType == null || !contentType.contains('audio')) {
          print('Warning: Response content-type is not audio: $contentType');
          print('Response body: ${response.body}');
          return null;
        }

        // Check if we have audio data
        if (response.bodyBytes.isEmpty) {
          print('Error: Response body is empty');
          return null;
        }

        // Save the audio bytes to a temporary file
        final tempDir = await getTemporaryDirectory();
        final audioFile = File(
          '${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );

        await audioFile.writeAsBytes(response.bodyBytes);

        // Verify file was created and has content
        if (await audioFile.exists()) {
          final fileSize = await audioFile.length();
          print('Audio saved to: ${audioFile.path}, size: $fileSize bytes');

          if (fileSize > 0) {
            return audioFile.path;
          } else {
            print('Error: Audio file is empty');
            return null;
          }
        } else {
          print('Error: Failed to create audio file');
          return null;
        }
      } else {
        print('Direct TTS request failed with status: ${response.statusCode}');
        print('Error body: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Direct TTS request error: $e');
      return null;
    }
  }
}
