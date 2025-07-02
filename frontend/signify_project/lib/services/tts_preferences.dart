import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final ttsSettingsProvider = StateNotifierProvider<TTSSettingsNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => TTSSettingsNotifier(),
);

class TTSSettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  TTSSettingsNotifier() : super(const AsyncValue.data({}));

  Future<void> updateTTSSettings({required String selectedVoiceId, required double stability}) async {
    state = const AsyncValue.loading();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:5000/update-preferences');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tts': {
            'voice_id': selectedVoiceId,   
            'stability': stability,  
          }
        }),
      );
      if (response.statusCode == 200) {
        state = AsyncValue.data(jsonDecode(response.body));
      } else {
        state = AsyncValue.error(jsonDecode(response.body)['error'] ?? 'Failed to update', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<Map<String, dynamic>?> fetchTTSPreferences() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:5000/get-tts-preferences');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}