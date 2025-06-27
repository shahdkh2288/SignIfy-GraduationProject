import 'package:flutter/material.dart';

import 'package:signify_project/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isPasswordVisible = false;
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
              Center(child: Image.asset('assets/images/logo2.png', height: 130)),
              SizedBox(height: 8),
              Text.rich(
                TextSpan(
                  text: 'Welcome ',
                  style: TextStyle(
                    fontSize: 32,
                    fontFamily: 'LeagueSpartan',
                    fontWeight: FontWeight.bold,
                  ),
                  children: [
                    TextSpan(
                      text: 'Back!',
                      style: TextStyle(
                        fontSize: 32,
                        fontFamily: 'LeagueSpartan',
                        color: Color(0xFF005FCE),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 35),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: 'Email or User Name',
                        hintStyle: TextStyle(
                          color: const Color.fromARGB(255, 218, 217, 217),
                          fontFamily: 'LeagueSpartan',
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/emailIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF005FCE),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF005FCE),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email or username';
                        }
                        if (!value.contains('@') && value.length < 3) {
                          return 'Please enter a valid email or username';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 60),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        hintStyle: TextStyle(
                          color: const Color.fromARGB(255, 218, 217, 217),
                          fontFamily: 'LeagueSpartan',
                        ),
                        prefixIcon: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Image.asset(
                            'assets/images/passIcon.png',
                            height: 20,
                            width: 20,
                            fit: BoxFit.contain,
                          ),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Color.fromARGB(255, 162, 162, 162),
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF005FCE),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF005FCE),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 16,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters long';
                        }
                        return null;
                      },
                    ),
                    SizedBox(height: 35),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/forgotPassword');
                        },
                        child: Text(
                          'Forgot Password ?',
                          style: TextStyle(
                            color: Color(0xFF005FCE),
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () async {
                                if (_formKey.currentState!.validate()) {
                                  setState(() {
                                    _isLoading = true;
                                  });
                                  final result = await _authService.login(
                                    _emailController.text.trim(),
                                    _passwordController.text.trim(),
                                  );
                                  setState(() {
                                    _isLoading = false;
                                  });
                                  if (result['success'] == true) {
                                    
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Login successful!'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                    await Future.delayed(
                                      Duration(milliseconds: 500),
                                    );
                                    Navigator.pushReplacementNamed(
                                      context,
                                      '/home',
                                    );
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          result['message'] ?? 'Login failed',
                                        ),
                                        backgroundColor: Colors.red,
                                      ),
                                    );
                                  }
                                }
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF005FCE),
                        padding: EdgeInsets.symmetric(
                          horizontal: 163,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child:
                          _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text(
                                'Login',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontFamily: 'LeagueSpartan',
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    SizedBox(height: 68),
                    Center(
                      child: Text(
                        'Or Login With',
                        style: TextStyle(
                          fontSize: 20,
                          fontFamily: 'LeagueSpartan',
                          color: Color(0xFF005FCE),
                          fontWeight: FontWeight.w100,
                          shadows: [
                            Shadow(
                              color: Colors.grey.withOpacity(0.5),
                              offset: Offset(1.5, 1.5),
                              blurRadius: 2.0,
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Image.asset(
                            'assets/images/googleIcon.png',
                            height: 50,
                            width: 50,
                          ),
                        ),
                        SizedBox(width: 30),
                        GestureDetector(
                          onTap: () {
                            // icloud login
                          },
                          child: Image.asset(
                            'assets/images/icloudIcon.png',
                            height: 50,
                            width: 50,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 65),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Don’t have an account ? ",
                          style: TextStyle(
                            fontSize: 20,
                            fontFamily: 'LeagueSpartan',
                            color: Color(0xFF005FCE),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text(
                            'Sign Up',
                            style: TextStyle(
                              color: Color(0xFF005FCE),
                              fontFamily: 'LeagueSpartan',
                              fontWeight: FontWeight.bold,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
