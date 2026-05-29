import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/supabase/signed_url_provider.dart';

class SupabaseImage extends ConsumerWidget {
  const SupabaseImage({
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = Icons.photo_outlined,
    super.key,
  });

  final String? imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildFallback();
    }

    final isHttp = imagePath!.startsWith('http');
    if (isHttp) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.network(
          imagePath!,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }

    final isLocal = !imagePath!.startsWith('transactions/');
    if (isLocal) {
      return ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Image.file(
          File(imagePath!),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
        ),
      );
    }

    final signedUrlAsync = ref.watch(signedUrlProvider(imagePath!));

    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.zero,
      child: signedUrlAsync.when(
        data: (url) => Image.network(
          url,
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) => _buildFallback(),
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: width,
              height: height,
              color: Colors.black12,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            );
          },
        ),
        loading: () => Container(
          width: width,
          height: height,
          color: Colors.black12,
          child: const Center(
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        ),
        error: (err, stack) => _buildFallback(),
      ),
    );
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      color: Colors.white10,
      child: Icon(
        fallbackIcon,
        size: (width != null && width! < 30) ? 14 : 24,
        color: Colors.white30,
      ),
    );
  }
}
