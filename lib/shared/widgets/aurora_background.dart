import 'package:flutter/material.dart';

import '../../app/app_theme.dart';

class AuroraBackground extends StatelessWidget {
  const AuroraBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            colors.backgroundSoft,
            colors.background,
            Color.lerp(colors.background, Colors.black, 0.16)!,
          ],
        ),
      ),
      child: Stack(
        children: [
          _GlowOrb(
            alignment: Alignment.topCenter,
            color: colors.primary,
            size: 220,
            offset: const Offset(0, -120),
          ),
          _GlowOrb(
            alignment: Alignment.topRight,
            color: colors.accentPink,
            size: 180,
            offset: const Offset(80, -30),
          ),
          _GlowOrb(
            alignment: Alignment.bottomLeft,
            color: colors.warning,
            size: 170,
            offset: const Offset(-70, 90),
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
