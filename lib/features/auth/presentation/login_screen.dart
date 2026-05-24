import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/placeholder_card.dart';
import '../application/auth_controller.dart';
import '../../calendar/presentation/calendar_screen.dart';

class LoginScreen extends ConsumerWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authAction = ref.watch(authControllerProvider);
    final hasSession = ref.watch(currentSessionProvider) != null;

    return Scaffold(
      appBar: AppBar(title: const Text(AppConstants.appName)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ghi chi tieu bang anh.',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Stage 0 da san sang: app shell, router va Riverpod root da duoc dung. Buoc tiep theo la ket noi Supabase va anonymous login.',
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              ),
              const SizedBox(height: 24),
              const PlaceholderCard(
                title: 'Trang thai hien tai',
                body:
                    'Day la man Login tam thoi de khoa luong Splash -> Login -> Calendar trong giai doan 0.',
              ),
              const SizedBox(height: 16),
              const PlaceholderCard(
                title: 'Supabase config',
                body:
                    'App da duoc noi voi Supabase project hien tai. Ban van co the override bang --dart-define khi can doi environment.',
              ),
              const SizedBox(height: 16),
              PlaceholderCard(
                title: 'Ket noi',
                body: hasSession
                    ? 'Da co session Supabase. Router se tu dua ban vao Calendar khi auth state hop le.'
                    : 'Chua co session. Nhan nut ben duoi de dang nhap anonymous tren Supabase.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: authAction.isLoading
                    ? null
                    : () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final router = GoRouter.of(context);

                        try {
                          await ref
                              .read(authControllerProvider.notifier)
                              .signInAnonymously();

                          if (!context.mounted) {
                            return;
                          }

                          router.go(CalendarScreen.routePath);
                        } catch (error) {
                          messenger.showSnackBar(
                            SnackBar(content: Text(error.toString())),
                          );
                        }
                      },
                child: Text(
                  authAction.isLoading
                      ? 'Dang ket noi Supabase...'
                      : 'Dang nhap anonymous',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
