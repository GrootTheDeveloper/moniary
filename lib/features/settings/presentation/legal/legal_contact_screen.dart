import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/app_theme.dart';

class LegalContactScreen extends StatelessWidget {
  const LegalContactScreen({super.key});

  static const routePath = '/legal-contact';

  static const _privacyEmail = 'privacy@moniary.app';
  static const _supportEmail = 'support@moniary.app';
  static const _legalEmail = 'legal@moniary.app';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Liên hệ pháp lý')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _LegalHero(),
            const SizedBox(height: 16),
            _ContactCard(
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy',
              value: _privacyEmail,
              description:
                  'Yêu cầu dữ liệu cá nhân, xóa dữ liệu hoặc câu hỏi privacy.',
            ),
            _ContactCard(
              icon: Icons.support_agent_outlined,
              title: 'Support',
              value: _supportEmail,
              description:
                  'Hỗ trợ chung về app, file export hoặc thao tác người dùng.',
            ),
            _ContactCard(
              icon: Icons.gavel_outlined,
              title: 'Legal',
              value: _legalEmail,
              description:
                  'Vấn đề điều khoản, phát hành Store hoặc yêu cầu pháp lý.',
            ),
            const SizedBox(height: 4),
            FilledButton.icon(
              onPressed: () => _copyAll(context),
              icon: const Icon(Icons.content_copy_outlined),
              label: const Text('Copy tất cả liên hệ'),
            ),
          ],
        ),
      ),
    );
  }

  void _copyAll(BuildContext context) {
    Clipboard.setData(
      const ClipboardData(
        text:
            'Privacy: $_privacyEmail\nSupport: $_supportEmail\nLegal: $_legalEmail',
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Đã copy thông tin liên hệ.')));
  }
}

class _LegalHero extends StatelessWidget {
  const _LegalHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Text(
        'Các kênh liên hệ này giúp người dùng, reviewer hoặc team phát hành biết nơi gửi yêu cầu phù hợp.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String value;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.mint),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: () => _copy(context),
                icon: const Icon(Icons.copy_rounded),
                tooltip: 'Copy',
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 6),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  void _copy(BuildContext context) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Đã copy $value')));
  }
}
