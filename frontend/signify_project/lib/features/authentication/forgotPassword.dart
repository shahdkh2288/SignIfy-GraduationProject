import 'package:flutter/material.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 17, vertical: 17),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 20),
              Center(
                child: Image.asset('assets/images/logo2.png', height: 130),
              ),
              SizedBox(height: 8),
              IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Image.asset(
                    'assets/images/back.png',
                    height: 50,
                    width: 50,
                  )),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'LeagueSpartan',
                    fontSize: 24,
                    color: Colors.black,
                  ),
                ),
              ),
              SizedBox(height: 12),
              
              Center(
                child: Text(
                  'No worries! Enter your email address below and we will\nsend you a code to reset password.',
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              SizedBox(height: 32),
              
              Text(
                'E-mail',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 25),
              
              Form(
                key: _formKey,
                child: TextFormField(
                  controller: _emailController,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    final emailRegex = RegExp(
                      r'^[\w\.-]+@(?:gmail\.com|yahoo\.com|outlook\.com|hotmail\.com|icloud\.com)$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Enter a valid Gmail, Yahoo, Outlook, Hotmail, or iCloud email';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    hintText: 'Email',
                    prefixIcon: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Image.asset(
                        'assets/images/userIcon.png',
                        height: 20,
                        width: 20,
                        fit: BoxFit.contain,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  style: TextStyle(
                    fontFamily: 'LeagueSpartan',
                  ),
                ),
              ),
              SizedBox(height: 55),
              
              SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF005FCE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (_formKey.currentState!.validate()) {
                            setState(() {
                              _isLoading = true;
                            });
                            await Future.delayed(Duration(seconds: 2));
                            setState(() {
                              _isLoading = false;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Reset instructions sent to your email!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                       
                            await Future.delayed(Duration(milliseconds: 5000));
                            Navigator.pushNamed(context, '/verifyAccount');
                          }
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Send Reset Instructions',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}