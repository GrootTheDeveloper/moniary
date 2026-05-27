import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_theme.dart';
import '../../auth/presentation/login_screen.dart';
import '../application/account_actions_controller.dart';
import 'about_moniary_screen.dart';
import 'data_deletion_policy_screen.dart';
import 'data_retention_policy_screen.dart';
import 'data_safety_screen.dart';
import 'data_transparency_screen.dart';
import 'deletion_request_screen.dart';
import 'export_data_screen.dart';
import 'export_history_screen.dart';
import 'financial_disclaimer_screen.dart';
import 'help_center_screen.dart';
import 'legal_contact_screen.dart';
import 'permission_rationale_screen.dart';
import 'policy_acceptance_notice_screen.dart';
import 'policy_changelog_screen.dart';
import 'privacy_contact_screen.dart';
import 'privacy_policy_screen.dart';
import 'store_compliance_checklist_screen.dart';
import 'terms_of_use_screen.dart';
import 'third_party_services_screen.dart';
import 'trust_safety_screen.dart';
import 'user_rights_summary_screen.dart';
import 'widgets/delete_account_dialog.dart';

class PrivacyCenterScreen extends ConsumerWidget {
  const PrivacyCenterScreen({super.key});

  static const routePath = '/privacy-center';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(accountActionsControllerProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error.toString())));
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
                  icon: Icons.help_outline_rounded,
                  title: 'Trung tâm trợ giúp',
                  subtitle:
                      'Tìm hướng dẫn về privacy, tài khoản, export dữ liệu và cách liên hệ hỗ trợ.',
                  onTap: () => context.push(HelpCenterScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Giới thiệu Moniary',
                  subtitle:
                      'Xem mục đích app, định hướng dữ liệu và trạng thái MVP trước khi phát hành.',
                  onTap: () => context.push(AboutMoniaryScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.privacy_tip_outlined,
                  title: 'Chính sách bảo mật',
                  subtitle:
                      'Xem cách Moniary xử lý dữ liệu cá nhân, tài chính và ảnh giao dịch.',
                  onTap: () => context.push(PrivacyPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.gavel_outlined,
                  title: 'Điều khoản sử dụng',
                  subtitle:
                      'Xem phạm vi sử dụng, trách nhiệm người dùng và giới hạn của phiên bản MVP.',
                  onTap: () => context.push(TermsOfUseScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.inventory_2_outlined,
                  title: 'Chính sách lưu giữ dữ liệu',
                  subtitle:
                      'Xem dữ liệu nào được lưu trên cloud, dữ liệu nào nằm cục bộ và cách xử lý sau khi xóa tài khoản.',
                  onTap: () =>
                      context.push(DataRetentionPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.hub_outlined,
                  title: 'Dịch vụ bên thứ ba',
                  subtitle:
                      'Xem app đang dùng Supabase, Flutter/package và bộ nhớ thiết bị như thế nào.',
                  onTap: () => context.push(ThirdPartyServicesScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.fact_check_outlined,
                  title: 'Checklist phát hành',
                  subtitle:
                      'Rà soát các mục privacy, data export, xóa tài khoản và contact trước khi lên Store.',
                  onTap: () =>
                      context.push(StoreComplianceChecklistScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.health_and_safety_outlined,
                  title: 'Tin cậy & an toàn',
                  subtitle:
                      'Xem ghi chú về giới hạn tư vấn tài chính, dữ liệu người dùng và chia sẻ file.',
                  onTap: () => context.push(TrustSafetyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.account_balance_outlined,
                  title: 'Miễn trừ tài chính',
                  subtitle:
                      'Xem giới hạn trách nhiệm: app không phải tư vấn đầu tư, thuế, kế toán hoặc pháp lý.',
                  onTap: () =>
                      context.push(FinancialDisclaimerScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.manage_history_outlined,
                  title: 'Lịch sử chính sách',
                  subtitle:
                      'Xem các mốc cập nhật privacy, legal và store readiness trong app.',
                  onTap: () => context.push(PolicyChangelogScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.assignment_ind_outlined,
                  title: 'Quyền dữ liệu của người dùng',
                  subtitle:
                      'Tóm tắt quyền xem dữ liệu, xuất dữ liệu, yêu cầu sửa/xóa và liên hệ privacy.',
                  onTap: () => context.push(UserRightsSummaryScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.verified_outlined,
                  title: 'Thông báo đồng ý chính sách',
                  subtitle:
                      'Giải thích rằng việc tiếp tục sử dụng app áp dụng theo chính sách và điều khoản hiện tại.',
                  onTap: () =>
                      context.push(PolicyAcceptanceNoticeScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.contact_mail_outlined,
                  title: 'Liên hệ pháp lý',
                  subtitle:
                      'Xem và copy email privacy, support và legal dùng cho phát hành Store.',
                  onTap: () => context.push(LegalContactScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.verified_user_outlined,
                  title: 'Data Safety',
                  subtitle:
                      'Tóm tắt các nhóm dữ liệu được thu thập hoặc không thu thập trong MVP.',
                  onTap: () => context.push(DataSafetyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.dataset_outlined,
                  title: 'Dữ liệu của tôi',
                  subtitle:
                      'Xem nhanh app đang lưu bao nhiêu dữ liệu trong tài khoản này.',
                  onTap: () => context.push(DataTransparencyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Quyền truy cập',
                  subtitle:
                      'Giải thích lý do Moniary dùng hoặc không dùng từng quyền Android.',
                  onTap: () =>
                      context.push(PermissionRationaleScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.file_download_outlined,
                  title: 'Xuất dữ liệu của tôi',
                  subtitle:
                      'Chọn định dạng file và tạo bản sao dữ liệu cá nhân.',
                  onTap: () => context.push(ExportDataScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.history_rounded,
                  title: 'Lịch sử export',
                  subtitle:
                      'Xem các file CSV, Excel hoặc PDF đã tạo từ tài khoản này.',
                  onTap: () => context.push(ExportHistoryScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'Xóa tài khoản',
                  subtitle:
                      'Xóa hồ sơ, ví, danh mục, giao dịch và ảnh giao dịch đã lưu.',
                  destructive: true,
                  onTap: state.isLoading
                      ? null
                      : () => _confirmDelete(context, ref),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.policy_outlined,
                  title: 'Chính sách xóa dữ liệu',
                  subtitle:
                      'Xem dữ liệu nào bị xóa và cách Moniary xử lý yêu cầu xóa.',
                  onTap: () => context.push(DataDeletionPolicyScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.description_outlined,
                  title: 'Yêu cầu xóa dữ liệu',
                  subtitle:
                      'Tạo file yêu cầu xóa thủ công nếu xóa trực tiếp không thành công.',
                  onTap: () => context.push(DeletionRequestScreen.routePath),
                ),
                const SizedBox(height: 12),
                _PrivacyActionTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Liên hệ quyền riêng tư',
                  subtitle:
                      'Kênh hỗ trợ cho yêu cầu dữ liệu, xóa dữ liệu hoặc câu hỏi privacy.',
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const DeleteAccountDialog(),
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
          Text(
            'Quyền riêng tư của bạn',
            style: Theme.of(context).textTheme.titleLarge,
          ),
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
