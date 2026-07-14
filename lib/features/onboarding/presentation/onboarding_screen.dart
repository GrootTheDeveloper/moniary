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
                children: [
                  _ReceiptScanSlide(isActive: _pageIndex == 0),
                  _PhotoDiarySlide(isActive: _pageIndex == 1),
                  _BudgetSlide(isActive: _pageIndex == 2),
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

// ---------------------------------------------------------------------------
// Shared slide layout
// ---------------------------------------------------------------------------

class _SlideLayout extends StatelessWidget {
  const _SlideLayout({
    required this.illustration,
    required this.title,
    this.subtitle,
  });

  final Widget illustration;
  final String title;
  final String? subtitle;

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
        ],
      ),
    );
  }
}

// Custom Clipper for jagged receipt bottom
class _ReceiptClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 6);

    const toothWidth = 8.0;
    const toothHeight = 4.0;
    final numTeeth = (size.width / toothWidth).ceil();

    for (int i = 0; i < numTeeth; i++) {
      final x2 = (i + 0.5) * toothWidth;
      final x3 = (i + 1) * toothWidth;
      path.lineTo(x2, size.height - 6 + toothHeight);
      path.lineTo(x3, size.height - 6);
    }

    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

// ---------------------------------------------------------------------------
// SLIDE 1 — Receipt Scanning
// ---------------------------------------------------------------------------

class _ReceiptScanSlide extends StatelessWidget {
  const _ReceiptScanSlide({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _ReceiptScanIllustration(isActive: isActive),
      title:
          '${context.l10n.onboardingPage1Title1}\n${context.l10n.onboardingPage1Title2}',
      subtitle: context.l10n.onboardingPage1Caption,
    );
  }
}

class _ReceiptScanIllustration extends StatefulWidget {
  const _ReceiptScanIllustration({required this.isActive});
  final bool isActive;

  @override
  State<_ReceiptScanIllustration> createState() =>
      _ReceiptScanIllustrationState();
}

class _ReceiptScanIllustrationState extends State<_ReceiptScanIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _master;

  // Animations (Relaxed, 5.0 seconds overall)
  late final Animation<double> _frameOpacity;
  late final Animation<double> _frameScale;
  late final Animation<double> _receiptSlide;
  late final Animation<double> _receiptOpacity;
  late final Animation<double> _scanLine;
  late final Animation<double> _statusOpacity;
  late final Animation<double> _resultSlide;
  late final Animation<double> _resultOpacity;

  // Detail pills stagger
  late final Animation<double> _pill1Opacity;
  late final Animation<double> _pill1Slide;
  late final Animation<double> _pill2Opacity;
  late final Animation<double> _pill2Slide;
  late final Animation<double> _pill3Opacity;
  late final Animation<double> _pill3Slide;

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000), // Slower, 5 seconds
    );
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.isActive && _master.status == AnimationStatus.completed) {
            _master.forward(from: 0);
          }
        });
      }
    });
    _initAnimations();
    if (widget.isActive) _master.forward();
  }

  void _initAnimations() {
    const easeOut = Curves.easeOutCubic;

    // Step 1: Camera frame in (0% -> 12%)
    _frameOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.00, 0.12, curve: easeOut),
    );
    _frameScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.00, 0.14, curve: easeOut),
      ),
    );

    // Step 2: Receipt slide up (12% -> 26%) - pause slightly after frame in
    _receiptOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.12, 0.24, curve: easeOut),
    );
    _receiptSlide = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.12, 0.26, curve: easeOut),
      ),
    );

    // Step 3: Scan sweep (28% -> 56%) - nice long, clearly visible sweep
    _scanLine = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.28, 0.56, curve: Curves.easeInOutCubic),
    );

    // Step 4: Status HUD text fade-in (50% -> 66%)
    _statusOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.50, 0.66, curve: easeOut),
    );

    // Step 5: Result Card slides up (64% -> 80%) - delayed after scan is finished
    _resultOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.64, 0.78, curve: easeOut),
    );
    _resultSlide = Tween<double>(begin: 28, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.64, 0.80, curve: easeOut),
      ),
    );

    // Step 6: Detail pills staggered fade-in (78% -> 100%)
    _pill1Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.78, 0.88, curve: easeOut),
    );
    _pill1Slide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.78, 0.88, curve: easeOut),
      ),
    );
    _pill2Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.84, 0.94, curve: easeOut),
    );
    _pill2Slide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.84, 0.94, curve: easeOut),
      ),
    );
    _pill3Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.90, 1.00, curve: easeOut),
    );
    _pill3Slide = Tween<double>(begin: 12, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.90, 1.00, curve: easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _ReceiptScanIllustration old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _master.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    const cameraW = 230.0;
    const cameraH = 215.0; // Increased from 175.0 to 215.0 for longer aspect ratio

    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        return SizedBox(
          width: cameraW,
          height: 360, // Increased overall height from 310 to 360
          child: Column(
            children: [
              // ── Camera frame
              Opacity(
                opacity: _frameOpacity.value,
                child: Transform.scale(
                  scale: _frameScale.value,
                  child: Container(
                    width: cameraW,
                    height: cameraH,
                    decoration: BoxDecoration(
                      color: const Color(0xFF191613),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: colors.outline.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.22),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Subtle camera grid lines (3x3 grid)
                        ..._buildGridLines(cameraW, cameraH),
                        // Top HUD (REC/AUTO indicators)
                        _buildTopHUD(colors),
                        // Corner brackets
                        ..._buildBrackets(colors.primary),
                        // Receipt card inside camera (now taller)
                        Positioned(
                          left: 36,
                          right: 36,
                          top: 26 + _receiptSlide.value,
                          bottom: 26,
                          child: Opacity(
                            opacity: _receiptOpacity.value,
                            child: _buildReceiptCard(colors),
                          ),
                        ),
                        // Scan line (extended sweep range)
                        if (_scanLine.value > 0 && _scanLine.value < 1)
                          Positioned(
                            left: 30,
                            right: 30,
                            top: 26 + _scanLine.value * (cameraH - 58),
                            child: _buildScanLine(),
                          ),
                        // High-contrast Status HUD overlay (glowing teal)
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 12,
                          child: Opacity(
                            opacity: _statusOpacity.value,
                            child: _buildStatusBar(context, colors),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Result card
              Opacity(
                opacity: _resultOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _resultSlide.value),
                  child: _buildResultCard(context, colors),
                ),
              ),
              const SizedBox(height: 12),
              // ── Detail pills (using Wrap to prevent horizontal overflow)
              Wrap(
                spacing: 6,
                runSpacing: 6,
                alignment: WrapAlignment.center,
                children: [
                  Opacity(
                    opacity: _pill1Opacity.value,
                    child: Transform.translate(
                      offset: Offset(_pill1Slide.value, 0),
                      child: _buildPill(
                        context,
                        colors,
                        Icons.category_outlined,
                        context.l10n.onboardingCategoryFood,
                        colors.primary,
                        colors.primary.withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _pill2Opacity.value,
                    child: Transform.translate(
                      offset: Offset(_pill2Slide.value, 0),
                      child: _buildPill(
                        context,
                        colors,
                        Icons.calendar_today_outlined,
                        context.l10n.onboardingReceiptDate,
                        colors.textSecondary,
                        colors.outline.withValues(alpha: 0.25),
                      ),
                    ),
                  ),
                  Opacity(
                    opacity: _pill3Opacity.value,
                    child: Transform.translate(
                      offset: Offset(_pill3Slide.value, 0),
                      child: _buildPill(
                        context,
                        colors,
                        Icons.payments_outlined,
                        context.l10n.onboardingReceiptAmount,
                        const Color(0xFF4A7C59),
                        const Color(0xFF4A7C59).withValues(alpha: 0.08),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildGridLines(double w, double h) {
    final linePaintColor = Colors.white.withValues(alpha: 0.06);
    return [
      Positioned(
        left: w / 3,
        top: 0,
        bottom: 0,
        child: Container(width: 1, color: linePaintColor),
      ),
      Positioned(
        left: 2 * w / 3,
        top: 0,
        bottom: 0,
        child: Container(width: 1, color: linePaintColor),
      ),
      Positioned(
        top: h / 3,
        left: 0,
        right: 0,
        child: Container(height: 1, color: linePaintColor),
      ),
      Positioned(
        top: 2 * h / 3,
        left: 0,
        right: 0,
        child: Container(height: 1, color: linePaintColor),
      ),
    ];
  }

  Widget _buildTopHUD(MoniaryColors colors) {
    return Positioned(
      top: 10,
      left: 14,
      right: 14,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Color(0xFFE8794C),
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 4),
              Text(
                'RAW',
                style: TextStyle(
                  color: Colors.white24,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
          Text(
            'EV 0.0',
            style: TextStyle(
              color: Colors.white24,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBrackets(Color color) {
    const bracketSize = 12.0;
    const bracketThick = 1.5;
    const pad = 12.0;
    return [
      Positioned(
        left: pad,
        top: pad,
        child: _CornerBracket(
          color: color,
          size: bracketSize,
          thickness: bracketThick,
          corner: _BracketCorner.topLeft,
        ),
      ),
      Positioned(
        right: pad,
        top: pad,
        child: _CornerBracket(
          color: color,
          size: bracketSize,
          thickness: bracketThick,
          corner: _BracketCorner.topRight,
        ),
      ),
      Positioned(
        left: pad,
        bottom: pad,
        child: _CornerBracket(
          color: color,
          size: bracketSize,
          thickness: bracketThick,
          corner: _BracketCorner.bottomLeft,
        ),
      ),
      Positioned(
        right: pad,
        bottom: pad,
        child: _CornerBracket(
          color: color,
          size: bracketSize,
          thickness: bracketThick,
          corner: _BracketCorner.bottomRight,
        ),
      ),
    ];
  }

  Widget _buildReceiptCard(MoniaryColors colors) {
    return ClipPath(
      clipper: _ReceiptClipper(),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceRaised,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
            ),
          ],
        ),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mock store name
            Row(
              children: [
                Icon(Icons.local_cafe_outlined, size: 8, color: colors.primary),
                const SizedBox(width: 3),
                Container(
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Text lines simulating receipt body
            ...List.generate(
              5, // Increased line count from 3 to 5 for taller receipt card
              (i) => Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                height: 3.5,
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(
                    alpha: i == 0 ? 0.12 : 0.06,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Spacer(),
            // Mock barcode
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                14, // Increased barcode width
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 0.8),
                  width: index % 4 == 0 ? 2 : 1,
                  height: 12,
                  color: colors.textPrimary.withValues(alpha: 0.15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScanLine() {
    return Container(
      height: 2.5,
      decoration: BoxDecoration(
        color: const Color(0xFF5FD3C4),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF5FD3C4).withValues(alpha: 0.7),
            blurRadius: 10,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, MoniaryColors colors) {
    const tealColor = Color(0xFF5FD3C4); // Glowing teal color matching scanner

    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF191613).withValues(alpha: 0.8), // Dark pill body
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: tealColor.withValues(alpha: 0.6), // Glowing teal border
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: tealColor.withValues(alpha: 0.25),
              blurRadius: 8,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: tealColor, // Glowing teal solid dot
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              context.l10n.onboardingScanning,
              style: context.moniaryTypography.metadataStrong.copyWith(
                color: tealColor, // High contrast teal text on dark background
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, MoniaryColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colors.outline.withValues(alpha: 0.8),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(Icons.restaurant_outlined, size: 16, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.onboardingCategoryFood,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.onboardingRecognized,
                  style: context.moniaryTypography.metadata.copyWith(
                    color: colors.primary,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Text(
            context.l10n.onboardingReceiptAmount,
            style: context.moniaryTypography.displaySmall.copyWith(
              color: colors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(
    BuildContext context,
    MoniaryColors colors,
    IconData icon,
    String label,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5), // Slightly reduced padding
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: context.moniaryTypography.metadataStrong.copyWith(
              fontSize: 9.0, // Reduced from 9.5 to prevent overflows
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SLIDE 2 — Photo Diary Calendar
// ---------------------------------------------------------------------------

class _PhotoDiarySlide extends StatelessWidget {
  const _PhotoDiarySlide({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _PhotoDiaryIllustration(isActive: isActive),
      title:
          '${context.l10n.onboardingPage2Title1}\n${context.l10n.onboardingPage2Title2}',
      subtitle: context.l10n.onboardingPage2Subtitle,
    );
  }
}

class _PhotoDiaryIllustration extends StatefulWidget {
  const _PhotoDiaryIllustration({required this.isActive});
  final bool isActive;

  @override
  State<_PhotoDiaryIllustration> createState() =>
      _PhotoDiaryIllustrationState();
}

class _PhotoDiaryIllustrationState extends State<_PhotoDiaryIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _master;

  // Animations (Relaxed, 5.0 seconds overall)
  late final Animation<double> _gridOpacity;
  late final Animation<double> _gridScale;
  late final List<Animation<double>> _cellScale;
  late final List<Animation<double>> _cellOpacity;
  late final Animation<double> _incomePillOpacity;
  late final Animation<double> _incomePillSlide;
  late final Animation<double> _expensePillOpacity;
  late final Animation<double> _expensePillSlide;
  late final Animation<double> _streakScale;
  late final Animation<double> _streakOpacity;

  // Cells data (10 filled cells with specific categories and mock photos)
  static const _filledCells = {0, 2, 3, 5, 7, 9, 11, 13, 14, 17};
  static const _cellColors = [
    Color(0xFF8E9B8F), // sage
    Color(0xFFB85C38), // terracotta
    Color(0xFFC2A98E), // taupe
    Color(0xFFA98C86), // dusty rose
    Color(0xFF7E8CA0), // slate
    Color(0xFFD9A574), // sand
    Color(0xFF4A7C59), // forest
    Color(0xFFB85C38), // terracotta
    Color(0xFF8E9B8F), // sage
    Color(0xFFA98C86), // dusty rose
  ];

  static const _cellIcons = [
    Icons.restaurant_outlined,
    Icons.local_cafe_outlined,
    Icons.shopping_bag_outlined,
    Icons.directions_car_outlined,
    Icons.movie_outlined,
    Icons.flight_takeoff_outlined,
    Icons.fitness_center_outlined,
    Icons.home_outlined,
    Icons.restaurant_outlined,
    Icons.card_giftcard_outlined,
  ];

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000), // 5 seconds
    );
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.isActive && _master.status == AnimationStatus.completed) {
            _master.forward(from: 0);
          }
        });
      }
    });
    _initAnimations();
    if (widget.isActive) _master.forward();
  }

  void _initAnimations() {
    const easeOut = Curves.easeOutCubic;

    // Step 1: Grid in (0% -> 14%)
    _gridOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.00, 0.14, curve: easeOut),
    );
    _gridScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.00, 0.16, curve: easeOut),
      ),
    );

    // Step 2: 10 cells pop staggered (16% -> 66%)
    _cellScale = [];
    _cellOpacity = [];
    for (int i = 0; i < 10; i++) {
      final start = 0.16 + i * 0.05;
      final end = (start + 0.12).clamp(0.0, 1.0);
      _cellOpacity.add(CurvedAnimation(
        parent: _master,
        curve: Interval(start, end, curve: easeOut),
      ));
      _cellScale.add(
        Tween<double>(begin: 0.3, end: 1.0).animate(
          CurvedAnimation(
            parent: _master,
            curve: Interval(start, end, curve: Curves.elasticOut),
          ),
        ),
      );
    }

    // Step 3: Income/Expense pills slide in (62% -> 76%)
    _incomePillOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.62, 0.74, curve: easeOut),
    );
    _incomePillSlide = Tween<double>(begin: -20, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.62, 0.74, curve: easeOut),
      ),
    );

    _expensePillOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.66, 0.78, curve: easeOut),
    );
    _expensePillSlide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.66, 0.78, curve: easeOut),
      ),
    );

    // Step 4: Streak badge pops (76% -> 96%) - pause slightly after grid is full
    _streakOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.76, 0.88, curve: easeOut),
    );
    _streakScale = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.76, 0.96, curve: Curves.elasticOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _PhotoDiaryIllustration old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _master.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    const cols = 4;
    const rows = 5;
    const cellSize = 46.0;
    const gap = 6.0;
    const gridW = cols * cellSize + (cols - 1) * gap;
    const gridH = rows * cellSize + (rows - 1) * gap;

    final filledList = _filledCells.toList()..sort();

    return AnimatedBuilder(
      animation: _master,
      // Removed fixed outer SizedBox to let Column resize freely and solve bottom overflow
      builder: (context, _) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Streak fire badge
            Opacity(
              opacity: _streakOpacity.value,
              child: Transform.scale(
                scale: _streakScale.value,
                child: _buildStreakBadge(context, colors),
              ),
            ),
            const SizedBox(height: 10),
            // Calendar Grid (Polaroid Style)
            Opacity(
              opacity: _gridOpacity.value,
              child: Transform.scale(
                scale: _gridScale.value,
                child: SizedBox(
                  width: gridW,
                  height: gridH,
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      mainAxisSpacing: gap,
                      crossAxisSpacing: gap,
                    ),
                    itemCount: cols * rows,
                    itemBuilder: (ctx, index) {
                      final filledIndex = filledList.indexOf(index);
                      final isFilled = filledIndex != -1;
                      return _buildDayCell(
                        context,
                        colors,
                        index,
                        isFilled,
                        isFilled ? filledIndex : -1,
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Income/Expense pills
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Opacity(
                  opacity: _incomePillOpacity.value,
                  child: Transform.translate(
                    offset: Offset(_incomePillSlide.value, 0),
                    child: _buildStatPill(
                      context,
                      colors,
                      Icons.south_west_rounded,
                      context.l10n.onboardingIncome,
                      const Color(0xFF4A7C59),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Opacity(
                  opacity: _expensePillOpacity.value,
                  child: Transform.translate(
                    offset: Offset(_expensePillSlide.value, 0),
                    child: _buildStatPill(
                      context,
                      colors,
                      Icons.north_east_rounded,
                      context.l10n.onboardingExpenseLabel,
                      const Color(0xFFA94736),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildDayCell(
    BuildContext context,
    MoniaryColors colors,
    int index,
    bool isFilled,
    int filledIndex,
  ) {
    final day = index + 1;
    if (isFilled) {
      final baseColor = _cellColors[filledIndex % _cellColors.length];
      final icon = _cellIcons[filledIndex % _cellIcons.length];

      return Transform.scale(
        scale: _cellScale[filledIndex].value,
        child: Opacity(
          opacity: _cellOpacity[filledIndex].value,
          child: Container(
            decoration: BoxDecoration(
              color: colors.surfaceRaised,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: colors.outline.withValues(alpha: 0.8),
                width: 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.textPrimary.withValues(alpha: 0.06),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(2), // Polaroid thin border
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            baseColor,
                            baseColor.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                // Polaroid bottom text frame
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      '$day',
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        fontSize: 7.5,
                        color: colors.textSecondary,
                        height: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Empty grid day
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: colors.outline.withValues(alpha: 0.4),
          ),
          color: colors.surface.withValues(alpha: 0.35),
        ),
        child: Center(
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 9,
              color: colors.textDim.withValues(alpha: 0.45),
            ),
          ),
        ),
      );
    }
  }

  Widget _buildStreakBadge(BuildContext context, MoniaryColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.30),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            '12 ${context.l10n.onboardingStreakLabel}',
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: colors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatPill(
    BuildContext context,
    MoniaryColors colors,
    IconData icon,
    String label,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: context.moniaryTypography.metadataStrong.copyWith(
              color: color,
              fontSize: 9.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SLIDE 3 — Budget & Insights
// ---------------------------------------------------------------------------

class _BudgetSlide extends StatelessWidget {
  const _BudgetSlide({required this.isActive});
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return _SlideLayout(
      illustration: _BudgetIllustration(isActive: isActive),
      title:
          '${context.l10n.onboardingPage3Title1}\n${context.l10n.onboardingPage3Title2}',
      subtitle: context.l10n.onboardingPage3Subtitle,
    );
  }
}

class _BudgetIllustration extends StatefulWidget {
  const _BudgetIllustration({required this.isActive});
  final bool isActive;

  @override
  State<_BudgetIllustration> createState() => _BudgetIllustrationState();
}

class _BudgetIllustrationState extends State<_BudgetIllustration>
    with TickerProviderStateMixin {
  late final AnimationController _master;

  // Animations (Relaxed, 5.0 seconds overall)
  late final Animation<double> _ringValue;
  late final Animation<int> _percentCounter;
  late final Animation<double> _ringOpacity;
  late final Animation<double> _row1Opacity;
  late final Animation<double> _row1Slide;
  late final Animation<double> _row2Opacity;
  late final Animation<double> _row2Slide;
  late final Animation<double> _row3Opacity;
  late final Animation<double> _row3Slide;
  late final Animation<double> _warningProgress;
  late final Animation<double> _insightOpacity;
  late final Animation<double> _insightSlide;

  static const _categories = [
    (icon: Icons.restaurant_outlined, label: 'onboardingCategoryFood', percent: 0.45),
    (icon: Icons.directions_bus_outlined, label: 'onboardingCategoryTransport', percent: 0.18),
    (icon: Icons.movie_outlined, label: 'onboardingCategoryEntertainment', percent: 0.07),
  ];

  @override
  void initState() {
    super.initState();
    _master = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5000), // 5 seconds
    );
    _master.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted && widget.isActive && _master.status == AnimationStatus.completed) {
            _master.forward(from: 0);
          }
        });
      }
    });
    _initAnimations();
    if (widget.isActive) _master.forward();
  }

  void _initAnimations() {
    const easeOut = Curves.easeOutCubic;

    // Step 1: Ring fade-in and draw (0% -> 38%)
    _ringOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.00, 0.14, curve: easeOut),
    );
    _ringValue = Tween<double>(begin: 0.0, end: 0.70).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.06, 0.38, curve: Curves.easeInOutCubic),
      ),
    );
    _percentCounter = IntTween(begin: 0, end: 70).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.06, 0.38, curve: Curves.easeInOutCubic),
      ),
    );

    // Step 2: Category rows slide in staggered (38% -> 74%)
    _row1Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.38, 0.52, curve: easeOut),
    );
    _row1Slide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.38, 0.52, curve: easeOut),
      ),
    );

    _row2Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.48, 0.62, curve: easeOut),
    );
    _row2Slide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.48, 0.62, curve: easeOut),
      ),
    );

    _row3Opacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.58, 0.72, curve: easeOut),
    );
    _row3Slide = Tween<double>(begin: 20, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.58, 0.72, curve: easeOut),
      ),
    );

    // Step 3: Nearing-limit warning color lerps (68% -> 84%) - delayed after rows are in
    _warningProgress = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.68, 0.84, curve: easeOut),
    );

    // Step 4: Insight banner pops up (80% -> 96%)
    _insightOpacity = CurvedAnimation(
      parent: _master,
      curve: const Interval(0.80, 0.94, curve: easeOut),
    );
    _insightSlide = Tween<double>(begin: 16, end: 0).animate(
      CurvedAnimation(
        parent: _master,
        curve: const Interval(0.80, 0.96, curve: easeOut),
      ),
    );
  }

  @override
  void didUpdateWidget(covariant _BudgetIllustration old) {
    super.didUpdateWidget(old);
    if (widget.isActive && !old.isActive) {
      _master.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _master.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;

    final warningColor = Color.lerp(
      colors.primary,
      const Color(0xFFA94736),
      _warningProgress.value,
    )!;

    final rowOpacities = [_row1Opacity, _row2Opacity, _row3Opacity];
    final rowSlides = [_row1Slide, _row2Slide, _row3Slide];

    return AnimatedBuilder(
      animation: _master,
      builder: (context, _) {
        return SizedBox(
          width: 228,
          child: Column(
            children: [
              // ── Budget ring
              Opacity(
                opacity: _ringOpacity.value,
                child: SizedBox.square(
                  dimension: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox.square(
                        dimension: 130,
                        child: CircularProgressIndicator(
                          value: _ringValue.value,
                          strokeWidth: 12,
                          strokeCap: StrokeCap.round,
                          color: warningColor,
                          backgroundColor: colors.textPrimary.withValues(
                            alpha: 0.08,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${_percentCounter.value}%',
                            style:
                                context.moniaryTypography.displayMedium.copyWith(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            context.l10n.onboardingBudgetUsed.toUpperCase(),
                            style: context.moniaryTypography.metadata.copyWith(
                              fontSize: 8.5,
                              color: colors.textDim,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // ── Category rows cards
              ...[0, 1, 2].map((i) {
                final cat = _categories[i];
                final rowColor = i == 0 ? warningColor : colors.primary;
                final label = i == 0
                    ? context.l10n.onboardingCategoryFood
                    : i == 1
                        ? context.l10n.onboardingCategoryTransport
                        : context.l10n.onboardingCategoryEntertainment;

                return Opacity(
                  opacity: rowOpacities[i].value,
                  child: Transform.translate(
                    offset: Offset(0, rowSlides[i].value),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _buildCategoryRowCard(
                        context,
                        colors,
                        cat.icon,
                        label,
                        cat.percent,
                        rowColor,
                        i == 0 && _warningProgress.value > 0.5,
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              // ── Insight card
              Opacity(
                opacity: _insightOpacity.value,
                child: Transform.translate(
                  offset: Offset(0, _insightSlide.value),
                  child: _buildInsightCard(context, colors),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryRowCard(
    BuildContext context,
    MoniaryColors colors,
    IconData icon,
    String label,
    double percent,
    Color barColor,
    bool showWarning,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.outline.withValues(
            alpha: showWarning ? 0.8 : 0.4,
          ),
          width: showWarning ? 1.2 : 0.8,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: barColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 14, color: barColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10.5,
                        ),
                      ),
                    ),
                    if (showWarning)
                      Padding(
                        padding: const EdgeInsets.only(right: 4),
                        child: Icon(
                          Icons.warning_amber_rounded,
                          size: 11,
                          color: barColor,
                        ),
                      ),
                    Text(
                      '${(percent * 100).round()}%',
                      style: context.moniaryTypography.metadataStrong.copyWith(
                        fontSize: 9.5,
                        color: barColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 4,
                    backgroundColor: colors.textPrimary.withValues(alpha: 0.08),
                    valueColor: AlwaysStoppedAnimation<Color>(barColor),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInsightCard(BuildContext context, MoniaryColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.15),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: colors.textPrimary.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text('💡', style: const TextStyle(fontSize: 13)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              context.l10n.onboardingInsightText,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Camera bracket drawing helpers
// ---------------------------------------------------------------------------
enum _BracketCorner { topLeft, topRight, bottomLeft, bottomRight }

class _CornerBracket extends StatelessWidget {
  const _CornerBracket({
    required this.color,
    required this.size,
    required this.thickness,
    required this.corner,
  });

  final Color color;
  final double size;
  final double thickness;
  final _BracketCorner corner;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _BracketPainter(
        color: color,
        thickness: thickness,
        corner: corner,
      ),
    );
  }
}

class _BracketPainter extends CustomPainter {
  const _BracketPainter({
    required this.color,
    required this.thickness,
    required this.corner,
  });

  final Color color;
  final double thickness;
  final _BracketCorner corner;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thickness
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final w = size.width;
    final h = size.height;

    switch (corner) {
      case _BracketCorner.topLeft:
        canvas.drawPath(
          Path()
            ..moveTo(0, h)
            ..lineTo(0, 0)
            ..lineTo(w, 0),
          paint,
        );
      case _BracketCorner.topRight:
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(w, 0)
            ..lineTo(w, h),
          paint,
        );
      case _BracketCorner.bottomLeft:
        canvas.drawPath(
          Path()
            ..moveTo(0, 0)
            ..lineTo(0, h)
            ..lineTo(w, h),
          paint,
        );
      case _BracketCorner.bottomRight:
        canvas.drawPath(
          Path()
            ..moveTo(w, 0)
            ..lineTo(w, h)
            ..lineTo(0, h),
          paint,
        );
    }
  }

  @override
  bool shouldRepaint(covariant _BracketPainter old) =>
      old.color != color || old.corner != corner;
}
