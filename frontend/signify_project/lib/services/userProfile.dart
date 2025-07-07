import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signify_project/models/userModel.dart';
import '../config/network_config.dart';

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  final url = Uri.parse('${NetworkConfig.baseUrl}/protected');
  final response = await http.get(
    url,
    headers: {'Authorization': 'Bearer $token'},
  );
  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    return UserProfile.fromJson(data['user']);
  } else {
    throw Exception('Failed to load profile');
  }
});
