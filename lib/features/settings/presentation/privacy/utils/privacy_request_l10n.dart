import 'package:flutter/material.dart';
import '../../../../../l10n/l10n_extension.dart';
import '../../../domain/privacy_requests/privacy_request_type.dart';
import '../../../domain/privacy_requests/privacy_request_history_entry.dart';

extension PrivacyRequestTypeL10n on PrivacyRequestType {
  String label(BuildContext context) {
    switch (id) {
      case 'data_access':
        return context.l10n.privacyReqDataAccess;
      case 'data_export_help':
        return context.l10n.privacyReqExportHelp;
      case 'data_correction':
        return context.l10n.privacyReqCorrection;
      case 'data_deletion':
        return context.l10n.privacyReqDeletion;
      case 'privacy_complaint':
        return context.l10n.privacyReqComplaint;
      default:
        return id;
    }
  }

  String description(BuildContext context) {
    switch (id) {
      case 'data_access':
        return context.l10n.privacyReqDataAccessDesc;
      case 'data_export_help':
        return context.l10n.privacyReqExportHelpDesc;
      case 'data_correction':
        return context.l10n.privacyReqCorrectionDesc;
      case 'data_deletion':
        return context.l10n.privacyReqDeletionDesc;
      case 'privacy_complaint':
        return context.l10n.privacyReqComplaintDesc;
      default:
        return id;
    }
  }

  String template(BuildContext context) {
    switch (id) {
      case 'data_access':
        return context.l10n.privacyTplDataAccess;
      case 'data_export_help':
        return context.l10n.privacyTplExportHelp;
      case 'data_correction':
        return context.l10n.privacyTplCorrection;
      case 'data_deletion':
        return context.l10n.privacyTplDeletion;
      case 'privacy_complaint':
        return context.l10n.privacyTplComplaint;
      default:
        return context.l10n.privacyTplDefault;
    }
  }
}

extension PrivacyRequestStatusOptionL10n on PrivacyRequestStatusOption {
  String label(BuildContext context) {
    switch (id) {
      case 'ready_to_send':
        return context.l10n.privacyStatusReady;
      case 'sent_manually':
        return context.l10n.privacyStatusSent;
      case 'resolved':
        return context.l10n.privacyStatusResolved;
      default:
        return id;
    }
  }

  String description(BuildContext context) {
    switch (id) {
      case 'ready_to_send':
        return context.l10n.privacyStatusReadyDesc;
      case 'sent_manually':
        return context.l10n.privacyStatusSentDesc;
      case 'resolved':
        return context.l10n.privacyStatusResolvedDesc;
      default:
        return id;
    }
  }
}
