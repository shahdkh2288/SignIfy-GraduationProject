import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../config/network_config.dart';

class NetworkTestScreen extends StatefulWidget {
  const NetworkTestScreen({super.key});

  @override
  State<NetworkTestScreen> createState() => _NetworkTestScreenState();
}

class _NetworkTestScreenState extends State<NetworkTestScreen> {
  String _testResults = 'Tap "Test Connection" to start';
  bool _isLoading = false;

  Future<void> _testNetworkConnection() async {
    setState(() {
      _isLoading = true;
      _testResults = 'Testing network connection...\n';
    });

    final StringBuffer results = StringBuffer();
    results.writeln('🔍 Network Diagnostics');
    results.writeln('=' * 40);
    results.writeln('Target Server: ${NetworkConfig.baseUrl}');
    results.writeln('');

    try {
      // Test 1: Basic connectivity
      results.writeln('1️⃣ Testing basic connectivity...');
      final startTime = DateTime.now();

      try {
        final response = await http
            .get(
              Uri.parse('${NetworkConfig.baseUrl}/health'),
              headers: {'Content-Type': 'application/json'},
            )
            .timeout(const Duration(seconds: 10));

        final endTime = DateTime.now();
        final duration = endTime.difference(startTime).inMilliseconds;

        if (response.statusCode == 200) {
          results.writeln('✅ Server reachable (${duration}ms)');
          results.writeln('   Status: ${response.statusCode}');
          results.writeln('   Response: ${response.body.substring(0, 50)}...');
        } else {
          results.writeln(
            '⚠️ Server responded with status: ${response.statusCode}',
          );
          results.writeln('   Body: ${response.body}');
        }
      } catch (e) {
        results.writeln('❌ Basic connectivity failed: $e');
      }

      results.writeln('');

      // Test 2: Sign detection endpoint
      results.writeln('2️⃣ Testing sign detection endpoint...');
      try {
        final testData = {
          'landmarks': [
            List.generate(100, (i) => [0.5, 0.5, 0.0]),
          ],
        };

        final response = await http
            .post(
              Uri.parse('${NetworkConfig.baseUrl}/detect-sign'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode(testData),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final result = jsonDecode(response.body);
          results.writeln('✅ Sign detection endpoint working');
          results.writeln('   Predicted: ${result['word']}');
          results.writeln('   Confidence: ${result['confidence']}');
        } else {
          results.writeln('⚠️ Sign detection failed: ${response.statusCode}');
          results.writeln('   Error: ${response.body}');
        }
      } catch (e) {
        results.writeln('❌ Sign detection test failed: $e');
      }

      results.writeln('');

      // Test 3: Video endpoint simulation
      results.writeln('3️⃣ Testing video endpoint availability...');
      try {
        // Just test if the endpoint exists by sending a malformed request
        final response = await http
            .post(
              Uri.parse('${NetworkConfig.baseUrl}/detect-video-signs'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({}),
            )
            .timeout(const Duration(seconds: 10));

        // We expect this to fail, but if it responds, the endpoint exists
        results.writeln('✅ Video endpoint exists');
        results.writeln('   Status: ${response.statusCode}');
      } catch (e) {
        results.writeln('❌ Video endpoint test failed: $e');
      }

      results.writeln('');
      results.writeln('📋 Summary:');
      results.writeln('• Make sure backend server is running');
      results.writeln('• Verify both devices are on same WiFi');
      results.writeln('• Check IP address: ${NetworkConfig.serverIP}');
      results.writeln('• Ensure firewall allows connections');
    } catch (e) {
      results.writeln('💥 Test suite failed: $e');
    }

    setState(() {
      _testResults = results.toString();
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Network Test',
          style: TextStyle(fontFamily: 'LeagueSpartan'),
        ),
        backgroundColor: const Color(0xFF005FCE),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Configuration',
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Server IP: ${NetworkConfig.serverIP}'),
                    Text('Server Port: ${NetworkConfig.serverPort}'),
                    Text('Base URL: ${NetworkConfig.baseUrl}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isLoading ? null : _testNetworkConnection,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005FCE),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child:
                  _isLoading
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Testing...'),
                        ],
                      )
                      : const Text(
                        'Test Connection',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Test Results',
                        style: TextStyle(
                          fontFamily: 'LeagueSpartan',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Text(
                            _testResults,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
