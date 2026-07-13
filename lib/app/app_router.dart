import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'main_shell_screen.dart';
import '../l10n/l10n_extension.dart';
import '../core/preferences/preferences_providers.dart';
import '../core/supabase/supabase_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/assistant/presentation/assistant_conversation_screen.dart';
import '../features/assistant/presentation/assistant_home_screen.dart';
import '../features/assistant/presentation/assistant_intro_screen.dart';
import '../features/assistant/presentation/assistant_permission_screen.dart';
import '../features/assistant/presentation/assistant_question_catalog.dart';
import '../features/assistant/presentation/assistant_question_library_screen.dart';
import '../features/budgets/presentation/budget_category_detail_screen.dart';
import '../features/budgets/presentation/budget_screen.dart';
import '../features/calendar/presentation/month/calendar_screen.dart';
import '../features/friends/presentation/screens/add_friend_screen.dart';
import '../features/friends/presentation/screens/friend_invite_accept_screen.dart';
import '../features/friends/presentation/screens/friends_screen.dart';
import '../features/groups/presentation/groups_screen.dart';
import '../features/groups/presentation/screens/add_group_transaction_screen.dart';
import '../features/groups/presentation/screens/create_group_screen.dart';
import '../features/groups/presentation/screens/debt_settlement_screen.dart';
import '../features/groups/presentation/screens/group_detail_screen.dart';
import '../features/groups/presentation/screens/group_invite_accept_screen.dart';
import '../features/groups/presentation/screens/group_invitations_screen.dart';
import '../features/groups/presentation/screens/group_transaction_detail_screen.dart';
import '../features/groups/presentation/screens/invite_member_screen.dart';
import '../features/groups/presentation/screens/member_amount_input_screen.dart';
import '../features/journal/domain/journal_models.dart';
import '../features/journal/presentation/journal_collection_detail_screen.dart';
import '../features/journal/presentation/journal_collections_screen.dart';
import '../features/journal/presentation/journal_export_screen.dart';
import '../features/journal/presentation/monthly_recap_screen.dart';
import '../features/journal/presentation/recording_streak_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_setup_screen.dart';
import '../features/profile/presentation/timezone_picker_screen.dart';
import '../features/profile/presentation/profile_survey_screen.dart';
import '../features/scanning/presentation/ocr_review_screen.dart';
import '../features/scanning/presentation/scanning_screen.dart';
import '../features/settings/domain/export/export_history_entry.dart';
import '../features/settings/domain/privacy_requests/privacy_request_history_entry.dart';
import '../features/settings/presentation/store/about_moniary_screen.dart';
import '../features/settings/presentation/legal/data_deletion_policy_screen.dart';
import '../features/settings/presentation/legal/data_retention_policy_screen.dart';
import '../features/settings/presentation/privacy/data_safety_screen.dart';
import '../features/settings/presentation/privacy/data_transparency_screen.dart';
import '../features/settings/presentation/account/active_sessions_screen.dart';
import '../features/settings/presentation/account/delete_account_help_screen.dart';
import '../features/settings/presentation/account/delete_account_screen.dart';
import '../features/settings/presentation/export/export_data_screen.dart';
import '../features/settings/presentation/export/export_detail_screen.dart';
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
import '../features/settings/presentation/privacy/app_lock_screen.dart';
import '../features/settings/presentation/import/import_data_screen.dart';
import '../features/settings/presentation/import/import_history_screen.dart';
import '../features/settings/presentation/import/import_detail_screen.dart';
import '../features/settings/domain/import/import_history_entry.dart';
import '../features/settings/presentation/notifications/notification_settings_screen.dart';
import '../features/settings/application/privacy_controller.dart';
import '../features/settings/presentation/profile_screen.dart';
import '../features/settings/presentation/settings_home_screen.dart';
import '../features/statistics/presentation/statistics_view.dart';
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
import '../features/transactions/presentation/starred/starred_transactions_screen.dart';
import '../features/auth/application/account_status_controller.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStateStream = ref
      .watch(supabaseClientProvider)
      .auth
      .onAuthStateChange;
  final authRefreshListenable = GoRouterRefreshStream(authStateStream);

  ref.onDispose(authRefreshListenable.dispose);

  final router = GoRouter(
    initialLocation: SplashScreen.routePath,
    overridePlatformDefaultLocation: true,
    refreshListenable: authRefreshListenable,
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(context.l10n.routeNotFound),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/'),
              child: Text(context.l10n.routeGoBack),
            ),
          ],
        ),
      ),
    ),
    redirect: (context, state) {
      final session = ref.read(currentSessionProvider);
      final onboardingSeen = ref.read(onboardingSeenProvider);
      final privacyState = ref.read(privacyControllerProvider);
      final location = state.matchedLocation;

      const publicRoutes = {
        SplashScreen.routePath,
        OnboardingScreen.routePath,
        LoginScreen.routePath,
        ProfileSetupScreen.routePath,
        ProfileSurveyScreen.routePath,
      };

      // Handle account soft delete status
      final accountStatus = ref.read(accountStatusControllerProvider).value;
      if (session != null &&
          accountStatus?.isPending == true &&
          location != LoginScreen.routePath) {
        return LoginScreen.routePath;
      }

      if (!onboardingSeen &&
          location != SplashScreen.routePath &&
          location != OnboardingScreen.routePath) {
        return OnboardingScreen.routePath;
      }

      if (session == null && !publicRoutes.contains(location)) {
        return LoginScreen.routePath;
      }

      // App lock check
      if (privacyState.isAppLocked && !privacyState.isAuthenticated) {
        if (location != AppLockScreen.routePath &&
            !publicRoutes.contains(location)) {
          return AppLockScreen.routePath;
        }
      } else {
        if (location == AppLockScreen.routePath) {
          return CalendarScreen
              .routePath; // default fallback when authenticated
        }
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
        builder: (context, state) => ProfileSetupScreen(
          isEditMode: state.uri.queryParameters['mode'] == 'edit',
        ),
      ),
      GoRoute(
        path: TimezonePickerScreen.routePath,
        builder: (context, state) => const TimezonePickerScreen(),
      ),
      GoRoute(
        path: ProfileSurveyScreen.routePath,
        builder: (context, state) => const ProfileSurveyScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: CalendarScreen.routePath,
                builder: (context, state) => const CalendarScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: GroupsScreen.routePath,
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ProfileScreen.routePath,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AssistantHomeScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AssistantHomeScreen(),
        ),
      ),
      GoRoute(
        path: SettingsHomeScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const SettingsHomeScreen(),
        ),
      ),
      GoRoute(
        path: MonthlyRecapScreen.routePath,
        pageBuilder: (context, state) {
          final now = DateTime.now();
          final month =
              state.extra as DateTime? ?? DateTime(now.year, now.month);
          return buildFadeTransitionPage(
            state: state,
            child: MonthlyRecapScreen(month: month),
          );
        },
      ),
      GoRoute(
        path: JournalExportScreen.routePath,
        pageBuilder: (context, state) {
          final recap = state.extra as MonthlyRecap?;
          final now = DateTime.now();
          final child = recap == null
              ? MonthlyRecapScreen(month: DateTime(now.year, now.month))
              : JournalExportScreen(recap: recap);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: JournalCollectionsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const JournalCollectionsScreen(),
        ),
      ),
      GoRoute(
        path: JournalCollectionDetailScreen.routePath,
        pageBuilder: (context, state) {
          final id = state.extra as String?;
          final child = id == null
              ? const JournalCollectionsScreen()
              : JournalCollectionDetailScreen(collectionId: id);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: RecordingStreakScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const RecordingStreakScreen(),
        ),
      ),
      GoRoute(
        path: AssistantIntroScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AssistantIntroScreen(),
        ),
      ),
      GoRoute(
        path: AssistantPermissionScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AssistantPermissionScreen(),
        ),
      ),
      GoRoute(
        path: AssistantConversationScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: AssistantConversationScreen(
            launch: state.extra as AssistantLaunch?,
          ),
        ),
      ),
      GoRoute(
        path: AssistantQuestionLibraryScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AssistantQuestionLibraryScreen(),
        ),
      ),
      GoRoute(
        path: BudgetScreen.routePath,
        pageBuilder: (context, state) =>
            buildSlideTransitionPage(state: state, child: const BudgetScreen()),
      ),
      GoRoute(
        path: BudgetCategoryDetailScreen.routePath,
        pageBuilder: (context, state) {
          final args = state.extra as BudgetCategoryDetailArgs?;
          final child = args == null
              ? const BudgetScreen()
              : BudgetCategoryDetailScreen(args: args);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: ScanningScreen.routePath,
        pageBuilder: (context, state) {
          final extra = state.extra;
          final initialImagePath = extra is String ? extra : null;
          return buildSlideUpTransitionPage(
            state: state,
            child: ScanningScreen(initialImagePath: initialImagePath),
          );
        },
      ),
      GoRoute(
        path: OcrReviewScreen.routePath,
        pageBuilder: (context, state) {
          final args = state.extra as OcrReviewArgs?;
          final child = args == null
              ? const CalendarScreen()
              : OcrReviewScreen(args: args);
          return buildSlideUpTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: GroupDetailScreen.routePath,
        pageBuilder: (context, state) {
          final groupId = state.extra as String?;
          final child = groupId == null
              ? const GroupsScreen()
              : GroupDetailScreen(groupId: groupId);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: CreateGroupScreen.routePath,
        pageBuilder: (context, state) => buildSlideUpTransitionPage(
          state: state,
          child: const CreateGroupScreen(),
        ),
      ),
      GoRoute(
        path: InviteMemberScreen.routePath,
        pageBuilder: (context, state) {
          final groupId = state.extra as String?;
          final child = groupId == null
              ? const GroupsScreen()
              : InviteMemberScreen(groupId: groupId);
          return buildSlideUpTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: AddGroupTransactionScreen.routePath,
        pageBuilder: (context, state) {
          final args = state.extra as AddGroupTransactionArgs?;
          final child = args == null
              ? const GroupsScreen()
              : AddGroupTransactionScreen(args: args);
          return buildSlideUpTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: MemberAmountInputScreen.routePath,
        pageBuilder: (context, state) {
          final args = state.extra as MemberAmountInputArgs?;
          final child = args == null
              ? const GroupsScreen()
              : MemberAmountInputScreen(args: args);
          return buildSlideUpTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: DebtSettlementScreen.routePath,
        pageBuilder: (context, state) {
          final groupId = state.extra as String?;
          final child = groupId == null
              ? const GroupsScreen()
              : DebtSettlementScreen(groupId: groupId);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: GroupTransactionDetailScreen.routePath,
        pageBuilder: (context, state) {
          final transactionId = state.extra as String?;
          final child = transactionId == null
              ? const GroupsScreen()
              : GroupTransactionDetailScreen(transactionId: transactionId);
          return buildFadeTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: FriendsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const FriendsScreen(),
        ),
      ),
      GoRoute(
        path: AddFriendScreen.routePath,
        pageBuilder: (context, state) => buildSlideUpTransitionPage(
          state: state,
          child: const AddFriendScreen(),
        ),
      ),
      GoRoute(
        path: FriendInviteAcceptScreen.routePath,
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'];
          final child = token == null
              ? const FriendsScreen()
              : FriendInviteAcceptScreen(token: token);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: GroupInviteAcceptScreen.routePath,
        pageBuilder: (context, state) {
          final token = state.pathParameters['token'];
          final child = token == null
              ? const GroupsScreen()
              : GroupInviteAcceptScreen(token: token);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: GroupInvitationsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const GroupInvitationsScreen(),
        ),
      ),
      GoRoute(
        path: PrivacyCenterScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: PrivacyCenterScreen(
            group: PrivacyCenterGroup.fromKey(
              state.uri.queryParameters['group'],
            ),
          ),
        ),
      ),
      GoRoute(
        path: AppLockScreen.routePath,
        builder: (context, state) => const AppLockScreen(),
      ),
      GoRoute(
        path: HelpCenterScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const HelpCenterScreen(),
        ),
      ),
      GoRoute(
        path: PrivacyAccountFaqScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PrivacyAccountFaqScreen(),
        ),
      ),
      GoRoute(
        path: ExportTroubleshootingScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ExportTroubleshootingScreen(),
        ),
      ),
      GoRoute(
        path: DeleteAccountHelpScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DeleteAccountHelpScreen(),
        ),
      ),
      GoRoute(
        path: SupportRequestChecklistScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const SupportRequestChecklistScreen(),
        ),
      ),
      GoRoute(
        path: AboutMoniaryScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const AboutMoniaryScreen(),
        ),
      ),
      GoRoute(
        path: PrivacyContactScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PrivacyContactScreen(),
        ),
      ),
      GoRoute(
        path: PrivacyRequestDetailScreen.routePath,
        pageBuilder: (context, state) {
          final entry = state.extra as PrivacyRequestHistoryEntry?;
          final child = entry == null
              ? const PrivacyCenterScreen()
              : PrivacyRequestDetailScreen(entry: entry);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: DataSafetyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DataSafetyScreen(),
        ),
      ),
      GoRoute(
        path: DataTransparencyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DataTransparencyScreen(),
        ),
      ),
      GoRoute(
        path: DataDeletionPolicyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DataDeletionPolicyScreen(),
        ),
      ),
      GoRoute(
        path: DataRetentionPolicyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DataRetentionPolicyScreen(),
        ),
      ),
      GoRoute(
        path: ThirdPartyServicesScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ThirdPartyServicesScreen(),
        ),
      ),
      GoRoute(
        path: FinancialDisclaimerScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const FinancialDisclaimerScreen(),
        ),
      ),
      GoRoute(
        path: PolicyChangelogScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PolicyChangelogScreen(),
        ),
      ),
      GoRoute(
        path: UserRightsSummaryScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const UserRightsSummaryScreen(),
        ),
      ),
      GoRoute(
        path: PolicyAcceptanceNoticeScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PolicyAcceptanceNoticeScreen(),
        ),
      ),
      GoRoute(
        path: DeleteAccountScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const DeleteAccountScreen(),
        ),
      ),
      GoRoute(
        path: ActiveSessionsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ActiveSessionsScreen(),
        ),
      ),
      GoRoute(
        path: ExportDataScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ExportDataScreen(),
        ),
      ),
      GoRoute(
        path: NotificationSettingsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const NotificationSettingsScreen(),
        ),
      ),
      GoRoute(
        path: ImportDataScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ImportDataScreen(),
        ),
      ),
      GoRoute(
        path: ImportHistoryScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ImportHistoryScreen(),
        ),
      ),
      GoRoute(
        path: ImportHistoryScreen.detailRoutePath,
        pageBuilder: (context, state) {
          final entry = state.extra as ImportHistoryEntry?;
          final child = entry == null
              ? const ImportHistoryScreen()
              : ImportDetailScreen(entry: entry);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: ExportHistoryScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const ExportHistoryScreen(),
        ),
      ),
      GoRoute(
        path: ExportDetailScreen.routePath,
        pageBuilder: (context, state) {
          final entry = state.extra as ExportHistoryEntry?;
          final child = entry == null
              ? const ExportHistoryScreen()
              : ExportDetailScreen(entry: entry);
          return buildSlideTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: PermissionRationaleScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PermissionRationaleScreen(),
        ),
      ),
      GoRoute(
        path: PrivacyPolicyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const PrivacyPolicyScreen(),
        ),
      ),
      GoRoute(
        path: TermsOfUseScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const TermsOfUseScreen(),
        ),
      ),
      GoRoute(
        path: StoreComplianceChecklistScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const StoreComplianceChecklistScreen(),
        ),
      ),
      GoRoute(
        path: TrustSafetyScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const TrustSafetyScreen(),
        ),
      ),
      GoRoute(
        path: LegalContactScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const LegalContactScreen(),
        ),
      ),
      GoRoute(
        path: DayDetailScreen.routePath,
        pageBuilder: (context, state) {
          final date = state.extra as DateTime? ?? DateTime.now();
          return buildSlideTransitionPage(
            state: state,
            child: DayDetailScreen(date: date),
          );
        },
      ),
      GoRoute(
        path: TransactionDetailScreen.routePath,
        pageBuilder: (context, state) {
          final args = state.extra as TransactionDetailRouteArgs?;
          final child = args == null
              ? const CalendarScreen()
              : TransactionDetailScreen(args: args);
          return buildFadeTransitionPage(state: state, child: child);
        },
      ),
      GoRoute(
        path: CameraScreen.routePath,
        pageBuilder: (context, state) => buildSlideUpTransitionPage(
          state: state,
          child: const CameraScreen(),
        ),
      ),
      GoRoute(
        path: StarredTransactionsScreen.routePath,
        pageBuilder: (context, state) => buildSlideTransitionPage(
          state: state,
          child: const StarredTransactionsScreen(),
        ),
      ),
      GoRoute(
        path: '/transaction-form',
        pageBuilder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final imagePath = extra?['imagePath'] as String?;
          return buildSlideUpTransitionPage(
            state: state,
            child: TransactionFormScreen(initialImagePath: imagePath),
          );
        },
      ),
    ],
  );

  ref.listen(privacyControllerProvider, (previous, next) {
    if (previous?.isAuthenticated != next.isAuthenticated ||
        previous?.isAppLocked != next.isAppLocked) {
      router.refresh();
    }
  });

  ref.listen(accountStatusControllerProvider, (previous, next) {
    if (previous?.value?.isPending != next.value?.isPending) {
      router.refresh();
    }
  });

  return router;
});

CustomTransitionPage<void> buildSlideTransitionPage({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

CustomTransitionPage<T> buildSlideUpTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(0.0, 1.0);
      const end = Offset.zero;
      const curve = Curves.easeInOutCubic;
      final tween = Tween(
        begin: begin,
        end: end,
      ).chain(CurveTween(curve: curve));
      return SlideTransition(position: animation.drive(tween), child: child);
    },
  );
}

CustomTransitionPage<T> buildFadeTransitionPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 400),
    reverseTransitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.fastOutSlowIn).animate(animation),
        child: child,
      );
    },
  );
}

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
