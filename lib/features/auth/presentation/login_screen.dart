import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/placeholder_card.dart';
import '../../calendar/presentation/calendar_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  static const routePath = '/login';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    'URL va anon key da duoc du tru trong AppConstants bang --dart-define, se duoc dung o giai doan 1.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => context.go(CalendarScreen.routePath),
                child: const Text('Di toi Calendar placeholder'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
