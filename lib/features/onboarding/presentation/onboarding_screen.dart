import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../l10n/l10n_extension.dart';
import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  static const routePath = '/onboarding';

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _pageIndex = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 4, right: 12),
                child: TextButton(
                  onPressed: _finish,
                  style: TextButton.styleFrom(
                    foregroundColor: colors.textDim,
                    minimumSize: const Size(64, 44),
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(context.l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _pageIndex = index),
                children: const [
                  _ReceiptScanSlide(),
                  _PhotoDiarySlide(),
                  _BudgetSlide(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: List.generate(
                        3,
                        (index) => AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutCubic,
                          width: _pageIndex == index ? 24 : 6,
                          height: 6,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            color: _pageIndex == index
                                ? colors.primary
                                : colors.textPrimary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
                  FilledButton(
                    onPressed: _pageIndex == 2 ? _finish : _nextPage,
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.square(48),
                      maximumSize: const Size.square(48),
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                    ),
                    child: Icon(
                      _pageIndex == 2
                          ? Icons.check_outlined
                          : Icons.chevron_right_outlined,
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await ref.read(onboardingSeenProvider.notifier).markSeen();
    if (!mounted) return;
    context.go(LoginScreen.routePath);
  }

  Future<void> _nextPage() async {
    await _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }
}

class _SlideLayout extends StatelessWidget {
  const _SlideLayout({
    required this.illustration,
    required this.title,
    this.subtitle,
    this.status,
  });

  final Widget illustration;
  final String title;
  final String? subtitle;
  final String? status;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 34),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: context.moniaryTypography.displayMedium.copyWith(
              fontSize: 27,
              height: 1.18,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 12),
            Text(
              subtitle!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
                height: 1.55,
              ),
            ),
          ],
          if (status != null) ...[
            const SizedBox(height: 12),
            Text(
              status!.toUpperCase(),
              textAlign: TextAlign.center,
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: colors.primary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReceiptScanSlide extends StatelessWidget {
  const _ReceiptScanSlide();

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: const _ReceiptScanIllustration(),
      title:
          '${context.l10n.onboardingPage1Title1}\n${context.l10n.onboardingPage1Title2}',
      status: context.l10n.onboardingPage1Subtitle,
    );
  }
}

class _ReceiptScanIllustration extends StatefulWidget {
  const _ReceiptScanIllustration();

  @override
  State<_ReceiptScanIllustration> createState() =>
      _ReceiptScanIllustrationState();
}

class _ReceiptScanIllustrationState extends State<_ReceiptScanIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _linePosition;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1350),
    )..repeat(reverse: true);
    _linePosition = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return SizedBox(
      width: 210,
      height: 250,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Container(
            width: 160,
            height: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.18),
                  blurRadius: 18,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: Stack(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.42),
                      width: 1.5,
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
                ...List.generate(
                  5,
                  (index) => Positioned(
                    left: 12,
                    right: index == 4 ? 38 : 12,
                    top: 18 + index * 18,
                    child: Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(
                          alpha: index == 0 ? 0.13 : 0.075,
                        ),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _linePosition,
                  builder: (context, child) {
                    return Positioned(
                      left: 4,
                      right: 4,
                      top: 18 + (_linePosition.value * 132),
                      child: child!,
                    );
                  },
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: const Color(0xFF5FD3C4),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF5FD3C4).withValues(alpha: 0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: colors.textPrimary,
                borderRadius: BorderRadius.circular(13),
                boxShadow: [
                  BoxShadow(
                    color: colors.textPrimary.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 9),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.24),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.onboardingReceiptCategory,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.background,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          context.l10n.onboardingReceiptDate,
                          style: context.moniaryTypography.metadata.copyWith(
                            color: colors.background.withValues(alpha: 0.54),
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    context.l10n.onboardingReceiptAmount,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      color: colors.secondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoDiarySlide extends StatelessWidget {
  const _PhotoDiarySlide();

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: const _PhotoDiaryIllustration(),
      title:
          '${context.l10n.onboardingPage2Title1}\n${context.l10n.onboardingPage2Title2}',
      subtitle: context.l10n.onboardingPage2Subtitle,
    );
  }
}

class _PhotoDiaryIllustration extends StatelessWidget {
  const _PhotoDiaryIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return Container(
      width: 194,
      height: 194,
      decoration: BoxDecoration(
        color: AppTheme.sage,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 14,
            top: 14,
            child: Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 38, 14, 14),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(24),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colors.textPrimary.withValues(alpha: 0.55),
                  ],
                ),
              ),
              child: Text(
                context.l10n.onboardingPhotoAmount,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetSlide extends StatelessWidget {
  const _BudgetSlide();

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: const _BudgetIllustration(),
      title:
          '${context.l10n.onboardingPage3Title1}\n${context.l10n.onboardingPage3Title2}',
      subtitle: context.l10n.onboardingPage3Subtitle,
    );
  }
}

class _BudgetIllustration extends StatelessWidget {
  const _BudgetIllustration();

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    return SizedBox.square(
      dimension: 184,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox.square(
            dimension: 168,
            child: CircularProgressIndicator(
              value: 0.7,
              strokeWidth: 15,
              strokeCap: StrokeCap.round,
              color: colors.primary,
              backgroundColor: colors.textPrimary.withValues(alpha: 0.08),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.onboardingBudgetPercent,
                style: context.moniaryTypography.displayMedium.copyWith(
                  fontSize: 31,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                context.l10n.onboardingBudgetLabel.toUpperCase(),
                style: context.moniaryTypography.metadata.copyWith(
                  fontSize: 8.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
