import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/app_theme.dart';
import '../../core/preferences/preferences_providers.dart';
import '../../l10n/l10n_extension.dart';
import 'mascot_data_provider.dart';
import 'mascot_dialogue.dart';

// ── Layout constants ──────────────────────────────────────────────────────────
const _frameCount = 10;
const _mascotHeight = 42.0;
const _mascotAspectRatio = 353 / 291;
const _walkDuration = Duration(seconds: 6);
const _frameDuration = Duration(milliseconds: 130);
const _actionFrameHeight = 58.0;
const _actionFrameWidth = 68.0;
const _baseBottom =
    8.0; // mascot feet align 8px above the bottom nav top border
const _buttonWidth = 68.0; // matches _CameraActionButton in bottom_nav_bar.dart
const _jumpHeight = 24.0; // lifts the mascot's feet up to the button's top edge

// ── Bounce animation constants ────────────────────────────────────────────────
const _bounceDuration = Duration(milliseconds: 400);

// ── Idle behaviour constants ──────────────────────────────────────────────────
const _ambientWalkDuration = Duration(seconds: 5);
const _actionVisibleDuration = Duration(seconds: 5);

// ── Speech bubble constants ───────────────────────────────────────────────────
const _speechDismissSeconds = 5;
const _speechBubbleMaxWidth = 200.0;
const _speechBubbleAbove = 60.0; // px above the mascot's feet

enum _MascotAction {
  look('look', 9),
  wave('wave', 9),
  sleep('sleep', 10),
  startled('startled', 10),
  celebrate('celebrate', 10);

  const _MascotAction(this.assetName, this.frameCount);

  final String assetName;
  final int frameCount;

  String assetPath(int frameIndex) {
    final safeFrame = frameIndex < frameCount ? frameIndex : frameCount - 1;
    return 'assets/mascot/generated/frames/mascot_$assetName'
        '_${safeFrame.toString().padLeft(2, '0')}.png';
  }
}

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

  // ── Feed & Confetti animation controllers ────────────────────────────────
  late final AnimationController _feedController;
  late final AnimationController _confettiController;
  bool _isEating = false;
  bool _showConfetti = false;
  bool _fedToday = false;
  final List<_Particle> _particles = [];

  // ── Frame sprite ─────────────────────────────────────────────────────────
  Timer? _frameTimer;
  int _frameIndex = 0;

  // ── Generated action sprites ─────────────────────────────────────────────
  Timer? _actionFrameTimer;
  _MascotAction? _activeAction;
  int _actionFrameIndex = 0;
  int _nextAmbientActionIndex = 0;
  bool _wasOverBudget = false;
  bool _wasHappy = false;

  // ── Idle ─────────────────────────────────────────────────────────────────
  Timer? _idleScheduler;
  bool _isIdling = false;

  // ── Speech bubble ─────────────────────────────────────────────────────────
  String? _speechText;
  bool _speechVisible = false;
  Timer? _speechDismissTimer;

  bool _autoGreetingShown = false;

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
        tween: Tween<double>(
          begin: 0,
          end: -16,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: -16,
          end: 4,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 4,
          end: 0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_bounceController);

    _feedController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _feedController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onFeedCompleted();
      }
    });

    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _feedController.addListener(() {
      setState(() {});
    });
    _confettiController.addListener(() {
      setState(() {});
    });
  }

  // ── Frame loop ─────────────────────────────────────────────────────────────
  void _startFrameLoop() {
    if (_activeAction != null) return;
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
    _idleScheduler = Timer(_ambientWalkDuration, _maybeIdle);
  }

  void _maybeIdle() {
    if (!mounted || _isIdling || _activeAction != null) return;
    _enterIdle();
  }

  void _enterIdle() {
    if (!mounted || _activeAction != null) return;
    _idleScheduler?.cancel();
    _idleScheduler = null;
    setState(() => _isIdling = true);
    _startAction(_pickIdleAction());
  }

  _MascotAction _pickIdleAction() {
    const ambientActions = [
      _MascotAction.look,
      _MascotAction.wave,
      _MascotAction.sleep,
      _MascotAction.startled,
      _MascotAction.celebrate,
    ];
    final action = ambientActions[_nextAmbientActionIndex];
    _nextAmbientActionIndex =
        (_nextAmbientActionIndex + 1) % ambientActions.length;
    return action;
  }

  void _startAction(_MascotAction action) {
    if (!mounted) return;
    _actionFrameTimer?.cancel();
    _stopFrameLoop();
    if (_walkController.isAnimating) {
      _walkController.stop();
    }

    setState(() {
      _activeAction = action;
      _actionFrameIndex = 0;
    });

    final actionFrameDuration = Duration(
      milliseconds: _actionVisibleDuration.inMilliseconds ~/ action.frameCount,
    );
    _actionFrameTimer = Timer.periodic(actionFrameDuration, (_) {
      if (!mounted) return;
      final nextFrame = _actionFrameIndex + 1;
      if (nextFrame >= action.frameCount) {
        _finishAction();
        return;
      }
      setState(() => _actionFrameIndex = nextFrame);
    });
  }

  void _finishAction() {
    _actionFrameTimer?.cancel();
    _actionFrameTimer = null;
    if (!mounted) return;

    final wasIdling = _isIdling;
    setState(() {
      _activeAction = null;
      _actionFrameIndex = 0;
      _isIdling = false;
    });

    _startFrameLoop();
    if (!_walkController.isAnimating) {
      _walkController.repeat(reverse: true);
    }
    if (wasIdling || _idleScheduler == null) {
      _scheduleNextIdleCheck();
    }
  }

  void _stopAction() {
    _actionFrameTimer?.cancel();
    _actionFrameTimer = null;
    _activeAction = null;
    _actionFrameIndex = 0;
  }

  void _queueStatusAction(_MascotAction action) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _activeAction != null || _isIdling) return;
      if (!ref.read(mascotEnabledProvider)) return;
      _startAction(action);
    });
  }

  // ── Tap handler ────────────────────────────────────────────────────────────
  void _onTap() {
    HapticFeedback.lightImpact();
    if (_isIdling || _activeAction != null) {
      _stopAction();
      _isIdling = false;
    }

    _startAction(_MascotAction.wave);
    _bounceController.forward(from: 0);

    final mascotDataAsync = ref.read(mascotDataProvider);
    final text = mascotDataAsync.whenOrNull(
      data: (data) => MascotDialogueGenerator.generate(
        context,
        allTimeEmpty: data.allTimeEmpty,
        budgetCategories: data.budgetCategories,
        todayTransactions: data.todayTransactions,
        monthTransactions: data.monthTransactions,
        streakDays: data.streakDays,
        isTap: true,
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

  void _showGreetingQuote(MascotData data) {
    final text = MascotDialogueGenerator.generate(
      context,
      allTimeEmpty: data.allTimeEmpty,
      budgetCategories: data.budgetCategories,
      todayTransactions: data.todayTransactions,
      monthTransactions: data.monthTransactions,
      streakDays: data.streakDays,
      isTap: false,
    );
    if (!mounted) return;
    setState(() {
      _speechText = text;
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

  // ── Feed animation trigger & callback ───────────────────────────────────────
  void _startFeedAnimation() {
    HapticFeedback.mediumImpact();
    _speechDismissTimer?.cancel();
    _stopAction();
    _isIdling = false;
    setState(() {
      _isEating = true;
      _showConfetti = false;
      _fedToday = true;
    });
    _feedController.forward(from: 0.0);
  }

  void _onFeedCompleted() {
    HapticFeedback.heavyImpact();
    _particles.clear();
    final colorsList = [
      Colors.red,
      Colors.orange,
      Colors.yellow,
      Colors.green,
      Colors.blue,
      Colors.pink,
      Colors.purple,
    ];
    for (int i = 0; i < 16; i++) {
      _particles.add(
        _Particle(
          angle: _rng.nextDouble() * 2 * math.pi,
          distance: 20.0 + _rng.nextDouble() * 45.0,
          color: colorsList[_rng.nextInt(colorsList.length)],
          size: 4.0 + _rng.nextDouble() * 6.0,
        ),
      );
    }

    setState(() {
      _isEating = false;
      _showConfetti = true;
      _speechText = context.l10n.mascotFedResponse;
    });
    _startAction(_MascotAction.celebrate);

    _confettiController.forward(from: 0.0);
    _feedController.reset();

    _speechDismissTimer?.cancel();
    _speechDismissTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) {
        setState(() {
          _speechVisible = false;
          _showConfetti = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _walkController.dispose();
    _bounceController.dispose();
    _feedController.dispose();
    _confettiController.dispose();
    _actionFrameTimer?.cancel();
    _stopFrameLoop();
    _idleScheduler?.cancel();
    _speechDismissTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled = ref.watch(mascotEnabledProvider);

    if (!enabled) {
      _stopFrameLoop();
      _stopAction();
      _idleScheduler?.cancel();
      _idleScheduler = null;
      _isIdling = false;
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

    final mascotDataAsync = ref.watch(mascotDataProvider);
    final data = mascotDataAsync.asData?.value;

    ref.listen<AsyncValue<MascotData>>(mascotDataProvider, (previous, next) {
      if (_autoGreetingShown) return;
      next.whenOrNull(
        data: (data) {
          _autoGreetingShown = true;
          Timer(const Duration(milliseconds: 1500), () {
            if (mounted) {
              _showGreetingQuote(data);
            }
          });
        },
      );
    });

    final isOverBudget =
        data?.budgetCategories.any((c) => c.isOverLimit) ?? false;
    final isHappy = (data?.streakDays ?? 0) >= 3;

    if (isOverBudget && !_wasOverBudget) {
      _queueStatusAction(_MascotAction.startled);
    } else if (!isOverBudget && isHappy && !_wasHappy) {
      _queueStatusAction(_MascotAction.celebrate);
    }
    _wasOverBudget = isOverBudget;
    _wasHappy = isHappy;

    final targetDuration = isOverBudget
        ? const Duration(seconds: 10)
        : (isHappy ? const Duration(seconds: 4) : const Duration(seconds: 6));

    if (_walkController.duration != targetDuration) {
      _walkController.duration = targetDuration;
      if (_walkController.isAnimating) {
        _walkController.repeat(reverse: true);
      }
    }

    if (_activeAction == null) {
      _startFrameLoop();
    }
    if (!_walkController.isAnimating && !_isIdling && _activeAction == null) {
      _walkController.repeat(reverse: true);
    }
    if (_idleScheduler == null && !_isIdling && _activeAction == null) {
      _scheduleNextIdleCheck();
    }

    const mascotWidth = _mascotHeight * _mascotAspectRatio;
    final screenWidth = MediaQuery.sizeOf(context).width;
    const leftBound = 12.0;
    final rightBound = (screenWidth - mascotWidth - 12.0).clamp(
      leftBound,
      double.infinity,
    );

    final showFeedButton =
        !_fedToday &&
        _speechVisible &&
        !_isEating &&
        _speechText != context.l10n.mascotFedResponse;

    return AnimatedBuilder(
      animation: Listenable.merge([_walkController, _bounceController]),
      builder: (context, child) {
        final x = leftBound + _walkController.value * (rightBound - leftBound);
        final movingLeft = _walkController.status == AnimationStatus.reverse;

        final mascotCenterX = x + mascotWidth / 2;
        final buttonCenterX = screenWidth / 2;
        final jumpZoneHalfWidth = _buttonWidth / 2 + mascotWidth;
        final distance = (mascotCenterX - buttonCenterX).abs();
        final jumpT = distance < jumpZoneHalfWidth
            ? math.cos((distance / jumpZoneHalfWidth) * (math.pi / 2))
            : 0.0;

        final bottomOffset =
            _baseBottom + _jumpHeight * jumpT - _bounceAnimation.value;

        final bubbleLeft = (x + mascotWidth / 2 - _speechBubbleMaxWidth / 2)
            .clamp(
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
            if (_speechText != null)
              Positioned(
                bottom: bubbleBottom,
                left: bubbleLeft,
                child: AnimatedScale(
                  scale: _speechVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutBack,
                  alignment: Alignment.bottomCenter,
                  child: _SpeechBubble(
                    text: _speechText!,
                    showFeedButton: showFeedButton,
                    onFeedTap: _startFeedAnimation,
                  ),
                ),
              ),

            if (_isEating)
              Positioned(
                bottom: () {
                  final double t = _feedController.value;
                  final startY = bubbleBottom + 12;
                  final endY = bottomOffset + _mascotHeight / 2;
                  return startY +
                      (endY - startY) * t -
                      35 * math.sin(t * math.pi);
                }(),
                left: () {
                  final double t = _feedController.value;
                  final startX = bubbleLeft + _speechBubbleMaxWidth / 2 - 8;
                  final endX = x + mascotWidth / 2 - 8;
                  return startX + (endX - startX) * t;
                }(),
                child: const IgnorePointer(
                  child: Text('🍎', style: TextStyle(fontSize: 16)),
                ),
              ),

            if (_showConfetti)
              Positioned(
                bottom: bottomOffset + _mascotHeight / 2 - 25,
                left: x + mascotWidth / 2 - 25,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 50,
                    height: 50,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: _particles.map((p) {
                        final currentDist =
                            p.distance * _confettiController.value;
                        final dx = currentDist * math.cos(p.angle);
                        final dy = currentDist * math.sin(p.angle);
                        final opacity = (1.0 - _confettiController.value).clamp(
                          0.0,
                          1.0,
                        );
                        return Positioned(
                          left: 25 + dx - p.size / 2,
                          top: 25 + dy - p.size / 2,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              width: p.size,
                              height: p.size,
                              decoration: BoxDecoration(
                                color: p.color,
                                shape: _rng.nextBool()
                                    ? BoxShape.circle
                                    : BoxShape.rectangle,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),

            Positioned(
              bottom: bottomOffset,
              left: x,
              child: GestureDetector(
                onTap: _onTap,
                behavior: HitTestBehavior.opaque,
                child: Transform.flip(flipX: movingLeft, child: child),
              ),
            ),
          ],
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          SizedBox(
            height: _mascotHeight,
            width: mascotWidth,
            child: OverflowBox(
              alignment: Alignment.bottomCenter,
              maxHeight: _activeAction == null
                  ? _mascotHeight
                  : _actionFrameHeight,
              maxWidth: _activeAction == null ? mascotWidth : _actionFrameWidth,
              child: SizedBox(
                height: _activeAction == null
                    ? _mascotHeight
                    : _actionFrameHeight,
                width: _activeAction == null ? mascotWidth : _actionFrameWidth,
                child: Image.asset(
                  _activeAction?.assetPath(_actionFrameIndex) ??
                      'assets/mascot/pig_${_frameIndex.toString().padLeft(2, '0')}.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomCenter,
                  filterQuality: FilterQuality.none,
                ),
              ),
            ),
          ),
          if (_showConfetti)
            const Positioned(
              top: -6,
              right: -6,
              child: Text('💖', style: TextStyle(fontSize: 11)),
            )
          else if (isOverBudget)
            const Positioned(
              top: -6,
              right: -6,
              child: Text('😰', style: TextStyle(fontSize: 11)),
            )
          else if (isHappy && !isOverBudget)
            const Positioned(
              top: -6,
              right: -6,
              child: Text('✨', style: TextStyle(fontSize: 11)),
            ),
        ],
      ),
    );
  }
}

class _Particle {
  _Particle({
    required this.angle,
    required this.distance,
    required this.color,
    required this.size,
  });
  final double angle;
  final double distance;
  final Color color;
  final double size;
}

class _SpeechBubble extends StatelessWidget {
  const _SpeechBubble({
    required this.text,
    this.onFeedTap,
    this.showFeedButton = false,
  });

  final String text;
  final VoidCallback? onFeedTap;
  final bool showFeedButton;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    final l10n = context.l10n;
    return Container(
      constraints: const BoxConstraints(maxWidth: _speechBubbleMaxWidth),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            text,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: colors.textPrimary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          if (showFeedButton) ...[
            const SizedBox(height: 6),
            GestureDetector(
              onTap: onFeedTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3.5,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.orange.withValues(alpha: 0.3),
                    width: 0.6,
                  ),
                ),
                child: Text(
                  l10n.mascotFeedAction,
                  style: const TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
