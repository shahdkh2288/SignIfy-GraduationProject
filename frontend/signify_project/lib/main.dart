import 'package:flutter/material.dart';
import 'package:signify_project/features/Splash%20and%20Onboarding%20Screens/onboarding1.dart';

import 'package:signify_project/features/Splash%20and%20Onboarding%20Screens/onboarding2.dart';
import 'package:signify_project/features/Splash%20and%20Onboarding%20Screens/onboarding3.dart';
import 'package:signify_project/features/Splash%20and%20Onboarding%20Screens/onboarding4.dart';
import 'package:signify_project/features/authentication/VerifyAccount.dart';
import 'package:signify_project/features/authentication/createNewPass.dart';
import 'package:signify_project/features/authentication/forgotPassword.dart';
import 'package:signify_project/features/authentication/login.dart';
import 'package:signify_project/features/authentication/signup.dart';
import 'features/Splash and Onboarding Screens/Splash.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

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
        '/login': (context) => LoginScreen(),
        '/forgotPassword': (context) => ForgotPasswordScreen(),
        '/signup': (context) => SignUpScreen(),
        '/verifyAccount': (context) => Verifyaccount(),
        '/createNewPassword': (context) => createNewPassword(),
        
      },
    );
  }
}

