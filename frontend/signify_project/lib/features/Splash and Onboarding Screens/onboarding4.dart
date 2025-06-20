
import 'package:flutter/material.dart';
import 'package:signify_project/features/Splash%20and%20Onboarding%20Screens/DotIndicator.dart';

class OnboardingScreen4 extends StatelessWidget{
  const OnboardingScreen4({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/onboarding4.png', width: 300, height: 300),
                const SizedBox(height: 20),
                const Text(
                  'Convert Between Speech',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF005FCE),
                  ),
                ),
                const Text(
                  ' and Text',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'LeagueSpartan',
                    color: Color(0xFF005FCE),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Speak to transcribe words instantly or hear written text read aloud with ease',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    color: Colors.grey[700],
                    fontFamily: 'LeagueSpartan',
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    DotIndicator(isActive: false),
                    SizedBox(width: 2), 
                    DotIndicator(isActive: false),
                    SizedBox(width: 2),
                    DotIndicator(isActive: true),
                  ],
                ),
                const SizedBox(height: 120,width: 60,),
                Padding(
                  padding: const EdgeInsets.only(top: 25.0),
                  child : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login'); 
                        },
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            fontSize: 26,
                            color: Color(0xFF005FCE),
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/login'); 
                        },
                        child: const Text(
                          'Next',
                          style: TextStyle(
                            fontSize: 26,
                            color: Color(0xFF005FCE),
                            fontFamily: 'LeagueSpartan',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}