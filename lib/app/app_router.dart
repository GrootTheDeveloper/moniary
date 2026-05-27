import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/preferences/preferences_providers.dart';
import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/calendar/presentation/month/calendar_screen.dart';
import '../features/groups/presentation/debt_summary_screen.dart';
import '../features/groups/presentation/group_detail_screen.dart';
import '../features/groups/presentation/group_expense_form_screen.dart';
import '../features/groups/presentation/groups_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/scanning/presentation/ocr_review_screen.dart';
import '../features/scanning/presentation/scanning_screen.dart';
import '../features/settings/domain/privacy_requests/privacy_request_history_entry.dart';
import '../features/settings/presentation/store/about_moniary_screen.dart';
import '../features/settings/presentation/legal/data_deletion_policy_screen.dart';
import '../features/settings/presentation/legal/data_retention_policy_screen.dart';
import '../features/settings/presentation/privacy/data_safety_screen.dart';
import '../features/settings/presentation/privacy/data_transparency_screen.dart';
import '../features/settings/presentation/account/delete_account_help_screen.dart';
import '../features/settings/presentation/account/deletion_request_screen.dart';
import '../features/settings/presentation/export/export_data_screen.dart';
import '../features/settings/presentation/export/export_history_screen.dart';
import '../features/settings/presentation/export/export_troubleshooting_screen.dart';
import '../features/settings/presentation/legal/financial_disclaimer_screen.dart';
import '../features/settings/presentation/support/help_center_screen.dart';
import '../features/settings/presentation/legal/legal_contact_screen.dart';
import '../features/settings/presentation/privacy/permission_rationale_screen.dart';
import '../features/settings/presentation/legal/policy_acceptance_notice_screen.dart';
import '../features/settings/presentation/legal/policy_changelog_screen.dart';
import '../features/settings/presentation/privacy/privacy_center_screen.dart';
import '../features/settings/presentation/privacy/privacy_account_faq_screen.dart';
import '../features/settings/presentation/privacy/privacy_contact_screen.dart';
import '../features/settings/presentation/privacy/privacy_policy_screen.dart';
import '../features/settings/presentation/privacy/privacy_request_detail_screen.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/settings/presentation/store/store_compliance_checklist_screen.dart';
import '../features/settings/presentation/support/support_request_checklist_screen.dart';
import '../features/settings/presentation/legal/terms_of_use_screen.dart';
import '../features/settings/presentation/legal/third_party_services_screen.dart';
import '../features/settings/presentation/store/trust_safety_screen.dart';
import '../features/settings/presentation/legal/user_rights_summary_screen.dart';
import '../features/splash/presentation/splash_screen.dart';
import '../features/transactions/presentation/camera/camera_screen.dart';
import '../features/transactions/presentation/detail/day_detail_screen.dart';
import '../features/transactions/presentation/detail/transaction_detail_screen.dart';
import '../features/transactions/presentation/form/transaction_form_sheet.dart';
import '../features/transactions/presentation/detail/transaction_route_args.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange;
  final authRefreshListenable = GoRouterRefreshStream(authStateStream);

  ref.onDispose(authRefreshListenable.dispose);

  return GoRouter(
    initialLocation: SplashScreen.routePath,
    refreshListenable: authRefreshListenable,
    redirect: (context, state) {
      final session = ref.read(currentSessionProvider);
      final onboardingSeen = ref.read(onboardingSeenProvider);
      final location = state.matchedLocation;

      const publicRoutes = {
        SplashScreen.routePath,
        OnboardingScreen.routePath,
        LoginScreen.routePath,
        ProfileSetupScreen.routePath,
      };

      if (!onboardingSeen &&
          location != SplashScreen.routePath &&
          location != OnboardingScreen.routePath) {
        return OnboardingScreen.routePath;
      }

      if (session == null && !publicRoutes.contains(location)) {
        return LoginScreen.routePath;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: SplashScreen.routePath,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: OnboardingScreen.routePath,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: LoginScreen.routePath,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: ProfileSetupScreen.routePath,
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: CalendarScreen.routePath,
        builder: (context, state) => const CalendarScreen(),
      ),
      GoRoute(
        path: ScanningScreen.routePath,
        builder: (context, state) => const ScanningScreen(),
      ),
      GoRoute(
        path: OcrReviewScreen.routePath,
        builder: (context, state) {
          final args = state.extra as OcrReviewArgs;
          return OcrReviewScreen(args: args);
        },
      ),
      GoRoute(
        path: GroupsScreen.routePath,
        builder: (context, state) => const GroupsScreen(),
      ),
      GoRoute(
        path: GroupDetailScreen.routePath,
        builder: (context, state) {
          return GroupDetailScreen(groupId: state.extra as String);
        },
      ),
      GoRoute(
        path: GroupExpenseFormScreen.routePath,
        builder: (context, state) {
          return GroupExpenseFormScreen(
            args: state.extra as GroupExpenseFormArgs,
          );
        },
      ),
      GoRoute(
        path: DebtSummaryScreen.routePath,
        builder: (context, state) {
          return DebtSummaryScreen(groupId: state.extra as String);
        },
      ),
      GoRoute(
        path: ProfileScreen.routePath,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: PrivacyCenterScreen.routePath,
        builder: (context, state) => const PrivacyCenterScreen(),
      ),
      GoRoute(
        path: HelpCenterScreen.routePath,
        builder: (context, state) => const HelpCenterScreen(),
      ),
      GoRoute(
        path: PrivacyAccountFaqScreen.routePath,
        builder: (context, state) => const PrivacyAccountFaqScreen(),
      ),
      GoRoute(
        path: ExportTroubleshootingScreen.routePath,
        builder: (context, state) => const ExportTroubleshootingScreen(),
      ),
      GoRoute(
        path: DeleteAccountHelpScreen.routePath,
        builder: (context, state) => const DeleteAccountHelpScreen(),
      ),
      GoRoute(
        path: SupportRequestChecklistScreen.routePath,
        builder: (context, state) => const SupportRequestChecklistScreen(),
      ),
      GoRoute(
        path: AboutMoniaryScreen.routePath,
        builder: (context, state) => const AboutMoniaryScreen(),
      ),
      GoRoute(
        path: PrivacyContactScreen.routePath,
        builder: (context, state) => const PrivacyContactScreen(),
      ),
      GoRoute(
        path: PrivacyRequestDetailScreen.routePath,
        builder: (context, state) {
          final entry = state.extra as PrivacyRequestHistoryEntry;
          return PrivacyRequestDetailScreen(entry: entry);
        },
      ),
      GoRoute(
        path: DataSafetyScreen.routePath,
        builder: (context, state) => const DataSafetyScreen(),
      ),
      GoRoute(
        path: DataTransparencyScreen.routePath,
        builder: (context, state) => const DataTransparencyScreen(),
      ),
      GoRoute(
        path: DataDeletionPolicyScreen.routePath,
        builder: (context, state) => const DataDeletionPolicyScreen(),
      ),
      GoRoute(
        path: DataRetentionPolicyScreen.routePath,
        builder: (context, state) => const DataRetentionPolicyScreen(),
      ),
      GoRoute(
        path: ThirdPartyServicesScreen.routePath,
        builder: (context, state) => const ThirdPartyServicesScreen(),
      ),
      GoRoute(
        path: FinancialDisclaimerScreen.routePath,
        builder: (context, state) => const FinancialDisclaimerScreen(),
      ),
      GoRoute(
        path: PolicyChangelogScreen.routePath,
        builder: (context, state) => const PolicyChangelogScreen(),
      ),
      GoRoute(
        path: UserRightsSummaryScreen.routePath,
        builder: (context, state) => const UserRightsSummaryScreen(),
      ),
      GoRoute(
        path: PolicyAcceptanceNoticeScreen.routePath,
        builder: (context, state) => const PolicyAcceptanceNoticeScreen(),
      ),
      GoRoute(
        path: DeletionRequestScreen.routePath,
        builder: (context, state) => const DeletionRequestScreen(),
      ),
      GoRoute(
        path: ExportDataScreen.routePath,
        builder: (context, state) => const ExportDataScreen(),
      ),
      GoRoute(
        path: ExportHistoryScreen.routePath,
        builder: (context, state) => const ExportHistoryScreen(),
      ),
      GoRoute(
        path: PermissionRationaleScreen.routePath,
        builder: (context, state) => const PermissionRationaleScreen(),
      ),
      GoRoute(
        path: PrivacyPolicyScreen.routePath,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: TermsOfUseScreen.routePath,
        builder: (context, state) => const TermsOfUseScreen(),
      ),
      GoRoute(
        path: StoreComplianceChecklistScreen.routePath,
        builder: (context, state) => const StoreComplianceChecklistScreen(),
      ),
      GoRoute(
        path: TrustSafetyScreen.routePath,
        builder: (context, state) => const TrustSafetyScreen(),
      ),
      GoRoute(
        path: LegalContactScreen.routePath,
        builder: (context, state) => const LegalContactScreen(),
      ),
      GoRoute(
        path: DayDetailScreen.routePath,
        builder: (context, state) {
          final date = state.extra as DateTime? ?? DateTime.now();
          return DayDetailScreen(date: date);
        },
      ),
      GoRoute(
        path: TransactionDetailScreen.routePath,
        builder: (context, state) {
          final args = state.extra as TransactionDetailRouteArgs;
          return TransactionDetailScreen(args: args);
        },
      ),
      GoRoute(
        path: CameraScreen.routePath,
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: '/transaction-form',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final imagePath = extra?['imagePath'] as String?;
          return TransactionFormScreen(initialImagePath: imagePath);
        },
      ),
    ],
  );
});

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) {
      notifyListeners();
    });
  }

  late final StreamSubscription<dynamic> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
