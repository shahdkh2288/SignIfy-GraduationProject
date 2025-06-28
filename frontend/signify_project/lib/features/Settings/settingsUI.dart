import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 18),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Settings',
                    style: TextStyle(
                      fontFamily: 'LeagueSpartan',
                      fontWeight: FontWeight.bold,
                      fontSize: 44,
                      color: Color(0xFF005FCE),
                    ),
                  ),
                  IconButton(
                    icon: Image.asset(
                      'assets/images/notifications.png',
                      height: 44,
                      width: 44,
                    ),
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: 80),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _SettingsButton(
                    label: 'Text-to-Speech',
                    iconPath: 'assets/images/settings1.png',
                    onTap: () {
                      Navigator.pushNamed(context, '/tts-settings');
                    },
                  ),
                  const SizedBox(width: 32),
                  _SettingsButton(
                    label: 'Speech-to-Text',
                    iconPath: 'assets/images/micro2.png',
                    iconWidth: 80,  
                    iconHeight: 80,  
                    onTap: () {
                      Navigator.pushNamed(context, '/stt-settings');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 36),
              Center(
                child: _SettingsButton(
                  label: 'Feedback',
                  iconPath: 'assets/images/feedback.png',
                  onTap: () {
                    Navigator.pushNamed(context, '/feedback');
                  },
                ),
              ),
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

class _SettingsButton extends StatelessWidget {
  final String label;
  final String iconPath;
  final VoidCallback onTap;
  final double iconWidth;
  final double iconHeight;

  const _SettingsButton({
    required this.label,
    required this.iconPath,
    required this.onTap,
    this.iconWidth = 110,
    this.iconHeight = 110,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        height: 180,
        decoration: BoxDecoration(
          color: const Color(0xFFE3F1FB),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.22),
              blurRadius: 28,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              iconPath,
              width: iconWidth,
              height: iconHeight,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 18),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'LeagueSpartan',
                fontWeight: FontWeight.bold,
                fontSize: 23,
                color: Color(0xFF005FCE),
                shadows: [
                  Shadow(
                    color: Colors.white,
                    blurRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}