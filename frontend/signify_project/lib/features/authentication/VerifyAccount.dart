import 'dart:async';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';

class Verifyaccount extends StatefulWidget {
  final String? email;
  const Verifyaccount({super.key, this.email});

  @override
  State<Verifyaccount> createState() => _VerifyaccountState();
}

class _VerifyaccountState extends State<Verifyaccount> {
  int _seconds = 59;
  Timer? _timer;
  bool _canResend = false;
  bool _isVerifying = false;
  final TextEditingController _codeController = TextEditingController();
  final AuthService _authService = AuthService();
  String? userEmail;
  String? resetToken;

  @override
  void initState() {
    super.initState();
    _startTimer();
    // Get email from route arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is String) {
        userEmail = args;
      } else if (widget.email != null) {
        userEmail = widget.email;
      }
    });
  }

  void _startTimer() {
    _seconds = 59;
    _canResend = false;
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_seconds > 0) {
        setState(() {
          _seconds--;
        });
      } else {
        setState(() {
          _canResend = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
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
              Center(child: Image.asset('assets/logo2.png', height: 130)),
              SizedBox(height: 8),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Image.asset('assets/back.png', height: 50, width: 50),
              ),
              SizedBox(height: 20),
              Center(
                child: Text(
                  'Verify Account',
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
                  'A verification code has been sent to your email. Please\n enter the code to verify your account.',
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
                'Enter Code',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'LeagueSpartan',
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 25),

              TextFormField(
                controller: _codeController,
                maxLength: 6,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  counterText: "",
                  hintText: '6 Digit Code',
                  hintStyle: TextStyle(
                    color: Color(0xFFBDBDBD),
                    fontFamily: 'LeagueSpartan',
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Color(0xFF005FCE), width: 2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
                style: TextStyle(fontFamily: 'LeagueSpartan', fontSize: 18),
              ),
              SizedBox(height: 120),
              Center(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Didn't Receive Code? ",
                          style: TextStyle(
                            fontFamily: 'LeagueSpartan',
                            fontSize: 15,
                            color: Colors.black54,
                          ),
                        ),
                        GestureDetector(
                          onTap:
                              _canResend
                                  ? () async {
                                    if (userEmail != null) {
                                      // Resend OTP
                                      final result = await _authService
                                          .forgotPassword(userEmail!);
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            result['success']
                                                ? 'OTP resent successfully!'
                                                : result['message'],
                                          ),
                                          backgroundColor:
                                              result['success']
                                                  ? Colors.green
                                                  : Colors.red,
                                        ),
                                      );
                                      if (result['success']) {
                                        _startTimer();
                                      }
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            'Email not found. Please try again.',
                                          ),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                  : null,
                          child: Text(
                            "Resend Code",
                            style: TextStyle(
                              fontFamily: 'LeagueSpartan',
                              fontSize: 15,
                              color:
                                  _canResend ? Color(0xFF005FCE) : Colors.grey,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      _canResend
                          ? "You can resend the code now"
                          : "Resend code in 00:${_seconds.toString().padLeft(2, '0')}",
                      style: TextStyle(
                        fontFamily: 'LeagueSpartan',
                        fontSize: 15,
                        color: Colors.black54,
                      ),
                    ),
                  ],
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
                  onPressed:
                      _isVerifying
                          ? null
                          : () async {
                            if (_codeController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Please Enter The Digit Code.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            if (userEmail == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Email not found. Please try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            setState(() {
                              _isVerifying = true;
                            });

                            try {
                              // Verify OTP first
                              final result = await _authService.verifyOtp(
                                email: userEmail!,
                                otp: _codeController.text.trim(),
                              );

                              setState(() {
                                _isVerifying = false;
                              });

                              if (result['success']) {
                                resetToken = result['reset_token'];
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('OTP verified successfully!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );

                                // Navigate to create new password screen with reset token
                                Navigator.pushNamed(
                                  context,
                                  '/createNewPassword',
                                  arguments: {'reset_token': resetToken},
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['message']),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              setState(() {
                                _isVerifying = false;
                              });
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'An error occurred. Please try again.',
                                  ),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                  child:
                      _isVerifying
                          ? CircularProgressIndicator(color: Colors.white)
                          : Text(
                            'Verify Account',
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
