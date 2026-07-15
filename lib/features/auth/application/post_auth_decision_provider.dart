import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/supabase/supabase_providers.dart';
import '../../../shared/utils/app_logger.dart';
import '../../profile/data/profile_repository.dart';
import '../../settings/domain/account/account_deletion_status.dart';
import 'account_status_controller.dart';

enum PostAuthDestination {
  noSession,
  profileSetup,
  profileSurvey,
  home,
  pendingDeletion,
}

class PostAuthDecision {
  const PostAuthDecision(this.destination, {this.deletionStatus});

  final PostAuthDestination destination;
  final AccountDeletionStatus? deletionStatus;
}

final postAuthDecisionProvider = FutureProvider<PostAuthDecision>((ref) async {
  final session = ref.watch(currentSessionProvider);
  // Use ref.read for repositories to avoid race conditions during rebuilds
  final profileRepo = ref.read(profileRepositoryProvider);

  if (session == null) {
    return const PostAuthDecision(PostAuthDestination.noSession);
  }

  if (!AppConstants.hasSupabaseConfig && session.user.id == 'mock-user-id') {
    return const PostAuthDecision(PostAuthDestination.home);
  }

  try {
    final deletionStatus = await ref.read(
      accountStatusControllerProvider.future,
    );
    if (deletionStatus.isPending) {
      return PostAuthDecision(
        PostAuthDestination.pendingDeletion,
        deletionStatus: deletionStatus,
      );
    }

    final profile = await profileRepo.fetchCurrentProfile();
    if (profile == null || profile.needsSetup) {
      return const PostAuthDecision(PostAuthDestination.profileSetup);
    }
    if (profile.needsSurvey) {
      return const PostAuthDecision(PostAuthDestination.profileSurvey);
    }
    return const PostAuthDecision(PostAuthDestination.home);
  } catch (e, st) {
    AppLogger.error('Post-auth decision calculation failed', e, st);
    rethrow;
  }
});
