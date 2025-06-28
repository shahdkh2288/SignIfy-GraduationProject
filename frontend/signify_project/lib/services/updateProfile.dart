import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:signify_project/models/userModel.dart';

final updateProfileProvider = FutureProvider.family<UserProfile, Map<String, dynamic>>((ref, data) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'access_token');
  final url = Uri.parse('http://10.0.2.2:5000/update-profile');

  var request = http.MultipartRequest('PUT', url);
  request.headers['Authorization'] = 'Bearer $token';

  data.forEach((key, value) {
    if (key == 'profile_image' && value is File) {
      request.files.add(http.MultipartFile.fromBytes(
        'profile_image',
        value.readAsBytesSync(),
        filename: value.path.split('/').last,
      ));
    } else if (value != null) {
      request.fields[key] = value.toString();
    }
  });

  final streamedResponse = await request.send();
  final response = await http.Response.fromStream(streamedResponse);

  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return UserProfile.fromJson(json['user']);
  } else {
    throw Exception(jsonDecode(response.body)['error'] ?? 'Failed to update profile');
  }
});