import 'package:flutter/material.dart';

import '../../app/app_theme.dart';
import '../brand/brand_assets.dart';

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
              boxShadow: [
                BoxShadow(
                  color: AppTheme.terracotta.withValues(alpha: 0.24),
                  blurRadius: 28,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.asset(
              BrandAssets.appLogo,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
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
