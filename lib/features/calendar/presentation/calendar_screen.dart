import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/widgets/placeholder_card.dart';
import '../../auth/presentation/login_screen.dart';

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final userId = ref.watch(currentSessionProvider)?.user.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            onPressed: () async {
              await ref.read(supabaseClientProvider).auth.signOut();

              if (!context.mounted) {
                return;
              }

              context.go(LoginScreen.routePath);
            },
            icon: const Icon(Icons.logout),
            tooltip: 'Dang xuat',
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                AppConstants.defaultTimezone,
                style: theme.textTheme.labelMedium,
              ),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const PlaceholderCard(
            title: 'Month view placeholder',
            body:
                'Man hinh nay se tro thanh trung tam MVP: lich thang, thumbnail giao dich, tong chi thang va bo loc.',
          ),
          const SizedBox(height: 16),
          const PlaceholderCard(
            title: 'Vertical slice tiep theo',
            body:
                'Giai doan 1 se them auth that, khoi tao user va route guard. Sau do moi hoan thien wallet/category/transaction.',
          ),
          const SizedBox(height: 16),
          PlaceholderCard(
            title: 'Auth session',
            body: userId == null
                ? 'Chua doc duoc session hien tai.'
                : 'Supabase da ket noi. User hien tai: $userId',
          ),
          const SizedBox(height: 16),
          const PlaceholderCard(
            title: 'Structure da tao',
            body:
                'lib/app, lib/core, lib/features, lib/shared da san sang de mo rong theo module.',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        label: const Text('Them giao dich'),
        icon: const Icon(Icons.add_a_photo_outlined),
      ),
    );
  }
}
