import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../config/network_config.dart';

class STTService {
  static const _baseUrl = NetworkConfig.baseUrl;
  static final _storage = FlutterSecureStorage();

  static Future<String?> sendAudioForTranscription(File audioFile) async {
    try {
      final token = await _storage.read(key: 'access_token');
      if (token == null) {
        print('Token not found');
        return null;
      }

      final url = Uri.parse('$_baseUrl/stt');

      final request =
          http.MultipartRequest('POST', url)
            ..headers['Authorization'] = 'Bearer $token'
            ..files.add(
              await http.MultipartFile.fromPath('audio', audioFile.path),
            );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        return jsonBody['transcript'] ?? '';
      } else {
        print('STT failed: ${response.statusCode} ${response.body}');
        return null;
      }
    } catch (e) {
      print('STTService error: $e');
      return null;
    }
  }
}
