import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../domain/store/app_release_info.dart';
import '../account/delete_account_help_screen.dart';
import '../export/export_data_screen.dart';
import '../export/export_troubleshooting_screen.dart';
import '../privacy/privacy_account_faq_screen.dart';
import '../privacy/privacy_contact_screen.dart';
import 'support_request_checklist_screen.dart';
import '../legal/user_rights_summary_screen.dart';
import '../widgets/settings_action_tile.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const routePath = '/help-center';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trung tâm trợ giúp')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: [
            const _HelpHero(),
            const SizedBox(height: 16),
            const _DiagnosticCard(),
            const SizedBox(height: 16),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.privacy_tip_outlined,
              title: 'Privacy & tài khoản',
              subtitle:
                  'Xem quyền dữ liệu, yêu cầu privacy và các lựa chọn liên quan tài khoản.',
              onTap: () => context.push(PrivacyAccountFaqScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.assignment_ind_outlined,
              title: 'Quyền dữ liệu',
              subtitle:
                  'Tóm tắt quyền xem, xuất, sửa/xóa dữ liệu và liên hệ privacy.',
              onTap: () => context.push(UserRightsSummaryScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.file_download_outlined,
              title: 'Xuất dữ liệu',
              subtitle:
                  'Xử lý khi export CSV, Excel hoặc PDF lỗi, trống hoặc không tìm thấy file.',
              onTap: () => context.push(ExportTroubleshootingScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.download_done_outlined,
              title: 'Tạo file export',
              subtitle: 'Mở luồng export khi cần tạo bản sao dữ liệu cá nhân.',
              onTap: () => context.push(ExportDataScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.support_agent_outlined,
              title: 'Liên hệ hỗ trợ',
              subtitle:
                  'Tạo request privacy hoặc copy thông tin liên hệ để gửi cho team hỗ trợ.',
              onTap: () => context.push(PrivacyContactScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.delete_forever_outlined,
              title: 'Xóa tài khoản',
              subtitle:
                  'Chuẩn bị trước khi xóa, hiểu dữ liệu bị ảnh hưởng và fallback khi có lỗi.',
              onTap: () => context.push(DeleteAccountHelpScreen.routePath),
            ),
            SettingsActionTile(
              margin: const EdgeInsets.only(bottom: 12),
              icon: Icons.fact_check_outlined,
              title: 'Checklist gửi hỗ trợ',
              subtitle:
                  'Chuẩn bị mô tả lỗi, file liên quan và diagnostic info trước khi gửi request.',
              onTap: () =>
                  context.push(SupportRequestChecklistScreen.routePath),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpHero extends StatelessWidget {
  const _HelpHero();

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
        'Tìm nhanh các hướng dẫn liên quan đến dữ liệu, quyền riêng tư, export và hỗ trợ tài khoản trong Moniary.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}

class _DiagnosticCard extends StatelessWidget {
  const _DiagnosticCard();

  @override
  Widget build(BuildContext context) {
    final diagnostic =
        'App: ${appReleaseInfo.name}\n'
        'Version: ${appReleaseInfo.version}\n'
        'Build: ${appReleaseInfo.buildNumber}\n'
        'Channel: ${appReleaseInfo.releaseChannel}\n'
        'Support: ${AppConstants.supportEmail}\n'
        'Privacy: ${AppConstants.privacyEmail}';

    return Container(
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
              const Icon(Icons.bug_report_outlined, color: AppTheme.mint),
              const SizedBox(width: 8),
              Text(
                'Thông tin gửi support',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Copy version, build và kênh liên hệ để gửi kèm khi báo lỗi.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: diagnostic));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đã copy thông tin support.')),
              );
            },
            icon: const Icon(Icons.content_copy_outlined),
            label: const Text('Copy diagnostic info'),
          ),
        ],
      ),
    );
  }
}
