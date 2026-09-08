import 'package:flutter/material.dart';

// Premium SaaS geometric logo badge for Stoptify
class AppLogoBadge extends StatelessWidget {
  const AppLogoBadge({
    super.key,
    this.size = 56,
  });

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF16161B),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(color: const Color(0xFF32323C), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.04),
            blurRadius: 16,
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Subtle inner octagon / stop shape
          Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFFFFF), Color(0xFFB0B0B8)],
              ),
              borderRadius: BorderRadius.circular(size * 0.14),
            ),
            child: Center(
              child: Container(
                width: size * 0.2,
                height: size * 0.2,
                decoration: BoxDecoration(
                  color: const Color(0xFF16161B),
                  borderRadius: BorderRadius.circular(size * 0.05),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


