import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../core/preferences/preferences_providers.dart';
import 'mascot_data_provider.dart';
import 'mascot_dialogue.dart';

// ── Layout constants ──────────────────────────────────────────────────────────
const _frameCount = 10;
const _mascotHeight = 42.0;
const _mascotAspectRatio = 353 / 291;
const _walkDuration = Duration(seconds: 6);
const _frameDuration = Duration(milliseconds: 130);
const _baseBottom = 0.0; // aligned with the -10.0 bottom offset in the shell stack
const _buttonWidth = 68.0; // matches _CameraActionButton in bottom_nav_bar.dart
const _jumpHeight = 24.0; // lifts the mascot's feet up to the button's top edge

// ── Bounce animation constants ────────────────────────────────────────────────
const _bounceDuration = Duration(milliseconds: 400);

// ── Idle behaviour constants ──────────────────────────────────────────────────
const _idleMinSeconds = 8;
const _idleMaxSeconds = 15;
const _idleChance = 0.3; // 30 % probability of pausing
const _idlePauseSeconds = 3;

// ── Speech bubble constants ───────────────────────────────────────────────────
const _speechDismissSeconds = 5;
const _speechBubbleMaxWidth = 200.0;
const _speechBubbleAbove = 60.0; // px above the mascot's feet

// ── Idle frame range ─────────────────────────────────────────────────────────
const _idleFrameStart = 0;
const _idleFrameEnd = 2;

class MascotOverlay extends ConsumerStatefulWidget {
  const MascotOverlay({super.key});

  @override
  ConsumerState<MascotOverlay> createState() => _MascotOverlayState();
}

class _MascotOverlayState extends ConsumerState<MascotOverlay>
    with TickerProviderStateMixin {
  // ── Walk controller ──────────────────────────────────────────────────────
  late final AnimationController _walkController;

  // ── Bounce controller (tap feedback) ────────────────────────────────────
  late final AnimationController _bounceController;
  late final Animation<double> _bounceAnimation;

  // ── Frame sprite ─────────────────────────────────────────────────────────
  Timer? _frameTimer;
  int _frameIndex = 0;

  // ── Idle ─────────────────────────────────────────────────────────────────
  Timer? _idleScheduler;
  bool _isIdling = false;
  int _idleFrameIndex = _idleFrameStart;
  Timer? _idleFrameTimer;
  Timer? _idleExitTimer;

  // ── Speech bubble ─────────────────────────────────────────────────────────
  String? _speechText;
  bool _speechVisible = false;
  Timer? _speechDismissTimer;

  final math.Random _rng = math.Random();

  @override
  void initState() {
    super.initState();

    _walkController = AnimationController(vsync: this, duration: _walkDuration);

    _bounceController = AnimationController(
      vsync: this,
      duration: _bounceDuration,
    );
    _bounceAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0, end: -16).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -16, end: 4).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 4, end: 0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);
  }

  // ── Frame loop ─────────────────────────────────────────────────────────────
  void _startFrameLoop() {
    _frameTimer ??= Timer.periodic(_frameDuration, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = (_frameIndex + 1) % _frameCount);
    });
  }

  void _stopFrameLoop() {
    _frameTimer?.cancel();
    _frameTimer = null;
  }

  // ── Idle behaviour ─────────────────────────────────────────────────────────
  void _scheduleNextIdleCheck() {
    _idleScheduler?.cancel();
    final seconds =
        _idleMinSeconds + _rng.nextInt(_idleMaxSeconds - _idleMinSeconds);
    _idleScheduler = Timer(Duration(seconds: seconds), _maybeIdle);
  }

  void _maybeIdle() {
    if (!mounted || _isIdling) return;
    if (_rng.nextDouble() < _idleChance) {
      _enterIdle();
    } else {
      _scheduleNextIdleCheck();
    }
  }

  void _enterIdle() {
    _walkController.stop();
    _stopFrameLoop();
    setState(() {
      _isIdling = true;
      _idleFrameIndex = _idleFrameStart;
    });

    _idleFrameTimer?.cancel();
    // Slowly cycle between idle frames
    _idleFrameTimer = Timer.periodic(const Duration(milliseconds: 300), (_) {
      if (!mounted) return;
      setState(() {
        _idleFrameIndex = _idleFrameIndex == _idleFrameStart
            ? _idleFrameEnd
            : _idleFrameStart;
      });
    });

    // Return to walking after pause
    _idleExitTimer?.cancel();
    _idleExitTimer = Timer(const Duration(seconds: _idlePauseSeconds), _exitIdle);
  }

  void _exitIdle() {
    if (!mounted) return;
    _idleFrameTimer?.cancel();
    _idleFrameTimer = null;
    _idleExitTimer?.cancel();
    _idleExitTimer = null;
    _walkController.repeat(reverse: true);
    setState(() => _isIdling = false);
    _scheduleNextIdleCheck();
  }

  // ── Tap handler ────────────────────────────────────────────────────────────
  void _onTap() {
    // Interrupt idle if active
    if (_isIdling) _exitIdle();

    // Bounce animation
    _bounceController.forward(from: 0);

    // Pick dialogue from current data snapshot
    final mascotDataAsync = ref.read(mascotDataProvider);
    final text = mascotDataAsync.whenOrNull(
      data: (data) => MascotDialogueGenerator.generate(
        context,
        allTimeEmpty: data.allTimeEmpty,
        budgetCategories: data.budgetCategories,
        todayTransactions: data.todayTransactions,
        monthTransactions: data.monthTransactions,
      ),
    );

    if (!mounted) return;
    setState(() {
      _speechText = text ?? MascotDialogueGenerator.randomFunQuote(context);
      _speechVisible = true;
    });

    _speechDismissTimer?.cancel();
    _speechDismissTimer = Timer(
      const Duration(seconds: _speechDismissSeconds),
      () {
        if (mounted) setState(() => _speechVisible = false);
      },
    );
  }

  @override
  void dispose() {
    _walkController.dispose();
    _bounceController.dispose();
    _stopFrameLoop();
    _idleScheduler?.cancel();
    _idleFrameTimer?.cancel();
    _idleExitTimer?.cancel();
    _speechDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(mascotEnabledProvider);

    if (!enabled) {
      _stopFrameLoop();
      _idleScheduler?.cancel();
      _idleScheduler = null;
      _idleFrameTimer?.cancel();
      _idleFrameTimer = null;
      _idleExitTimer?.cancel();
      _idleExitTimer = null;
      _speechDismissTimer?.cancel();
      _speechDismissTimer = null;
      if (_walkController.isAnimating) {
        _walkController.stop();
      }
      if (_bounceController.isAnimating) {
        _bounceController.stop();
      }
      return const SizedBox.shrink();
    }

    _startFrameLoop();
    if (!_walkController.isAnimating && !_isIdling) {
      _walkController.repeat(reverse: true);
    }
    if (_idleScheduler == null && !_isIdling) {
      _scheduleNextIdleCheck();
    }

    const mascotWidth = _mascotHeight * _mascotAspectRatio;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const leftBound = 12.0;
    final rightBound =
        (screenWidth - mascotWidth - 12.0).clamp(leftBound, double.infinity);

    return AnimatedBuilder(
      animation: Listenable.merge([_walkController, _bounceController]),
      builder: (context, child) {
        final x = leftBound + _walkController.value * (rightBound - leftBound);
        final movingLeft =
            _walkController.status == AnimationStatus.reverse;

        // Hop over the "+" camera button (centred on screen)
        final mascotCenterX = x + mascotWidth / 2;
        final buttonCenterX = screenWidth / 2;
        final jumpZoneHalfWidth = _buttonWidth / 2 + mascotWidth;
        final distance = (mascotCenterX - buttonCenterX).abs();
        final jumpT = distance < jumpZoneHalfWidth
            ? math.cos((distance / jumpZoneHalfWidth) * (math.pi / 2))
            : 0.0;

        final bottomOffset =
            _baseBottom + _jumpHeight * jumpT - _bounceAnimation.value;

        // Clamp bubble so it never overflows left or right edge
        final bubbleLeft =
            (x + mascotWidth / 2 - _speechBubbleMaxWidth / 2).clamp(
          8.0,
          (screenWidth - _speechBubbleMaxWidth - 8.0).clamp(
            8.0,
            double.infinity,
          ),
        );

        final bubbleBottom = bottomOffset + _speechBubbleAbove;

        return Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Speech bubble ──────────────────────────────────────────────
            if (_speechText != null)
              Positioned(
                bottom: bubbleBottom,
                left: bubbleLeft,
                child: AnimatedOpacity(
                  opacity: _speechVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: IgnorePointer(
                    child: _SpeechBubble(text: _speechText!),
                  ),
                ),
              ),

            // ── Mascot sprite ──────────────────────────────────────────────
            Positioned(
              bottom: bottomOffset,
              left: x,
              child: GestureDetector(
                onTap: _onTap,
                behavior: HitTestBehavior.opaque,
                child: Transform.flip(
                  flipX: movingLeft,
                  child: child,
                ),
              ),
            ),
          ],
        );
      },
      child: SizedBox(
        height: _mascotHeight,
        width: mascotWidth,
        child: Image.asset(
          'assets/mascot/pig_${(_isIdling ? _idleFrameIndex : _frameIndex).toString().padLeft(2, '0')}.png',
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

// ── Speech bubble widget ───────────────────────────────────────────────────────

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return Container(
      constraints: const BoxConstraints(maxWidth: _speechBubbleMaxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: colors.outline,
          width: 0.8,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: colors.textPrimary,
          height: 1.4,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
