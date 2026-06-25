import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/supabase/supabase_providers.dart';
import '../../profile/data/profile_repository.dart';
import '../../settings/domain/account/account_deletion_status.dart';
import 'account_status_controller.dart';

enum PostAuthDestination { noSession, profileSetup, home, pendingDeletion }

class PostAuthDecision {
  const PostAuthDecision(this.destination, {this.deletionStatus});

  final PostAuthDestination destination;
  final AccountDeletionStatus? deletionStatus;
}

final postAuthDecisionProvider = FutureProvider.autoDispose<PostAuthDecision>((
  ref,
) async {
  if (ref.read(currentSessionProvider) == null) {
    return const PostAuthDecision(PostAuthDestination.noSession);
  }

  // OAuth callbacks can restore a Supabase session before the app has created
  // the user's profile/default data. Load the profile first because
  // ProfileRepository can safely initialize a missing profile; then account
  // deletion status can read from `profiles` without turning a first-time
  // Google sign-in into a splash "Cannot connect" state.
  final profile = await ref
      .read(profileRepositoryProvider)
      .fetchCurrentProfile();

  final deletionStatus = await ref.refresh(
    accountStatusControllerProvider.future,
  );
  if (deletionStatus.isPending) {
    return PostAuthDecision(
      PostAuthDestination.pendingDeletion,
      deletionStatus: deletionStatus,
    );
  }

  return PostAuthDecision(
    profile == null || profile.needsSetup
        ? PostAuthDestination.profileSetup
        : PostAuthDestination.home,
  );
});
