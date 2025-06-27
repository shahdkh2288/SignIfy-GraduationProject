import 'package:flutter/material.dart';


class OnboardingScreen1 extends StatelessWidget {
  const OnboardingScreen1({super.key});

  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
    body: SafeArea(child: 
    Center(
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/onboarding1.png', width: 300, height: 300),
          const SizedBox(height: 20),
          const Text(
            'Welcome to Signify! 👋',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              fontFamily: 'LeagueSpartan',
              color: Color(0xFF005FCE),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Bridging communication\nbetween everyone through sign language',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              color: Colors.grey[700],
              fontFamily: 'LeagueSpartan',
            ),
          ),
          const SizedBox(height: 32),
          Container(
            width: 226,
            height: 57,
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 6,
                  offset: const Offset(0, 4), 
                ),
              ],
              borderRadius: BorderRadius.circular(12),
            ),
          
          child : SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/onboarding2'); 
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: const Color(0xFF005FCE),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                
              ),
              child: const Text(
                'Get Started',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.white,
                  fontFamily: 'LeagueSpartan',
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          ),
        ],
      ))
    ))
    );
   
  }

}


  
