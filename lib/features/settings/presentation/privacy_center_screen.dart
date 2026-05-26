import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../auth/presentation/login_screen.dart';
import '../application/account_actions_controller.dart';
import 'data_deletion_policy_screen.dart';
import 'data_safety_screen.dart';
import 'permission_rationale_screen.dart';
import 'privacy_contact_screen.dart';
import 'privacy_policy_screen.dart';

class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  static const routePath = '/privacy-center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm riêng tư')),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _PrivacyHero(),
                const SizedBox(height: 18),
                _PrivacyActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Chính sách bảo mật',
                  subtitle: 'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.',
                  onTap: () => context.push(PrivacyPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Data Safety',
                  subtitle: 'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong MVP.',
                  onTap: () => context.push(DataSafetyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Quyền truy cập',
                  subtitle: 'Giải thích lý do Moniary dùng hoặc không dùng từng quyền Android.',
                  onTap: () => context.push(PermissionRationaleScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.file_download_outlined,
                  title: 'Xuất dữ liệu của tôi',
                  subtitle: 'Tạo file CSV chứa toàn bộ giao dịch của tài khoản hiện tại.',
                  onTap: state.isLoading ? null : () => _exportCsv(context, ref),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Xóa tài khoản',
                  subtitle: 'Xóa hồ sơ, ví, danh mục, giao dịch và ảnh giao dịch đã lưu.',
                  destructive: true,
                  onTap: state.isLoading ? null : () => _confirmDelete(context, ref),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.policy_outlined,
                  title: 'Chính sách xóa dữ liệu',
                  subtitle: 'Xem dữ liệu nào bị xóa và cách Moniary xử lý yêu cầu xóa.',
                  onTap: () => context.push(DataDeletionPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Liên hệ quyền riêng tư',
                  subtitle: 'Kênh hỗ trợ cho yêu cầu dữ liệu, xóa dữ liệu hoặc câu hỏi privacy.',
                  onTap: () => context.push(PrivacyContactScreen.routePath),
                ),
              ],
            ),
            if (state.isLoading)
              const Positioned.fill(
                child: ColoredBox(
                  color: Color(0x66000000),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportCsv(BuildContext context, WidgetRef ref) async {
    final file = await ref.read(accountActionsControllerProvider.notifier).exportCsv();
    if (!context.mounted || file == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đã xuất CSV'),
        content: Text(
          'File đã được lưu tại:\n${file.path}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const _DeleteAccountDialog(),
    );

    if (confirmed != true) {
      return;
    }

    await ref.read(accountActionsControllerProvider.notifier).deleteAccount();
    if (context.mounted) {
      context.go(LoginScreen.routePath);
    }
  }
}

class _PrivacyHero extends StatelessWidget {
  const _PrivacyHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.shield_outlined, color: AppTheme.mint),
          ),
          const SizedBox(height: 14),
          Text('Quyền riêng tư của bạn', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Quản lý các thông tin về dữ liệu, quyền truy cập và lựa chọn bảo mật trong Moniary.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _PrivacyActionTile extends StatelessWidget {
  const _PrivacyActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppTheme.danger : AppTheme.mint;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: destructive ? AppTheme.danger : Colors.white,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(Icons.chevron_right_rounded, color: color),
          ],
        ),
      ),
    );
  }
}

class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canDelete = _controller.text.trim().toUpperCase() == 'XOA';
    return AlertDialog(
      title: const Text('Xóa tài khoản?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Thao tác này sẽ xóa hồ sơ, ví, danh mục, giao dịch và ảnh giao dịch của bạn. Hãy xuất CSV trước nếu cần giữ lại dữ liệu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _controller,
            decoration: const InputDecoration(labelText: 'Nhập XOA để xác nhận'),
            textCapitalization: TextCapitalization.characters,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: canDelete ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.danger),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}
