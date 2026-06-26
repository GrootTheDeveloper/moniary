import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../app/app_theme.dart';
import '../../../../core/supabase/supabase_providers.dart';
import '../../../../l10n/l10n_extension.dart';
import '../../../../shared/utils/app_logger.dart';
import '../../../../shared/utils/error_helpers.dart';
import '../../application/account/active_sessions_controller.dart';
import '../../domain/account/active_session.dart';

class ActiveSessionsScreen extends ConsumerWidget {
  const ActiveSessionsScreen({super.key});

  static const routePath = '/active-sessions';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(activeSessionsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.activeSessionsTitle)),
      body: state.when(
        data: (sessions) {
          if (sessions.isEmpty) {
            return Center(child: Text(context.l10n.activeSessionsEmpty));
          }
          return RefreshIndicator(
            onRefresh: () =>
                ref.refresh(activeSessionsControllerProvider.future),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: sessions.length,
              itemBuilder: (context, index) {
                final session = sessions[index];
                return _SessionTile(session: session);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) {
          AppLogger.error('Failed to load active sessions', error, stack);
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.l10n.activeSessionsError(
                    userFriendlyMessage(context, error),
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.refresh(activeSessionsControllerProvider.future),
                  child: Text(context.l10n.commonRetry),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SessionTile extends ConsumerWidget {
  const _SessionTile({required this.session});

  final ActiveSession session;

  String _parseDeviceName(String? userAgent, BuildContext context) {
    if (userAgent == null || userAgent.isEmpty) {
      return context.l10n.activeSessionsUnknownDevice;
    }

    final ua = userAgent.toLowerCase();

    // Parse OS
    String os = '';
    if (ua.contains('iphone')) {
      os = 'iPhone';
    } else if (ua.contains('ipad')) {
      os = 'iPad';
    } else if (ua.contains('mac os')) {
      os = 'macOS';
    } else if (ua.contains('windows')) {
      os = 'Windows';
    } else if (ua.contains('android')) {
      os = 'Android';
    } else if (ua.contains('linux')) {
      os = 'Linux';
    } else {
      os = context.l10n.activeSessionsOtherOs;
    }

    // Parse Browser/App
    String browser = '';
    if (ua.contains('moniary') || ua.contains('dart')) {
      browser = 'Moniary App';
    } else if (ua.contains('edg/')) {
      browser = 'Edge';
    } else if (ua.contains('chrome/') && !ua.contains('edg/')) {
      browser = 'Chrome';
    } else if (ua.contains('safari/') && !ua.contains('chrome/')) {
      browser = 'Safari';
    } else if (ua.contains('firefox/')) {
      browser = 'Firefox';
    } else {
      browser = context.l10n.activeSessionsOtherBrowser;
    }

    return context.l10n.activeSessionsDeviceOn(browser, os);
  }

  IconData _getDeviceIcon(String? userAgent) {
    if (userAgent == null) {
      return Icons.device_unknown;
    }
    final ua = userAgent.toLowerCase();
    if (ua.contains('iphone') || ua.contains('android')) {
      return Icons.phone_android;
    }
    if (ua.contains('ipad')) {
      return Icons.tablet_mac;
    }
    return Icons.computer;
  }

  String? _getCurrentSessionId(Session? session) {
    if (session == null) return null;
    try {
      final parts = session.accessToken.split('.');
      if (parts.length != 3) return null;
      var normalized = parts[1];
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final payload = utf8.decode(base64Url.decode(normalized));
      final data = jsonDecode(payload) as Map<String, dynamic>;
      return data['session_id'] as String?;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSession = ref.watch(currentSessionProvider);
    final currentSessionId = _getCurrentSessionId(currentSession);
    final isCurrent = currentSessionId == session.id;

    final deviceName = _parseDeviceName(session.userAgent, context);
    final icon = _getDeviceIcon(session.userAgent);

    final lastActive = DateFormat('dd/MM/yyyy HH:mm').format(session.updatedAt);
    final createdAt = DateFormat('dd/MM/yyyy').format(session.createdAt);

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(icon, color: Theme.of(context).colorScheme.primary),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              deviceName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (isCurrent)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.l10n.activeSessionsThisDevice,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
              ),
            ),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.l10n.activeSessionsFirstLogin(createdAt)),
            Text(context.l10n.activeSessionsLastActive(lastActive)),
            if (session.ip != null && session.ip!.isNotEmpty)
              Text(context.l10n.activeSessionsIp(session.ip!)),
          ],
        ),
      ),
      trailing: isCurrent
          ? null
          : IconButton(
              icon: const Icon(Icons.logout, color: AppTheme.danger),
              onPressed: () => _showRevokeDialog(context, ref),
              tooltip: context.l10n.activeSessionsRevokeTooltip,
            ),
      isThreeLine: true,
    );
  }

  void _showRevokeDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.activeSessionsRevokeTitle),
          content: Text(context.l10n.activeSessionsRevokeContent),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.commonCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref
                    .read(activeSessionsControllerProvider.notifier)
                    .revokeSession(session.id);
              },
              child: Text(context.l10n.activeSessionsRevokeConfirm),
            ),
          ],
        );
      },
    );
  }
}
