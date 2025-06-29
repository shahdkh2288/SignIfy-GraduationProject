import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final sttSettingsProvider = StateNotifierProvider<STTSettingsNotifier, AsyncValue<Map<String, dynamic>>>(
  (ref) => STTSettingsNotifier(),
);

class STTSettingsNotifier extends StateNotifier<AsyncValue<Map<String, dynamic>>> {
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
      final url = Uri.parse('http://10.0.2.2:5000/update-preferences');
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
}