import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../../l10n/l10n_extension.dart';
import '../../calendar/presentation/month/calendar_screen.dart';
import '../application/assistant_controller.dart';
import 'assistant_permission_screen.dart';

class AssistantIntroScreen extends ConsumerStatefulWidget {
  const AssistantIntroScreen({super.key});

  static const routePath = '/assistant/intro';

  @override
  ConsumerState<AssistantIntroScreen> createState() =>
      _AssistantIntroScreenState();
}

class _AssistantIntroScreenState extends ConsumerState<AssistantIntroScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slides = [
      (
        icon: Icons.chat_bubble_outline,
        title: context.l10n.assistantIntroTitle1,
        body: context.l10n.assistantIntroBody1,
        color: context.moniaryColors.primary,
      ),
      (
        icon: Icons.trending_up,
        title: context.l10n.assistantIntroTitle2,
        body: context.l10n.assistantIntroBody2,
        color: context.moniaryColors.warning,
      ),
      (
        icon: Icons.route_outlined,
        title: context.l10n.assistantIntroTitle3,
        body: context.l10n.assistantIntroBody3,
        color: context.moniaryColors.success,
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 24, 0),
              child: Row(
                children: [
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      context,
                    ).backButtonTooltip,
                    onPressed: _goBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _finish,
                    child: Text(context.l10n.assistantIntroSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (value) => setState(() => _page = value),
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  return _IntroSlide(
                    icon: slide.icon,
                    title: slide.title,
                    body: slide.body,
                    color: slide.color,
                    index: index,
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var index = 0; index < slides.length; index++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: index == _page ? 28 : 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: index == _page
                                ? context.moniaryColors.primary
                                : context.moniaryColors.outline,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: _finishing
                        ? null
                        : () {
                            if (_page == slides.length - 1) {
                              _finish();
                            } else {
                              _controller.animateToPage(
                                _page + 1,
                                duration: const Duration(milliseconds: 320),
                                curve: Curves.easeOutCubic,
                              );
                            }
                          },
                    child: Text(
                      _page == slides.length - 1
                          ? context.l10n.assistantIntroStart
                          : context.l10n.assistantIntroNext,
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

  void _goBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(CalendarScreen.routePath);
  }

  Future<void> _finish() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      final access = await ref.read(assistantAccessProvider.future);
      await ref
          .read(assistantAccessControllerProvider.notifier)
          .save(access.copyWith(introSeen: true));
      if (mounted) context.go(AssistantPermissionScreen.routePath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.errorGeneric)));
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }
}

class _IntroSlide extends StatelessWidget {
  const _IntroSlide({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.index,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 16, 28, 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Transform.rotate(
            angle: index.isEven ? -0.06 : 0.06,
            child: Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(34),
                border: Border.all(color: color.withValues(alpha: 0.35)),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(8, 10),
                  ),
                ],
              ),
              child: Icon(icon, size: 48, color: color),
            ),
          ),
          const SizedBox(height: 42),
          Text(title, style: context.moniaryTypography.displayLarge),
          const SizedBox(height: 16),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.6),
          ),
        ],
      ),
    );
  }
}
