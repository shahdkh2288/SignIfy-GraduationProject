import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/network_config.dart';

final sttSettingsProvider = StateNotifierProvider<
  STTSettingsNotifier,
  AsyncValue<Map<String, dynamic>>
>((ref) => STTSettingsNotifier());

class STTSettingsNotifier
    extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
  STTSettingsNotifier() : super(const AsyncValue.data({}));

  Future<void> updateSTTSettings({
    required String language,
    required bool smartFormat,
    required bool profanityFilter,
  }) async {
    state = const AsyncValue.loading();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('${NetworkConfig.baseUrl}/update-preferences');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'stt': {
            'language': language,
            'smart_format': smartFormat,
            'profanity_filter': profanityFilter,
          },
        }),
      );
      if (response.statusCode == 200) {
        state = AsyncValue.data(jsonDecode(response.body));
      } else {
        state = AsyncValue.error(
          jsonDecode(response.body)['error'] ?? 'Failed to update',
          StackTrace.current,
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  Future<Map<String, dynamic>?> getCurrentSTTPreferences() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('${NetworkConfig.baseUrl}/get-stt-preferences');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['stt_preferences'] ?? data;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
