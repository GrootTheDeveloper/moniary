import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/preferences/preferences_providers.dart';

const _frameCount = 10;
const _mascotHeight = 42.0;
const _mascotAspectRatio = 353 / 291;
const _walkDuration = Duration(seconds: 6);
const _frameDuration = Duration(milliseconds: 130);
const _baseTop = -18.0;
const _buttonWidth = 68.0; // matches _CameraActionButton in bottom_nav_bar.dart
const _jumpHeight = 24.0; // lifts the mascot's feet up to the button's top edge

class MascotOverlay extends ConsumerStatefulWidget {
  const MascotOverlay({super.key});

  @override
  ConsumerState<MascotOverlay> createState() => _MascotOverlayState();
}

class _MascotOverlayState extends ConsumerState<MascotOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _walkController;
  Timer? _frameTimer;
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _walkController = AnimationController(vsync: this, duration: _walkDuration)
      ..repeat(reverse: true);
  }

  void _startFrameLoop() {
    _frameTimer ??= Timer.periodic(_frameDuration, (_) {
      setState(() => _frameIndex = (_frameIndex + 1) % _frameCount);
    });
  }

  void _stopFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  @override
  void dispose() {
    _walkController.dispose();
    _stopFrameLoop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(mascotEnabledProvider);

    if (!enabled) {
      _stopFrameLoop();
      return const SizedBox.shrink();
    }
    _startFrameLoop();

    const mascotWidth = _mascotHeight * _mascotAspectRatio;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const leftBound = 12.0;
    final rightBound = (screenWidth - mascotWidth - 12.0).clamp(
      leftBound,
      double.infinity,
    );

    // Positioned must be a direct result of this builder (no RenderObjectWidget
    // ancestor like LayoutBuilder/IgnorePointer between it and the parent Stack).
    return AnimatedBuilder(
      animation: _walkController,
      builder: (context, child) {
        final x = leftBound + _walkController.value * (rightBound - leftBound);
        final movingLeft = _walkController.status == AnimationStatus.reverse;

        // Hop up onto the "+" button (centered on screen) instead of
        // walking behind it.
        final mascotCenterX = x + mascotWidth / 2;
        final buttonCenterX = screenWidth / 2;
        final jumpZoneHalfWidth = _buttonWidth / 2 + mascotWidth;
        final distance = (mascotCenterX - buttonCenterX).abs();
        final jumpT = distance < jumpZoneHalfWidth
            ? math.cos((distance / jumpZoneHalfWidth) * (math.pi / 2))
            : 0.0;

        return Positioned(
          top: _baseTop - _jumpHeight * jumpT,
          left: x,
          child: IgnorePointer(
            child: Transform.flip(flipX: movingLeft, child: child),
          ),
        );
      },
      child: SizedBox(
        height: _mascotHeight,
        width: mascotWidth,
        child: Image.asset(
          'assets/mascot/pig_${_frameIndex.toString().padLeft(2, '0')}.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
