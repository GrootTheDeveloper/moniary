import 'package:flutter/material.dart';

import '../../../../app/app_theme.dart';
import '../../../../shared/widgets/supabase_image.dart';
import '../../domain/entities/friend_profile.dart';

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name, required this.colors});

  final String name;
  final MoniaryColors colors;

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();
    return Container(
      width: 48,
      height: 48,
      color: colors.primary.withValues(alpha: 0.14),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                ClipOval(
                  child: SupabaseImage(
                    imagePath: profile.avatarPath,
                    width: 48,
                    height: 48,
                    fallbackBuilder: (context) => _InitialAvatar(
                      name: profile.displayName,
                      colors: colors,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle?.trim().isNotEmpty == true
                            ? subtitle!
                            : profile.displayUsername,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.moniaryTypography.metadata.copyWith(
                          color: colors.textDim,
                        ),
                      ),
                    ],
                  ),
                ),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  Flexible(
                    flex: 0,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),
                      child: trailing!,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
