import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0B1521), AppTheme.background, Color(0xFF071019)],
        ),
      ),
      child: Stack(
        children: [
          const _GlowOrb(
            alignment: Alignment.topCenter,
            color: AppTheme.mint,
            size: 220,
            offset: Offset(0, -120),
          ),
          const _GlowOrb(
            alignment: Alignment.topRight,
            color: AppTheme.pink,
            size: 180,
            offset: Offset(80, -30),
          ),
          const _GlowOrb(
            alignment: Alignment.bottomLeft,
            color: AppTheme.amber,
            size: 170,
            offset: Offset(-70, 90),
          ),
          child,
        ],
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.alignment,
    required this.color,
    required this.size,
    required this.offset,
  });

  final Alignment alignment;
  final Color color;
  final double size;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: offset,
        child: IgnorePointer(
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  color.withValues(alpha: 0.28),
                  color.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
