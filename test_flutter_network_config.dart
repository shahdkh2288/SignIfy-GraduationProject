import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Test Flutter network configuration with emulator base URL
void main() async {
  const String emulatorBaseUrl = 'http://10.0.2.2:5000';

  print('🔍 Testing Flutter network configuration for Android emulator...');
  print('📡 Target URL: $emulatorBaseUrl');

  // Test health endpoint
  try {
    print('\n🩺 Testing health endpoint...');
    final healthResponse = await http
        .get(
          Uri.parse('$emulatorBaseUrl/health'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(Duration(seconds: 10));

    if (healthResponse.statusCode == 200) {
      print('✅ Health endpoint accessible: ${healthResponse.body}');
    } else {
      print('❌ Health endpoint failed: ${healthResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Health endpoint error: $e');
  }

  // Test session management
  try {
    print('\n📋 Testing session management...');
    final sessionsResponse = await http
        .get(
          Uri.parse('$emulatorBaseUrl/list-sessions'),
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(Duration(seconds: 10));

    if (sessionsResponse.statusCode == 200) {
      final sessions = jsonDecode(sessionsResponse.body);
      print('✅ Session management accessible');
      print('   - Active sessions: ${sessions['sessions']?.length ?? 0}');
    } else {
      print('❌ Session management failed: ${sessionsResponse.statusCode}');
    }
  } catch (e) {
    print('❌ Session management error: $e');
  }

  print('\n🏁 Network configuration test completed');
  print(
    '💡 If all tests pass, the Flutter app should work with the Android emulator',
  );
  print('💡 If tests fail, ensure the backend is running on port 5000');
}
