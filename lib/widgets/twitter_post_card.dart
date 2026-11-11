import 'dart:io';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../services/hive_database_service.dart';
import '../utils/map_safety.dart';
import 'twitter_feed_poll_section.dart';

/// Twitter/X benzeri post kartı widget'ı
class TwitterPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onRetweet;
  final VoidCallback? onComment;
  final VoidCallback? onShare;

  /// Anket oyu vb. sonrası feed listesini yenilemek için (PagedList önbelleği).
  final VoidCallback? onPostUpdated;

  /// Oy veren kullanıcı (giriş e-postası). Boşsa post yazarının e-postası kullanılır.
  final String? viewerEmail;

  const TwitterPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onRetweet,
    this.onComment,
    this.onShare,
    this.onPostUpdated,
    this.viewerEmail,
  });

  @override
  Widget build(BuildContext context) {
    // Güvenli tip dönüşümü
    final safePost = asStringDynamicMap(post);
    final payload = asStringDynamicMap(safePost['payload']);

    final content = payload['content'] ?? '';
    final userName = payload['userName'] ?? 'Bilinmeyen';
    final userEmail = payload['userEmail'] ?? '';
    final likes = payload['likes'] ?? 0;
    final retweets = payload['retweets'] ?? 0;
    final comments = payload['comments'] ?? 0;
    final userLiked = payload['userLiked'] ?? false;
    final userRetweeted = payload['userRetweeted'] ?? false;
    final media = payload['media'] as List<dynamic>?;
    final hasMedia = payload['hasMedia'] ?? false;
    final poll = asStringDynamicMap(payload['poll']);
    final hasPoll = payload['hasPoll'] ?? false;
    final postId = safePost['id']?.toString() ?? '';

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey, width: 0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Builder(
                  builder: (context) {
                    // Kullanıcının profil resmi URL'sini Hive'dan al
                    final settings = userEmail.isNotEmpty
                        ? HiveDatabaseService.getSettings(userEmail)
                        : null;
                    final profileImageUrl = settings?.profileImageUrl;

                    return CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey[200],
                      backgroundImage:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? NetworkImage(profileImageUrl)
                                  as ImageProvider<Object>
                              : null,
                      onBackgroundImageError:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? (exception, stackTrace) {
                                  // Resim yüklenemezse varsayılan ikonu göster
                                }
                              : null,
                      child:
                          profileImageUrl != null && profileImageUrl.isNotEmpty
                              ? null
                              : Icon(
                                  Icons.person,
                                  color: Colors.grey[600],
                                  size: 20,
                                ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      Text(
                        '@$userEmail',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {},
                  icon: Icon(
                    Icons.more_horiz,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // İçerik
            Text(
              content,
              style: const TextStyle(
                fontSize: 15,
                height: 1.3,
                color: Colors.black,
              ),
            ),

            // Medya gösterimi
            if (hasMedia && media != null && media.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildPostMediaGallery(media),
            ],

            // Anket gösterimi
            if (hasPoll && poll.isNotEmpty) ...[
              const SizedBox(height: 12),
              TwitterFeedPollSection(
                post: post,
                pollData: poll,
                postId: postId,
                viewerEmail: viewerEmail,
                onVoteSubmitted: onPostUpdated,
              ),
            ],

            const SizedBox(height: 12),

            // Alt butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: FontAwesomeIcons.comment,
                    count: comments,
                    onPressed: onComment,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: FontAwesomeIcons.retweet,
                    count: retweets,
                    isActive: userRetweeted,
                    activeColor: const Color(0xFF00BA7C),
                    onPressed: onRetweet,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: userLiked
                        ? FontAwesomeIcons.solidHeart
                        : FontAwesomeIcons.heart,
                    count: likes,
                    isActive: userLiked,
                    activeColor: const Color(0xFFE0245E),
                    onPressed: onLike,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: FontAwesomeIcons.shareFromSquare,
                    onPressed: onShare,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required FaIconData icon,
    int? count,
    bool isActive = false,
    Color activeColor = const Color(0xFF1DA1F2),
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(
              icon,
              size: 18,
              color: isActive ? activeColor : Colors.grey[600],
            ),
            if (count != null && count > 0) ...[
              const SizedBox(width: 6),
              Text(
                _formatCount(count),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isActive ? activeColor : Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  Widget _buildPostMediaGallery(List<dynamic> media) {
    if (media.isEmpty) return const SizedBox.shrink();

    // Tek resim
    if (media.length == 1) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          File(media[0]),
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 300,
              color: Colors.grey[200],
              child: Center(
                child: Icon(
                  Icons.image_not_supported,
                  color: Colors.grey[400],
                  size: 48,
                ),
              ),
            );
          },
        ),
      );
    }

    // 2 resim - yan yana
    if (media.length == 2) {
      return Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Image.file(
                File(media[0]),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 2),
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: Image.file(
                File(media[1]),
                height: 200,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ],
      );
    }

    // 3 veya 4 resim - grid
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: media.length > 4 ? 4 : media.length,
      itemBuilder: (context, index) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(index == 0
              ? 16
              : index == 1
                  ? 16
                  : index == 2
                      ? 16
                      : 16),
          child: Image.file(
            File(media[index]),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}
