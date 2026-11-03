import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../providers/dava_provider.dart';
import '../services/hive_database_service.dart';
import '../utils/map_safety.dart';

import 'twitter_poll_helpers.dart';

export 'twitter_post_card.dart' show TwitterPostCard;
export 'twitter_feed_poll_section.dart' show TwitterFeedPollSection;
export 'twitter_poll_helpers.dart' show pollTypeBadgeIcon, pollDaysLeftFromData, pollAsInt, kTwitterPollBlue;

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
  /// FAB → Anket Paylaş akışında anket formunu composer içinde açar (ek dialog yok).
  final bool startInPollMode;

  const TwitterPostComposer({
    super.key,
    this.userEmail,
    this.quickAction = ComposerQuickAction.text,
    this.startInPollMode = false,
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
      if (widget.startInPollMode) {
        await _addPoll();
        return;
      }
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
        mainAxisSize: MainAxisSize.min,
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
                        maxLines: _isExpanded ? 6 : 1,
                        minLines: 1,
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
                      if (_isExpanded ||
                          _textController.text.isNotEmpty ||
                          _pollData != null) ...[
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
                            color: kTwitterPollBlue.withOpacity(0.65),
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
                            color: kTwitterPollBlue,
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

      if (widget.startInPollMode && mounted) {
        Navigator.of(context).pop();
      }
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
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: _PollEditorPanel(
              onPollCreated: (data) => Navigator.of(dialogContext).pop(data),
              onCancel: () {
                Navigator.of(dialogContext).pop();
                if (widget.startInPollMode &&
                    _pollData == null &&
                    mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ),
        );
      },
    );

    if (result != null && mounted) {
      setState(() => _pollData = result);
    }
  }
}

/// Anket oluşturma formu — composer içinde inline kullanılır.
class _PollEditorPanel extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>> onPollCreated;
  final VoidCallback onCancel;

  const _PollEditorPanel({
    required this.onPollCreated,
    required this.onCancel,
  });

  @override
  State<_PollEditorPanel> createState() => _PollEditorPanelState();
}

class _PollEditorPanelState extends State<_PollEditorPanel> {
  final TextEditingController _questionController = TextEditingController();
  final List<TextEditingController> _optionControllers = [
    TextEditingController(),
    TextEditingController(),
  ];
  int _durationDays = 1;

  @override
  void dispose() {
    _questionController.dispose();
    for (final controller in _optionControllers) {
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

    widget.onPollCreated({
      'question': _questionController.text.trim(),
      'options': options,
      'duration': _durationDays,
      'endsAt': now.add(Duration(days: _durationDays)).toIso8601String(),
      'votes': {for (final option in options) option: 0},
      'userVotes': {},
      'createdAt': now.toIso8601String(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFD9DE)),
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFFF7F9F9),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              pollTypeBadgeIcon(size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Anket Oluştur',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: widget.onCancel,
                icon: const Icon(Icons.close, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _questionController,
            maxLength: 120,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: 'Anket sorusu',
              hintText: 'Örn: Favori sporunuz hangisi?',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._optionControllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      decoration: InputDecoration(
                        hintText: 'Seçenek ${index + 1}',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                      maxLength: 50,
                      onChanged: (_) => setState(() {}),
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
          if (_optionControllers.length < 4)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add),
              label: const Text('Seçenek Ekle'),
              style: TextButton.styleFrom(
                foregroundColor: kTwitterPollBlue,
              ),
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Anket süresi:', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButton<int>(
                  value: _durationDays,
                  isExpanded: true,
                  items: [1, 2, 3, 7]
                      .map(
                        (days) => DropdownMenuItem(
                          value: days,
                          child: Text('$days gün'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _durationDays = value);
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canCreate() ? _createPoll : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kTwitterPollBlue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 48),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('Anketi Ekle'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
