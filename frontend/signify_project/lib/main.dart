import 'package:flutter/material.dart';
import 'package:signify_project/Splash%20and%20Onboarding%20Screens/onboarding2.dart';
import 'package:signify_project/Splash%20and%20Onboarding%20Screens/onboarding3.dart';
import 'package:signify_project/Splash%20and%20Onboarding%20Screens/onboarding4.dart';
import 'Splash and Onboarding Screens/Splash.dart';
import 'Splash and Onboarding Screens/Onboarding1.dart';
void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Signify App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => SplashScreen(),
        '/onboarding1': (context) => OnboardingScreen1(),
        '/onboarding2': (context) => OnboardingScreen2(),
        '/onboarding3': (context) => OnBoardingScreen3(),
        '/onboarding4': (context) => OnboardingScreen4(),
        
      },
    );
  }
}

