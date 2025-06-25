import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TTSService {
  static const _baseUrl = 'http://10.0.2.2:5000'; 
  static const _storage = FlutterSecureStorage();

  static Future<String?> getTtsAudioUrl(String text) async {
    final token = await _storage.read(key: 'access_token');
    final url = Uri.parse('$_baseUrl/tts');
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'text': text}),
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return _baseUrl + data['file'];
    } else {
      return null;
    }
  }
}