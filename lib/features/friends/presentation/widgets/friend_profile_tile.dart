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
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: ClipOval(
          child: SupabaseImage(
            imagePath: profile.avatarPath,
            width: 44,
            height: 44,
            fallbackIcon: Icons.person_outline,
          ),
        ),
        title: Text(
          profile.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          subtitle?.trim().isNotEmpty == true
              ? subtitle!
              : profile.displayUsername,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: AppTheme.textSubtle),
        ),
        trailing: trailing,
      ),
    );
  }
}
