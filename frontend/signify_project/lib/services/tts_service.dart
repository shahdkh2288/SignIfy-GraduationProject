import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path_provider/path_provider.dart';

class TTSService {
  static const _baseUrl = 'http://10.0.2.2:5000';
  static const _storage = FlutterSecureStorage();

  // Direct audio download method
  static Future<String?> getTtsAudioDirect(String text) async {
    final token = await _storage.read(key: 'access_token');
    final url = Uri.parse('$_baseUrl/tts');

    print('Sending direct TTS request to: $url');
    print('Text: $text');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'text': text}),
      );

      print('Direct TTS Response status: ${response.statusCode}');
      print(
        'Direct TTS Response content type: ${response.headers['content-type']}',
      );

      if (response.statusCode == 200) {
        // Save the audio bytes to a temporary file
        final tempDir = await getTemporaryDirectory();
        final audioFile = File(
          '${tempDir.path}/tts_audio_${DateTime.now().millisecondsSinceEpoch}.mp3',
        );

        await audioFile.writeAsBytes(response.bodyBytes);
        print('Audio saved to: ${audioFile.path}');

        return audioFile.path;
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
