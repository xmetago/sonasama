import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/dava_provider.dart';
import '../services/hive_database_service.dart';
import '../utils/map_safety.dart';

/// Twitter/X benzeri post paylaşım widget'ı
class TwitterPostComposer extends StatefulWidget {
  final String? userEmail;
  
  const TwitterPostComposer({super.key, this.userEmail});

  @override
  State<TwitterPostComposer> createState() => _TwitterPostComposerState();
}

class _TwitterPostComposerState extends State<TwitterPostComposer> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isExpanded = false;
  List<XFile> _selectedMedia = [];
  Map<String, dynamic>? _pollData;
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        children: [
          // Ana post yazma alanı
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profil resmi
                Builder(
                  builder: (context) {
                    // Kullanıcının profil resmi URL'sini Hive'dan al
                    final settings = widget.userEmail != null && widget.userEmail!.isNotEmpty 
                        ? HiveDatabaseService.getSettings(widget.userEmail!)
                        : null;
                    final profileImageUrl = settings?.profileImageUrl;
                    
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                          : null,
                      onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? (exception, stackTrace) {
                              // Resim yüklenemezse varsayılan ikonu göster
                            }
                          : null,
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? null
                          : Icon(
                              Icons.person,
                              color: Colors.grey[600],
                              size: 28,
                            ),
                    );
                  },
                ),
                const SizedBox(width: 12),
                
                // Metin alanı ve butonlar
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Metin alanı
                      TextField(
                        controller: _textController,
                        focusNode: _focusNode,
                        onTap: () {
                          setState(() {
                            _isExpanded = true;
                          });
                        },
                        onChanged: (value) {
                          setState(() {});
                        },
                        maxLines: _isExpanded ? null : 1,
                        maxLength: 280,
                        // Türkçe karakter desteği - input formatter kaldırıldı, tüm karakterler kabul edilir
                        style: const TextStyle(
                          fontSize: 20,
                          height: 1.3,
                        ),
                        decoration: const InputDecoration(
                          hintText: "What's happening?",
                          hintStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 20,
                          ),
                          border: InputBorder.none,
                          counterText: '',
                        ),
                      ),
                      
                      // Seçilen medya önizlemeleri
                      if (_selectedMedia.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _buildMediaPreview(),
                      ],
                      
                      // Anket önizlemesi
                      if (_pollData != null) ...[
                        const SizedBox(height: 12),
                        _buildPollPreview(),
                      ],
                      
                      // Alt butonlar
                      if (_isExpanded || _textController.text.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            // Medya butonları
                            _buildActionButton(
                              icon: FontAwesomeIcons.image,
                              color: const Color(0xFF1DA1F2),
                              onPressed: _addMedia,
                            ),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              icon: FontAwesomeIcons.photoFilm,
                              color: const Color(0xFF1DA1F2),
                              onPressed: _addVideo,
                            ),
                            const SizedBox(width: 12),
                            _buildActionButton(
                              icon: FontAwesomeIcons.squarePollVertical,
                              color: const Color(0xFF1DA1F2),
                              onPressed: _addPoll,
                            ),

                            const Spacer(),
                            
                            // Karakter sayısı ve Post butonu
                            Flexible(
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Karakter sayısını sadece 240+ karakter olduğunda göster
                                  if (_textController.text.length >= 240)
                                    Flexible(
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getCharacterCountColor(),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_textController.text.length}/280',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: _getCharacterCountTextColor(),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  if (_textController.text.length >= 240)
                                    const SizedBox(width: 6),
                                  
                                  // Post butonu
                                  ElevatedButton(
                                    onPressed: _canPost() ? _postContent : null,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: _canPost() ? Colors.green : Colors.grey[300],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      minimumSize: const Size(60, 36),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      elevation: 0,
                                    ),
                                    child: const Text(
                                      'Post',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = const Color(0xFF1DA1F2),
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
        ),
        child: FaIcon(
          icon,
          size: 22,
          color: Colors.green,
        ),
      ),
    );
  }

  Widget _buildMediaPreview() {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _selectedMedia.length,
        itemBuilder: (context, index) {
          final media = _selectedMedia[index];
          return Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300, width: 1),
                  image: DecorationImage(
                    image: FileImage(File(media.path)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                top: 4,
                right: 12,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedMedia.removeAt(index);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.black87,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPollPreview() {
    if (_pollData == null) return const SizedBox.shrink();
    
    final options = _pollData!['options'] as List<String>;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.squarePollVertical,
                    size: 16,
                    color: Colors.blue.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Anket',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: () {
                  setState(() {
                    _pollData = null;
                  });
                },
                child: const Icon(
                  Icons.close,
                  size: 20,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...options.map((option) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400, width: 1),
              borderRadius: BorderRadius.circular(8),
              color: Colors.white,
            ),
            child: Text(
              option,
              style: const TextStyle(fontSize: 14),
            ),
          )),
          const SizedBox(height: 4),
          Text(
            '${_pollData!['duration']} gün',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  bool _canPost() {
    return _textController.text.trim().isNotEmpty && 
           _textController.text.length <= 280;
  }

  Color _getCharacterCountColor() {
    final length = _textController.text.length;
    if (length > 260) return Colors.red.withOpacity(0.1);
    if (length > 240) return Colors.orange.withOpacity(0.1);
    return Colors.grey.withOpacity(0.1);
  }

  Color _getCharacterCountTextColor() {
    final length = _textController.text.length;
    if (length > 260) return Colors.red;
    if (length > 240) return Colors.orange;
    return Colors.grey;
  }

  Future<void> _postContent() async {
    if (!_canPost()) return;

    try {
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final postId = 'user_post_${DateTime.now().millisecondsSinceEpoch}';
      
      // Medya dosya yollarını al
      final mediaList = _selectedMedia.map((file) => file.path).toList();
      
      final postData = {
        'id': postId,
        'type': 'user_post',
        'createdAt': DateTime.now().toIso8601String(),
        'authorEmail': widget.userEmail,
        'payload': {
          'content': _textController.text.trim(),
          'userName': HiveDatabaseService.getRegistrationByEmail(widget.userEmail ?? '')?.judgeName ?? 'Bilinmeyen',
          'userEmail': widget.userEmail,
          'likes': 0,
          'retweets': 0,
          'comments': 0,
          'userLiked': false,
          'userRetweeted': false,
          'media': mediaList, // Medya dosya yolları
          'hasMedia': mediaList.isNotEmpty,
          'mediaCount': mediaList.length,
          'poll': _pollData, // Anket verisi
          'hasPoll': _pollData != null,
        },
      };

      await davaProvider.addHomeFeedPost(postData);
      
      // Başarı mesajı
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Post paylaşıldı!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Alanı temizle
      _textController.clear();
      _selectedMedia.clear();
      _pollData = null;
      _focusNode.unfocus();
      setState(() {
        _isExpanded = false;
      });
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Post paylaşılamadı: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _addMedia() async {
    try {
      final List<XFile> images = await _imagePicker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
      );
      
      if (images.isNotEmpty) {
        setState(() {
          _selectedMedia.addAll(images);
          if (_selectedMedia.length > 4) {
            _selectedMedia = _selectedMedia.take(4).toList();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ Maksimum 4 resim ekleyebilirsiniz'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 2),
              ),
            );
          }
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Resim seçilemedi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addVideo() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 140),
      );
      
      if (video != null) {
        setState(() {
          _selectedMedia = [video]; // Video için sadece tek dosya
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Video eklendi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Video seçilemedi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _addPoll() async {
    // Anket eklenirse medya eklenemez
    if (_selectedMedia.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Anket eklerken medya ekleyemezsiniz'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => _PollCreationDialog(),
    );

    if (result != null) {
      setState(() {
        _pollData = result;
      });
    }
  }
}

/// Twitter/X benzeri post kartı widget'ı
class TwitterPostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final VoidCallback? onLike;
  final VoidCallback? onRetweet;
  final VoidCallback? onComment;
  final VoidCallback? onShare;
  
  const TwitterPostCard({
    super.key,
    required this.post,
    this.onLike,
    this.onRetweet,
    this.onComment,
    this.onShare,
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
                      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                          : null,
                      onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? (exception, stackTrace) {
                              // Resim yüklenemezse varsayılan ikonu göster
                            }
                          : null,
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
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
              _buildPollWidget(poll, userEmail),
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
                    icon: userLiked ? FontAwesomeIcons.solidHeart : FontAwesomeIcons.heart,
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
    required IconData icon,
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

  Widget _buildPollWidget(Map<String, dynamic> pollData, String currentUserEmail) {
    final options = pollData['options'] as List<dynamic>? ?? [];
    final votes = asStringDynamicMap(pollData['votes']);
    final totalVotes = votes.values.fold<int>(0, (sum, count) => sum + (count as int));
    final userVotes = asStringDynamicMap(pollData['userVotes']);
    final userVote = userVotes[currentUserEmail] as String?;
    final hasVoted = userVote != null;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300, width: 1),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey.shade50,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...options.asMap().entries.map((entry) {
            final option = entry.value as String;
            final voteCount = votes[option] ?? 0;
            final percentage = totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
            final isUserChoice = userVote == option;
            
            return GestureDetector(
              onTap: hasVoted ? null : () {
                // Oy verme işlemi - Provider üzerinden güncelleme yapılabilir
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Stack(
                  children: [
                    // Arkaplan progress
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isUserChoice 
                          ? Colors.blue.shade100
                          : Colors.grey.shade200,
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: hasVoted ? (percentage / 100) : 0,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: isUserChoice 
                              ? Colors.blue.shade400
                              : Colors.grey.shade400,
                          ),
                        ),
                      ),
                    ),
                    // Metin
                    Container(
                      height: 40,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              option,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: isUserChoice ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ),
                          if (hasVoted)
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 8),
          Text(
            '$totalVotes oy • ${pollData['duration']} gün',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
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
          borderRadius: BorderRadius.circular(index == 0 ? 16 : 
                                              index == 1 ? 16 : 
                                              index == 2 ? 16 : 16),
          child: Image.file(
            File(media[index]),
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
}

/// Anket oluşturma dialog'u
class _PollCreationDialog extends StatefulWidget {
  @override
  State<_PollCreationDialog> createState() => _PollCreationDialogState();
}

class _PollCreationDialogState extends State<_PollCreationDialog> {
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _durationDays = 1;

  @override
  void dispose() {
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    if (_optionControllers.length < 4) {
      setState(() {
        _optionControllers.add(TextEditingController());
      });
    }
  }

  void _removeOption(int index) {
    if (_optionControllers.length > 2) {
      setState(() {
        _optionControllers[index].dispose();
        _optionControllers.removeAt(index);
      });
    }
  }

  bool _canCreate() {
    return _optionControllers.every((controller) => controller.text.trim().isNotEmpty);
  }

  void _createPoll() {
    if (!_canCreate()) return;

    final options = _optionControllers
        .map((controller) => controller.text.trim())
        .toList();

    final pollData = {
      'options': options,
      'duration': _durationDays,
      'votes': {for (var option in options) option: 0},
      'userVotes': {},
      'createdAt': DateTime.now().toIso8601String(),
    };

    Navigator.of(context).pop(pollData);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Anket Oluştur',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Seçenekler
            ..._optionControllers.asMap().entries.map((entry) {
              final index = entry.key;
              final controller = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        // Türkçe karakter desteği - input formatter kaldırıldı, tüm karakterler kabul edilir
                        decoration: InputDecoration(
                          hintText: 'Seçenek ${index + 1}',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                        maxLength: 50,
                        onChanged: (value) => setState(() {}),
                      ),
                    ),
                    if (_optionControllers.length > 2)
                      IconButton(
                        onPressed: () => _removeOption(index),
                        icon: const Icon(Icons.close, size: 20),
                        color: Colors.red,
                      ),
                  ],
                ),
              );
            }),

            // Seçenek ekle butonu
            if (_optionControllers.length < 4)
              TextButton.icon(
                onPressed: _addOption,
                icon: const Icon(Icons.add),
                label: const Text('Seçenek Ekle'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.blue,
                ),
              ),

            const SizedBox(height: 16),

            // Süre seçimi
            Row(
              children: [
                const Text(
                  'Anket süresi:',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<int>(
                    value: _durationDays,
                    isExpanded: true,
                    items: [1, 2, 3, 7]
                        .map((days) => DropdownMenuItem(
                              value: days,
                              child: Text('$days gün'),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _durationDays = value;
                        });
                      }
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canCreate() ? _createPoll : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Oluştur'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
