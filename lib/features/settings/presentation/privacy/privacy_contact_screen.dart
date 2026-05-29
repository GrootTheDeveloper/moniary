import 'dart:io';
import '../../../../l10n/l10n_extension.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/account_actions_controller.dart';
import '../../domain/privacy_requests/privacy_request_history_entry.dart';
import '../../domain/privacy_requests/privacy_request_sla.dart';
import '../../domain/privacy_requests/privacy_request_template.dart';
import '../../domain/privacy_requests/privacy_request_type.dart';
import 'privacy_request_detail_screen.dart';

class PrivacyContactScreen extends ConsumerStatefulWidget {
  const PrivacyContactScreen({super.key});

  static const routePath = '/privacy-contact';

  @override
  ConsumerState<PrivacyContactScreen> createState() =>
      _PrivacyContactScreenState();
}

class _PrivacyContactScreenState extends ConsumerState<PrivacyContactScreen> {
  final _messageController = TextEditingController();
  String _requestTypeId = privacyRequestTypes.first.id;

  @override
  void initState() {
    super.initState();
    _applyTemplate(notify: false);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(accountActionsControllerProvider);
    final historyAsync = ref.watch(privacyRequestHistoryProvider);

    ref.listen(accountActionsControllerProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(userFriendlyMessage(error))));
        },
      );
    });

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.privacyContact)),
      body: SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
              children: [
                const _ContactHero(),
                const SizedBox(height: 16),
                const _ContactInfoTile(
                  icon: Icons.email_outlined,
                  title: 'Email hỗ trợ',
                  value: AppConstants.privacyEmail,
                  description:
                      'Dùng cho yêu cầu xóa dữ liệu, xuất dữ liệu hoặc câu hỏi về quyền riêng tư.',
                ),
                const _ContactInfoTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Thông tin cần gửi',
                  value: 'User ID hoặc email đăng nhập',
                  description:
                      'Không gửi mật khẩu, access token, ảnh hóa đơn nhạy cảm hoặc số tiền chi tiết qua email.',
                ),
                const _ContactInfoTile(
                  icon: Icons.schedule_outlined,
                  title: 'Thời gian phản hồi',
                  value: 'Trong vòng 7 ngày làm việc',
                  description:
                      'Team cần cập nhật thời gian thực tế trước khi phát hành production.',
                ),
                const SizedBox(height: 8),
                const _SupportShortcutsCard(),
                const SizedBox(height: 12),
                const _ResponseTimelineCard(),
                const SizedBox(height: 12),
                _PrivacyRequestHistorySection(historyAsync: historyAsync),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _requestTypeId,
                  decoration: const InputDecoration(labelText: 'Loại yêu cầu'),
                  items: privacyRequestTypes
                      .map(
                        (type) => DropdownMenuItem(
                          value: type.id,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      _requestTypeId = value;
                      _applyTemplate();
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  privacyRequestTypeById(_requestTypeId).description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _messageController,
                  minLines: 4,
                  maxLines: 6,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    labelText: 'Nội dung yêu cầu',
                    hintText: 'Mô tả ngắn điều bạn muốn team hỗ trợ.',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: _applyTemplate,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: Text(context.l10n.privacyUseTemplate),
                ),
                const SizedBox(height: 8),
                _RequestPreviewCard(
                  requestType: privacyRequestTypeById(_requestTypeId),
                  message: _messageController.text,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: state.isLoading ? null : _createPrivacyRequest,
                  icon: const Icon(Icons.mark_email_read_outlined),
                  label: Text(context.l10n.privacyCreateRequest),
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

  void _applyTemplate({bool notify = true}) {
    final template = privacyRequestTemplateFor(
      privacyRequestTypeById(_requestTypeId),
    );
    _messageController.text = template;
    _messageController.selection = TextSelection.collapsed(
      offset: _messageController.text.length,
    );
    if (notify && mounted) {
      setState(() {});
    }
  }

  Future<void> _createPrivacyRequest() async {
    final file = await ref
        .read(accountActionsControllerProvider.notifier)
        .createPrivacyRequest(
          requestType: privacyRequestTypeById(_requestTypeId).label,
          message: _messageController.text,
        );
    if (!mounted || file == null) {
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (context) => _PrivacyRequestDialog(file: file),
    );
  }
}

class _PrivacyRequestDialog extends StatelessWidget {
  const _PrivacyRequestDialog({required this.file});

  final File file;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.privacyRequestCreated),
      content: Text(
        'File yêu cầu đã được lưu tại:\n${file.path}',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
      actions: [
        TextButton(
          onPressed: () => context.pop(),
          child: Text(context.l10n.commonClose),
        ),
      ],
    );
  }
}

class _RequestPreviewCard extends StatelessWidget {
  const _RequestPreviewCard({required this.requestType, required this.message});

  final PrivacyRequestType requestType;
  final String message;

  @override
  Widget build(BuildContext context) {
    final cleanMessage = message.trim().isEmpty
        ? 'Chưa nhập nội dung yêu cầu.'
        : message.trim();

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
              const Icon(Icons.preview_outlined, color: AppTheme.mint),
              const SizedBox(width: 8),
              Text(
                'Xem trước yêu cầu',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(requestType.label, style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(cleanMessage, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _ResponseTimelineCard extends StatelessWidget {
  const _ResponseTimelineCard();

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.timeline_outlined, color: AppTheme.mint),
              const SizedBox(width: 8),
              Text(
                'Quy trình phản hồi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const _TimelineStep(
            label: 'Tạo request trong app',
            description: 'App tạo file JSON để bạn gửi cho kênh hỗ trợ.',
          ),
          const _TimelineStep(
            label: 'Gửi request thủ công',
            description: 'Gửi file qua email ${AppConstants.privacyEmail}.',
          ),
          _TimelineStep(
            label: 'Theo dõi phản hồi',
            description:
                'Mốc phản hồi dự kiến là $privacyRequestResponseBusinessDays ngày làm việc.',
          ),
        ],
      ),
    );
  }
}

class _SupportShortcutsCard extends StatelessWidget {
  const _SupportShortcutsCard();

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.contact_support_outlined, color: AppTheme.mint),
              const SizedBox(width: 8),
              Text(
                'Lối tắt hỗ trợ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Column(
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy(
                  context,
                  AppConstants.privacyEmail,
                  'Đã copy email support.',
                ),
                icon: const Icon(Icons.email_outlined),
                label: Text(context.l10n.privacyCopyEmail),
              ),
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: () => _copy(
                  context,
                  'Email: ${AppConstants.privacyEmail}\nChủ đề: Moniary privacy request\nĐính kèm file request JSON đã tạo trong app.',
                  'Đã copy hướng dẫn gửi request.',
                ),
                icon: const Icon(Icons.content_copy_outlined),
                label: Text(context.l10n.privacyCopyInstructions),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _copy(BuildContext context, String value, String message) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _TimelineStep extends StatelessWidget {
  const _TimelineStep({required this.label, required this.description});

  final String label;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppTheme.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacyRequestHistorySection extends StatelessWidget {
  const _PrivacyRequestHistorySection({required this.historyAsync});

  final AsyncValue<List<PrivacyRequestHistoryEntry>> historyAsync;

  @override
  Widget build(BuildContext context) {
    return historyAsync.when(
      data: (history) {
        if (history.isEmpty) {
          return const SizedBox.shrink();
        }

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
                  const Icon(Icons.history_rounded, color: AppTheme.mint),
                  const SizedBox(width: 8),
                  Text(
                    'Yêu cầu gần đây',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...history.take(3).map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PrivacyRequestHistoryTile(
                    entry: entry,
                    onTap: () => context.push(
                      PrivacyRequestDetailScreen.routePath,
                      extra: entry,
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
    );
  }
}

class _PrivacyRequestHistoryTile extends StatelessWidget {
  const _PrivacyRequestHistoryTile({required this.entry, required this.onTap});

  final PrivacyRequestHistoryEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final createdAt = DateFormat('dd/MM/yyyy HH:mm').format(entry.createdAt);
    final status = privacyRequestStatusById(entry.status);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppTheme.mint.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.description_outlined,
                color: AppTheme.mint,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.requestType,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdAt,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status.label,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: AppTheme.mint),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.mint),
          ],
        ),
      ),
    );
  }
}

class _ContactHero extends StatelessWidget {
  const _ContactHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceRaised,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.support_agent_rounded,
            color: AppTheme.mint,
            size: 34,
          ),
          const SizedBox(height: 12),
          Text(
            'Yêu cầu về dữ liệu cá nhân',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Nếu không thể xử lý trực tiếp trong app, người dùng có thể liên hệ team để yêu cầu hỗ trợ về dữ liệu.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ContactInfoTile extends StatelessWidget {
  const _ContactInfoTile({
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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.mint.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppTheme.mint, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
