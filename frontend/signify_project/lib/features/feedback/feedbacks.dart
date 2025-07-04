import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({super.key});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  int _stars = 0;
  String _feedbackText = '';
  bool _isLoading = false;
  String? _message;
  String? _userName;
  late TextEditingController _feedbackController;

  @override
  void initState() {
    super.initState();
    _feedbackController = TextEditingController(text: _feedbackText);
    _fetchUserName();
  }

  @override
  void dispose() {
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserName() async {
    const storage = FlutterSecureStorage();
    final jwt = await storage.read(key: 'access_token');
    if (jwt == null) return;
    try {
      final response = await http.get(
        Uri.parse('http://10.0.2.2:5000/protected'),
        headers: {'Authorization': 'Bearer $jwt'},
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['user']['fullname'] ?? 'User';
        });
      }
    } catch (_) {}
  }

  Future<void> _submitFeedback() async {
    if (_stars < 1 || _stars > 5) {
      setState(() {
        _message = 'Please select a rating from 1 to 5 stars.';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _message = null;
    });
    try {
      const storage = FlutterSecureStorage();
      final jwt = await storage.read(key: 'access_token');
      if (jwt == null) {
        setState(() {
          _isLoading = false;
          _message = 'No access token found.';
        });
        return;
      }
      final response = await http.post(
        Uri.parse('http://10.0.2.2:5000/submit-feedback'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwt',
        },
        body: jsonEncode({
          'stars': _stars,
          'feedback_text': _feedbackText,
        }),
      );
      if (response.statusCode == 201) {
        setState(() {
          _isLoading = false;
          _message = 'Feedback submitted successfully!';
          _stars = 0;
          _feedbackText = '';
          _feedbackController.clear();
        });
        await Future.delayed(const Duration(seconds: 2));
        setState(() {
          _message = null;
        });
      } else {
        final error = jsonDecode(response.body)['error'] ?? 'Failed to submit feedback';
        setState(() {
          _isLoading = false;
          _message = error;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _message = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    
    if (_feedbackController.text != _feedbackText) {
      _feedbackController.value = TextEditingValue(
        text: _feedbackText,
        selection: TextSelection.collapsed(offset: _feedbackText.length),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        
                        Builder(
                          builder: (context) {
                            String firstName = (_userName ?? '').split(' ').first;
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hi,',
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900, 
                                    fontFamily: 'LeagueSpartan',
                                    color: Color(0xFF005FCE),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  firstName,
                                  style: const TextStyle(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900, 
                                    fontFamily: 'LeagueSpartan',
                                    color: Color(0xFF005FCE),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              
              Text(
                "Let’s Make Signify Better Together!",
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                  color: Colors.black,
                  fontFamily: 'LeagueSpartan',
                  shadows: [
                    Shadow(
                      blurRadius: 6,
                      color: Colors.black.withOpacity(0.35),
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 38),
              
              const Text(
                "Rating",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 25,
                  color: Color(0xFF005FCE),
                  fontFamily: 'LeagueSpartan',
                ),
              ),
              const SizedBox(height: 15),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      _stars > index ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 42,
                    ),
                    onPressed: () {
                      setState(() {
                        _stars = index + 1;
                      });
                    },
                  );
                }),
              ),
              const SizedBox(height: 37),
              const Text(
                "Description",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25, color: Color(0xFF005FCE), fontFamily: 'LeagueSpartan'),
              ),
              const SizedBox(height: 25),
              SizedBox(
                height: 120, 
                child: Card(
                  color: Colors.blue.shade50,
                  elevation: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Stack(
                      children: [
                        Column(
                          children: [
                            Expanded(
                              child: Scrollbar(
                                thumbVisibility: true,
                                child: TextField(
                                  maxLength: 750,
                                  maxLines: null,
                                  expands: true,
                                  controller: _feedbackController,
                                  decoration: const InputDecoration(
                                    hintText: "Enter your feedback here...",
                                    border: InputBorder.none,
                                    counterText: '',
                                  ),
                                  onChanged: (val) => setState(() => _feedbackText = val),
                                  style: const TextStyle(fontSize: 16, fontFamily: 'LeagueSpartan'),
                                  textAlign: TextAlign.left,
                                  textDirection: TextDirection.ltr,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Text(
                                '${_feedbackText.length}/750',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_message != null)
                Text(
                  _message!,
                  style: TextStyle(
                    color: _message!.contains('success') ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2386E6),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'LeagueSpartan',
                    ),
                    foregroundColor: Colors.white, 
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Submit'),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        width: double.infinity,
        height: 70,
        decoration: const BoxDecoration(
          color: Color(0xFF005FCE),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(8),
            topRight: Radius.circular(8),
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/home');
                },
                child: Image.asset(
                  'assets/images/home.png',
                  width: 59,
                  height: 52,
                ),
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/settings');
                },
                child: Image.asset(
                  'assets/images/settings.png',
                  width: 56,
                  height: 60,
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 16,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/profile');
                },
                child: Image.asset(
                  'assets/images/user.png',
                  width: 58,
                  height: 58,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

