import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:5000';
  final storage = const FlutterSecureStorage();

  Future<Map<String, dynamic>> login(
    String usernameOrEmail,
    String password,
  ) async {
    try {
      final trimmedUsernameOrEmail = usernameOrEmail.trim();
      final trimmedPassword = password.trim();
      Map<String, dynamic> body = {'password': trimmedPassword};
      if (trimmedUsernameOrEmail.contains('@')) {
        body = {'email': trimmedUsernameOrEmail, 'password': trimmedPassword};
      } else {
        body = {
          'username': trimmedUsernameOrEmail,
          'password': trimmedPassword,
        };
      }
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final accessToken = jsonResponse['access_token'];
        final user = jsonResponse['user'];

        // Store the access token securely
        await storage.write(key: 'access_token', value: accessToken);

        return {
          'success': true,
          'user': user,
          'message': jsonResponse['message'],
        };
      } else {
        final jsonResponse = json.decode(response.body);
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Login failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> signup({
    required String fullname,
    required String username,
    required String email,
    required String password,
    required String dateofbirth,
    required String role,
  }) async {
    try {
      final body = {
        'fullname': fullname.trim(),
        'username': username.trim(),
        'email': email.trim(),
        'password': password.trim(),
        'dateofbirth': dateofbirth.trim(),
        'role': role.trim(),
      };
      final response = await http.post(
        Uri.parse('$baseUrl/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );
      if (response.statusCode == 201) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Signup successful',
        };
      } else {
        final jsonResponse = json.decode(response.body);
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Signup failed',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<String?> getAccessToken() async {
    return await storage.read(key: 'access_token');
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
  }

  Future<bool> isAuthenticated() async {
    final token = await getAccessToken();
    return token != null;
  }

  // Helper method to get auth header
  Future<Map<String, String>> getAuthHeader() async {
    final token = await getAccessToken();
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final body = {'email': email.trim()};
      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'OTP sent to email',
        };
      } else {
        final jsonResponse = json.decode(response.body);
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Failed to send OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String email,
    required String otp,
  }) async {
    try {
      final body = {'email': email.trim(), 'otp': otp.trim()};
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'OTP verified successfully',
          'reset_token': jsonResponse['reset_token'],
        };
      } else {
        final jsonResponse = json.decode(response.body);
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Failed to verify OTP',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithToken({
    required String resetToken,
    required String newPassword,
  }) async {
    try {
      final body = {
        'reset_token': resetToken.trim(),
        'new_password': newPassword.trim(),
      };
      final response = await http.post(
        Uri.parse('$baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(body),
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Password reset successful',
        };
      } else {
        final jsonResponse = json.decode(response.body);
        return {
          'success': false,
          'message': jsonResponse['error'] ?? 'Failed to reset password',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
    }
  }
}
