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

  final deletionStatus = await ref.refresh(
    accountStatusControllerProvider.future,
  );
  if (deletionStatus.isPending) {
    return PostAuthDecision(
      PostAuthDestination.pendingDeletion,
      deletionStatus: deletionStatus,
    );
  }

  final profile = await ref
      .read(profileRepositoryProvider)
      .fetchCurrentProfile();
  return PostAuthDecision(
    profile == null || profile.needsSetup
        ? PostAuthDestination.profileSetup
        : PostAuthDestination.home,
  );
});
