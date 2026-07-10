import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/dava_provider.dart';
import '../services/hive_database_service.dart';
import '../utils/map_safety.dart';

/// Twitter/X anket mavi tonu (görseldeki çerçeve/metin rengine yakın)
const Color _kTwitterPollBlue = Color(0xFF1D9BF0);

/// Anket alanını ayırt etmek için (adalet terazisi)
Widget pollTypeBadgeIcon({double size = 18}) {
  return Icon(
    Icons.balance,
    size: size,
    color: _kTwitterPollBlue.withValues(alpha: 0.9),
  );
}

/// Anket bitişine kalan tam gün sayısı (eski kayıtlar için `createdAt` + `duration` ile tahmin)
int pollDaysLeftFromData(Map<String, dynamic> pollData) {
  final endsAtStr = pollData['endsAt']?.toString();
  DateTime? end;
  if (endsAtStr != null && endsAtStr.isNotEmpty) {
    end = DateTime.tryParse(endsAtStr);
  }
  if (end == null) {
    final created =
        DateTime.tryParse(pollData['createdAt']?.toString() ?? '') ??
            DateTime.now();
    final dur = pollData['duration'];
    final days = dur is int ? dur : int.tryParse(dur.toString()) ?? 1;
    end = created.add(Duration(days: days));
  }
  final diff = end.difference(DateTime.now());
  if (diff.isNegative) return 0;
  return diff.inDays.clamp(0, 3650);
}

int pollAsInt(dynamic value) {
  if (value == null) return 0;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? 0;
}

/// Seyir defteri anket alanı: oy sonrası UI güncellemesi, hover, çift tıklama koruması
class TwitterFeedPollSection extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> pollData;
  final String postId;

  /// Giriş yapmış kullanıcı e-postası (oy anahtarı). Boşsa yazar e-postası kullanılır.
  final String? viewerEmail;
  final VoidCallback? onVoteSubmitted;

  const TwitterFeedPollSection({
    super.key,
    required this.post,
    required this.pollData,
    required this.postId,
    this.viewerEmail,
    this.onVoteSubmitted,
  });

  @override
  State<TwitterFeedPollSection> createState() => _TwitterFeedPollSectionState();
}

class _TwitterFeedPollSectionState extends State<TwitterFeedPollSection> {
  bool _submitting = false;
  String? _hoveredOption;
  Map<String, dynamic>? _pendingPoll;

  String get _voterKey {
    final v = (widget.viewerEmail ?? '').trim();
    if (v.isNotEmpty) return v;
    final payload = asStringDynamicMap(widget.post['payload']);
    return (payload['userEmail'] ?? '').toString().trim();
  }

  @override
  void didUpdateWidget(TwitterFeedPollSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pollData, widget.pollData)) {
      _pendingPoll = null;
    }
  }

  Future<void> _submitVote(String option) async {
    final pollData = _pendingPoll ?? widget.pollData;
    final userVotes = asStringDynamicMap(pollData['userVotes']);
    final existing = userVotes[_voterKey]?.toString();
    final alreadyVoted = existing != null && existing.isNotEmpty;
    if (_submitting ||
        alreadyVoted ||
        widget.postId.isEmpty ||
        _voterKey.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final updatedPoll = Map<String, dynamic>.from(pollData);
      final updatedVotes = asStringDynamicMap(updatedPoll['votes']);
      final updatedUserVotes = asStringDynamicMap(updatedPoll['userVotes']);
      final currentCount = pollAsInt(updatedVotes[option]);
      updatedVotes[option] = currentCount + 1;
      updatedUserVotes[_voterKey] = option;
      updatedPoll['votes'] = updatedVotes;
      updatedPoll['userVotes'] = updatedUserVotes;

      final updatedPost = Map<String, dynamic>.from(widget.post);
      final updatedPayload = asStringDynamicMap(updatedPost['payload']);
      updatedPayload['poll'] = updatedPoll;
      updatedPayload['hasPoll'] = true;
      updatedPost['payload'] = updatedPayload;

      await davaProvider.updateHomeFeedPost(widget.postId, updatedPost);
      if (!mounted) return;
      setState(() => _pendingPoll = updatedPoll);
      widget.onVoteSubmitted?.call();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollData = _pendingPoll ?? widget.pollData;
    final options = pollData['options'] as List<dynamic>? ?? [];
    final question = pollData['question']?.toString() ?? '';
    final votes = asStringDynamicMap(pollData['votes']);
    final userVotes = asStringDynamicMap(pollData['userVotes']);
    final userVote = userVotes[_voterKey]?.toString();
    final hasVoted = userVote != null && userVote.isNotEmpty;
    final totalVotes =
        votes.values.fold<int>(0, (sum, count) => sum + pollAsInt(count));
    final daysLeft = pollDaysLeftFromData(pollData);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFD9DE), width: 1),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: pollTypeBadgeIcon(size: 22),
                  ),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: pollTypeBadgeIcon(size: 22),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, question.isEmpty ? 8 : 0, 8, 8),
            child: Column(
              children: options.map<Widget>((dynamic raw) {
                final option = raw as String;
                final voteCount = pollAsInt(votes[option]);
                final percentage =
                    totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
                final isUserChoice = userVote == option;

                if (!hasVoted) {
                  final hovered = _hoveredOption == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MouseRegion(
                      // InkWell kaldırıldı: Material hover katmanı kutu rengini bastırıyordu.
                      cursor: SystemMouseCursors.click,
                      opaque: true,
                      onEnter: (_) {
                        if (_submitting) return;
                        setState(() => _hoveredOption = option);
                      },
                      onExit: (_) {
                        if (_hoveredOption == option) {
                          setState(() => _hoveredOption = null);
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _submitting ? null : () => _submitVote(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hovered
                                  ? _kTwitterPollBlue.withValues(alpha: 0.95)
                                  : _kTwitterPollBlue.withValues(alpha: 0.65),
                              width: hovered ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: hovered
                                ? _kTwitterPollBlue.withValues(alpha: 0.16)
                                : Colors.white,
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: hovered
                                  ? _kTwitterPollBlue
                                  : _kTwitterPollBlue.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFCFD9DE),
                              width: 1,
                            ),
                            color: Colors.white,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              color: _kTwitterPollBlue.withValues(
                                alpha: isUserChoice ? 0.28 : 0.14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isUserChoice
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${percentage.round()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  '$totalVotes oy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Center(child: pollTypeBadgeIcon(size: 17)),
                ),
                Text(
                  '$daysLeft gün kaldı',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum ComposerQuickAction {
  text,
  image,
  video,
  poll,
}

/// Twitter/X benzeri post paylaşım widget'ı
class TwitterPostComposer extends StatefulWidget {
  final String? userEmail;
  final ComposerQuickAction quickAction;

  const TwitterPostComposer({
    super.key,
    this.userEmail,
    this.quickAction = ComposerQuickAction.text,
  });

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
  void initState() {
    super.initState();
    _isExpanded = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      switch (widget.quickAction) {
        case ComposerQuickAction.image:
          await _addMedia();
          break;
        case ComposerQuickAction.video:
          await _addVideo();
          break;
        case ComposerQuickAction.poll:
          await _addPoll();
          break;
        case ComposerQuickAction.text:
          // Varsayılan metin paylaşımı
          break;
      }
    });
  }

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
                    final settings =
                        widget.userEmail != null && widget.userEmail!.isNotEmpty
                            ? HiveDatabaseService.getSettings(widget.userEmail!)
                            : null;
                    final profileImageUrl = settings?.profileImageUrl;

                    return CircleAvatar(
                      radius: 24,
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 4, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: _getCharacterCountColor(),
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '${_textController.text.length}/280',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color:
                                                _getCharacterCountTextColor(),
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
                                      backgroundColor: _canPost()
                                          ? Colors.green
                                          : Colors.grey[300],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
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

    final options = List<String>.from(_pollData!['options'] as List? ?? []);
    final question = _pollData!['question']?.toString() ?? '';
    final votes = asStringDynamicMap(_pollData!['votes']);
    final totalVotes = votes.values.fold<int>(
        0, (sum, c) => sum + (c is int ? c : int.tryParse(c.toString()) ?? 0));
    final daysLeft = pollDaysLeftFromData(_pollData!);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFD9DE), width: 1),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, right: 8),
                  child: pollTypeBadgeIcon(size: 22),
                ),
                Expanded(
                  child: question.isEmpty
                      ? Text(
                          'Anket',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.35,
                          ),
                        )
                      : Text(
                          question,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                            height: 1.35,
                          ),
                        ),
                ),
                IconButton(
                  onPressed: () => setState(() => _pollData = null),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.grey,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Column(
              children: options
                  .map(
                    (option) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _kTwitterPollBlue.withOpacity(0.65),
                            width: 1,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.white,
                        ),
                        child: Text(
                          option,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _kTwitterPollBlue,
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  '$totalVotes oy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Center(child: pollTypeBadgeIcon(size: 17)),
                ),
                Text(
                  '$daysLeft gün kaldı',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _canPost() {
    // Twitter/X benzeri paylaşımda bazen sadece görsel veya sadece anket yeterli olabiliyor.
    // Bu yüzden metin boş olsa bile medya veya anket varsa Post'u aktif ediyoruz.
    final hasText = _textController.text.trim().isNotEmpty;
    final hasMedia = _selectedMedia.isNotEmpty;
    final hasPoll = _pollData != null;

    return (hasText || hasMedia || hasPoll) &&
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
          'userName':
              HiveDatabaseService.getRegistrationByEmail(widget.userEmail ?? '')
                      ?.judgeName ??
                  'Bilinmeyen',
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

/// Anket oluşturma dialog'u
class _PollCreationDialog extends StatefulWidget {
  @override
  State<_PollCreationDialog> createState() => _PollCreationDialogState();
}

class _PollCreationDialogState extends State<_PollCreationDialog> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _durationDays = 1;

  @override
  void dispose() {
    _questionController.dispose();
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
    if (_questionController.text.trim().isEmpty) return false;
    return _optionControllers
        .every((controller) => controller.text.trim().isNotEmpty);
  }

  void _createPoll() {
    if (!_canCreate()) return;

    final options =
        _optionControllers.map((controller) => controller.text.trim()).toList();
    final now = DateTime.now();

    final pollData = {
      'question': _questionController.text.trim(),
      'options': options,
      'duration': _durationDays,
      'endsAt': now.add(Duration(days: _durationDays)).toIso8601String(),
      'votes': {for (var option in options) option: 0},
      'userVotes': {},
      'createdAt': now.toIso8601String(),
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

            TextField(
              controller: _questionController,
              maxLength: 120,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Anket sorusu',
                hintText: 'Örn: Favori sporunuz hangisi?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
              ),
            ),
            const SizedBox(height: 16),

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
