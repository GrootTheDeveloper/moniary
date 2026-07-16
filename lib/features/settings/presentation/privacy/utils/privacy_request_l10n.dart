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
      case 'submitted':
        return context.l10n.privacyStatusSubmitted;
      case 'in_review':
        return context.l10n.privacyStatusInReview;
      case 'resolved':
        return context.l10n.privacyStatusResolved;
      case 'rejected':
        return context.l10n.privacyStatusRejected;
      default:
        return id;
    }
  }

  String description(BuildContext context) {
    switch (id) {
      case 'submitted':
        return context.l10n.privacyStatusSubmittedDesc;
      case 'in_review':
        return context.l10n.privacyStatusInReviewDesc;
      case 'resolved':
        return context.l10n.privacyStatusResolvedDesc;
      case 'rejected':
        return context.l10n.privacyStatusRejectedDesc;
      default:
        return id;
    }
  }
}
