import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../domain/entities/friend_profile.dart';

class FriendProfileTile extends StatelessWidget {
  const FriendProfileTile({
    required this.profile,
    this.trailing,
    this.subtitle,
    this.onTap,
    super.key,
  });

  final FriendProfile profile;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.moniaryColors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colors.outline),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        leading: ClipOval(
          child: SupabaseImage(
            imagePath: profile.avatarPath,
            width: 48,
            height: 48,
            fallbackIcon: Icons.person_outline,
          ),
        ),
        title: Text(
          profile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(
          subtitle?.trim().isNotEmpty == true
              ? subtitle!
              : profile.displayUsername,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.moniaryTypography.metadata.copyWith(
            color: colors.textDim,
          ),
        ),
        trailing: trailing,
      ),
    );
  }
}
