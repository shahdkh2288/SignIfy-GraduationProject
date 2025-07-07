import 'package:http/http.dart' as http;

class NetworkConfig {
  // Update this IP address to match your computer's IP address
  // Use 192.168.1.3 for your mobile phone
  // Use 10.0.2.2 for Android emulator
  static const String serverIP = '10.0.2.2';
  static const String serverPort = '5000';
  static const String baseUrl = 'http://$serverIP:$serverPort';

  // Network timeout settings
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);

  // Alternative URLs for different environments
  static const String emulatorUrl = 'http://10.0.2.2:5000';
  static const String localhostUrl = 'http://localhost:5000';

  /// Check if the server is reachable
  static Future<bool> isServerReachable() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(connectTimeout);

      return response.statusCode == 200;
    } catch (e) {
      print('Server not reachable at $baseUrl: $e');
      return false;
    }
  }

  /// Get the appropriate base URL based on the platform
  static String getBaseUrl() {
    // You can modify this logic based on your needs
    return baseUrl; // Always use mobile IP for now
  }

  /// Test connection and print diagnostic info
  static Future<void> testConnection() async {
    print('🔍 Testing network connection...');
    print('📡 Target URL: $baseUrl');

    try {
      final isReachable = await isServerReachable();
      if (isReachable) {
        print('✅ Server is reachable!');
      } else {
        print('❌ Server is not reachable');
        print('💡 Make sure:');
        print('   1. Backend server is running');
        print('   2. Phone and computer are on same WiFi');
        print('   3. Firewall allows connections');
        print('   4. IP address is correct: $serverIP');
      }
    } catch (e) {
      print('❌ Connection test failed: $e');
    }
  }
}
