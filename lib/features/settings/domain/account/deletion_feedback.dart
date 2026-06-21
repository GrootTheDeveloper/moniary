enum AccountDeletionReason {
  difficultToUse('difficult_to_use'),
  missingFeatures('missing_features'),
  technicalIssues('technical_issues'),
  privacyConcerns('privacy_concerns'),
  noLongerNeeded('no_longer_needed'),
  other('other');

  const AccountDeletionReason(this.id);

  final String id;
}

class DeletionFeedbackContext {
  const DeletionFeedbackContext({
    required this.appVersion,
    required this.platform,
    required this.locale,
  });

  final String appVersion;
  final String platform;
  final String locale;

  Map<String, String> toMap() => {
    'appVersion': appVersion,
    'platform': platform,
    'locale': locale,
  };
}
