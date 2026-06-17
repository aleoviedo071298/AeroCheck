import 'package:flutter/material.dart';

class ScreenLayout extends StatelessWidget {
  const ScreenLayout({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background: half light, half dark
        Column(
          children: [
            Expanded(child: Container(color: const Color(0xFFF1F5F9))),
            Expanded(child: Container(color: const Color(0xFF0F172A))),
          ],
        ),
        // Content
        child,
      ],
    );
  }
}
