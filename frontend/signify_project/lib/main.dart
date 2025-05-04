import 'package:flutter/material.dart';
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
      },
    );
  }
}

