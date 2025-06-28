import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

final changePasswordProvider = StateNotifierProvider<ChangePasswordNotifier, AsyncValue<String>>(
  (ref) => ChangePasswordNotifier(),
);

class ChangePasswordNotifier extends StateNotifier<AsyncValue<String>> {
  ChangePasswordNotifier() : super(const AsyncValue.data(''));

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    state = const AsyncValue.loading();
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'access_token');
      final url = Uri.parse('http://10.0.2.2:5000/change-password');
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      final json = jsonDecode(response.body);
      if (response.statusCode == 200) {
        state = AsyncValue.data(json['message'] ?? 'Password changed successfully');
      } else {
        state = AsyncValue.error(json['error'] ?? 'Failed to change password', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }
}