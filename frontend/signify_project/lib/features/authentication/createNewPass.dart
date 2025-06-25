import 'package:flutter/material.dart';

class createNewPassword extends StatefulWidget {
  const createNewPassword({super.key});

  @override
  _createNewPasswordState createState() => _createNewPasswordState();
}

class _createNewPasswordState extends State<createNewPassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  final passwordRegex = RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&]).{8,}$');

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

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
                child: Image.asset('assets/logo2.png', height: 130),
              ),
              SizedBox(height: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Image.asset(
                  'assets/back.png',
                  height: 50,
                  width: 50,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Create New Password',
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
                  'Please enter and confirm your new password. You will need\nto log in again after resetting it.',
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
                'Enter new Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'new password',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/passIcon.png', 
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey, 
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
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
                onChanged: (_) {
                  setState(() {}); 
                },
              ),
              
              SizedBox(height: 45),
              Text(
                'Confirm New Password',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 30),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: !_isConfirmPasswordVisible,
                decoration: InputDecoration(
                  hintText: 'confirm new password',
                  prefixIcon: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Image.asset(
                      'assets/passIcon.png',
                      height: 20,
                      width: 20,
                      fit: BoxFit.contain,
                    ),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      color: Colors.grey, 
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
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
              SizedBox(height: 90),
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
                          if (_passwordController.text.isEmpty ||
                              _confirmPasswordController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Please fill in both fields.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (!passwordRegex.hasMatch(_passwordController.text)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Password must be at least 8 characters,\ninclude upper, lower, number & special char.',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          if (_passwordController.text != _confirmPasswordController.text) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Passwords do not match.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }
                          setState(() {
                            _isLoading = true;
                          });
                          await Future.delayed(Duration(seconds: 2));
                          setState(() {
                            _isLoading = false;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Password reset successful! Please log in with your new password.'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          await Future.delayed(Duration(seconds: 1));
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                  child: _isLoading
                      ? CircularProgressIndicator(
                          color: Colors.white,
                        )
                      : Text(
                          'Reset Password',
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