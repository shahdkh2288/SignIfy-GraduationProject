import 'package:flutter/material.dart';

class DotIndicator extends StatelessWidget{
  final bool isActive;

  const DotIndicator({Key? key, required this.isActive}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF005FCE) : Colors.grey[300],
        shape: BoxShape.circle,
        
      ),
    );
  }
}