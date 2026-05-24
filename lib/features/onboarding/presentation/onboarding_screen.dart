import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../core/preferences/preferences_providers.dart';
import '../../../shared/widgets/aurora_background.dart';
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

  static const _pages = [
    (
      title1: 'Ghi chi tiêu',
      title2: 'bằng ảnh',
      subtitle: 'Nhanh gọn  •  Dễ nhớ  •  Không bỏ sót',
      caption: 'Lưu khoảnh khắc chi tiêu như một cuốn nhật ký mini.',
      icon: Icons.camera_alt_rounded,
      accent: AppTheme.amber,
    ),
    (
      title1: 'Xem lịch tháng',
      title2: 'trực quan',
      subtitle: 'Ảnh, tổng chi, bộ lọc và nhắc nhở trong một màn hình',
      caption: 'Mỗi ngày là một ô nhỏ, mỗi giao dịch là một kỷ niệm.',
      icon: Icons.calendar_month_rounded,
      accent: AppTheme.mint,
    ),
    (
      title1: 'Thống kê',
      title2: 'dễ hiểu',
      subtitle: 'Theo dõi thu chi và thói quen tiêu dùng không cần bảng biểu khó',
      caption: 'Moniary giúp bạn nhìn tiền theo ngữ cảnh sống thật.',
      icon: Icons.pie_chart_rounded,
      accent: AppTheme.pink,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_pageIndex];

    return Scaffold(
      body: AuroraBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _finish,
                    child: const Text('Bỏ qua'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  page.title1,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  page.title2,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppTheme.mint,
                      ),
                ),
                const SizedBox(height: 10),
                Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    onPageChanged: (index) => setState(() => _pageIndex = index),
                    itemCount: _pages.length,
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 320,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(32),
                              border: Border.all(color: AppTheme.outline),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Icon(Icons.chevron_left_rounded, color: Colors.white70),
                                    Text('Tháng 5', style: Theme.of(context).textTheme.titleMedium),
                                    const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _MockFeatureCard(icon: item.icon, accent: item.accent),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Text(
                            item.caption,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _pageIndex == index ? 18 : 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: _pageIndex == index ? AppTheme.mint : const Color(0xFF3A4A5E),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _pageIndex == _pages.length - 1 ? _finish : _nextPage,
                  child: Text(_pageIndex == _pages.length - 1 ? 'Tiếp tục' : 'Xem tiếp'),
                ),
              ],
            ),
          ),
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
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOut,
    );
  }
}

class _MockFeatureCard extends StatelessWidget {
  const _MockFeatureCard({required this.icon, required this.accent});

  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 340,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1824),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Stack(
        children: [
          Positioned(
            top: 22,
            left: 22,
            child: CircleAvatar(
              radius: 26,
              backgroundColor: accent,
              child: Icon(icon, color: Colors.white),
            ),
          ),
          Positioned(
            top: 86,
            left: 18,
            right: 18,
            child: Container(
              height: 190,
              decoration: BoxDecoration(
                color: const Color(0xFF152231),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Center(
                child: Icon(Icons.image_outlined, color: Colors.white24, size: 64),
              ),
            ),
          ),
          Positioned(
            bottom: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: const [
                _FeaturePill(icon: Icons.camera_alt_outlined, label: 'Chụp & lưu'),
                _FeaturePill(icon: Icons.today_outlined, label: 'Xem theo ngày'),
                _FeaturePill(icon: Icons.pie_chart_outline_rounded, label: 'Thống kê'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppTheme.surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.outline),
          ),
          child: Icon(icon, size: 22),
        ),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
