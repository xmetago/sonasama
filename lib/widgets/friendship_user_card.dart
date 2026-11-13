import 'package:flutter/material.dart';

import '../utils/app_theme.dart';

/// Arkadaş listesindeki kullanıcı satırı. Aksiyonlar dışarıdan gelir.
class FriendshipUserCard extends StatelessWidget {
  const FriendshipUserCard({
    super.key,
    required this.avatar,
    required this.judgeName,
    required this.categoryBadge,
    required this.onOpenChat,
    required this.scoreButton,
    required this.removeButton,
    this.moreButton,
    this.footer,
  });

  final Widget avatar;
  final String judgeName;
  final Widget categoryBadge;
  final VoidCallback onOpenChat;
  final Widget scoreButton;
  final Widget removeButton;
  final Widget? moreButton;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: AppTheme.cardDecoration(borderRadius: 14, bordered: true),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                avatar,
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: onOpenChat,
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          judgeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTheme.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        categoryBadge,
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                scoreButton,
                const SizedBox(width: 4),
                removeButton,
                if (moreButton != null) ...[
                  const SizedBox(width: 4),
                  moreButton!,
                ],
              ],
            ),
            if (footer != null) footer!,
          ],
        ),
      ),
    );
  }
}
