import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../shared/widgets/placeholder_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static const routePath = '/calendar';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
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
        children: const [
          PlaceholderCard(
            title: 'Month view placeholder',
            body:
                'Man hinh nay se tro thanh trung tam MVP: lich thang, thumbnail giao dich, tong chi thang va bo loc.',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
            title: 'Vertical slice tiep theo',
            body:
                'Giai doan 1 se them auth that, khoi tao user va route guard. Sau do moi hoan thien wallet/category/transaction.',
          ),
          SizedBox(height: 16),
          PlaceholderCard(
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
