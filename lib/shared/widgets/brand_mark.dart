import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({this.size = 84, this.showBadge = true, super.key});

  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(size * 0.28),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF53E4D4), AppTheme.mint, Color(0xFF219E90)],
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.mint.withValues(alpha: 0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  left: size * 0.15,
                  top: size * 0.16,
                  child: Container(
                    width: size * 0.18,
                    height: size * 0.08,
                    decoration: BoxDecoration(
                      color: const Color(0xFF145952),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    width: size * 0.52,
                    height: size * 0.52,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: Center(
                      child: Container(
                        width: size * 0.3,
                        height: size * 0.3,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF18222E),
                          border: Border.all(
                            color: const Color(0xFF2B394A),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: size * 0.14,
                  top: size * 0.18,
                  child: Container(
                    width: size * 0.11,
                    height: size * 0.11,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFFF0CF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (showBadge)
            Positioned(
              right: -4,
              bottom: 2,
              child: Container(
                width: size * 0.28,
                height: size * 0.28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.amber,
                  border: Border.all(color: const Color(0xFF0A121D), width: 3),
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 16,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
