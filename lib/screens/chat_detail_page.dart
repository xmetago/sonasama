import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:shimmer/shimmer.dart';
import '../models/chat_message_model.dart';
import '../services/chat_service.dart';
import '../services/user_session_service.dart';
import '../services/audio_message_service.dart';
import '../widgets/simple_emoji_picker.dart';
import '../widgets/audio_message_player.dart';
import 'dart:async';

class ChatDetailPage extends StatefulWidget {
  final String receiverId;
  final String receiverEmail;
  final String receiverName;
  final String? receiverAvatarUrl;
  final String? userEmail;

  const ChatDetailPage({
    super.key,
    required this.receiverId,
    required this.receiverEmail,
    required this.receiverName,
    this.receiverAvatarUrl,
    this.userEmail,
  });

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final List<types.Message> _messages = [];
  StreamSubscription<List<ChatMessageModel>>? _messagesSubscription;
  types.User? _currentUser;
  types.User? _receiverUser;

  bool _isRecording = false;
  int _recordingDuration = 0;
  bool _isLoadingMessages = true;

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _startListening();
  }

  void _initializeUsers() {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    _currentUser = types.User(
      id: currentUser.id,
      firstName: currentUser.judgeName,
      imageUrl: currentUser.profileImage,
    );

    _receiverUser = types.User(
      id: widget.receiverId,
      firstName: widget.receiverName,
      imageUrl: widget.receiverAvatarUrl,
    );
  }

  List<types.Message> _dedupeAndSort(List<ChatMessageModel> raw) {
    final uniqueMessages = <String, types.Message>{};
    for (final chatMessage in raw) {
      final message = _convertToChatMessage(chatMessage);
      uniqueMessages[message.id] = message;
    }

    return uniqueMessages.values.toList()
      ..sort((a, b) {
        final aTime = a.createdAt ?? 0;
        final bTime = b.createdAt ?? 0;
        if (aTime != bTime) {
          // flutter_chat_ui en yeni mesajı listenin başında bekler.
          return bTime.compareTo(aTime);
        }
        return b.id.compareTo(a.id);
      });
  }

  void _applyMessages(List<ChatMessageModel> chatMessages) {
    if (!mounted) return;

    final nextMessages = _dedupeAndSort(chatMessages);
    final unchanged = !_isLoadingMessages &&
        _messages.length == nextMessages.length &&
        _messages.every(
          (message) => nextMessages.any((next) => next.id == message.id),
        );

    if (unchanged) return;

    void updateState() {
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(nextMessages);
        _isLoadingMessages = false;
      });
    }

    // Stream emit'i layout/build sırasında gelirse setState çakışmasını önle.
    if (WidgetsBinding.instance.schedulerPhase != SchedulerPhase.idle) {
      WidgetsBinding.instance.addPostFrameCallback((_) => updateState());
    } else {
      updateState();
    }
  }

  Future<void> _markConversationRead() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    try {
      await ChatService.markConversationAsRead(currentUser.id, widget.receiverId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Konuşma okundu işaretlenemedi: $e');
      }
    }
  }

  Future<void> _forceRefresh() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      _isLoadingMessages = true;
    });

    try {
      final messages = await ChatService.getMessages(currentUser.id, widget.receiverId);
      _applyMessages(messages);
      await ChatService.markConversationAsRead(currentUser.id, widget.receiverId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Mesaj yenileme hatası: $e');
      }
      try {
        final fallback = ChatService.getMessagesSync(currentUser.id, widget.receiverId);
        _applyMessages(fallback);
      } catch (_) {
        if (mounted) {
          setState(() {
            _isLoadingMessages = false;
          });
        }
      }
    }
  }

  void _startListening() {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) {
      setState(() {
        _isLoadingMessages = false;
      });
      return;
    }

    _messagesSubscription = ChatService.watchConversation(
      currentUser.id,
      widget.receiverId,
    ).listen(
      (chatMessages) {
        _applyMessages(chatMessages);
        _markConversationRead();
      },
      onError: (Object e) {
        if (kDebugMode) {
          debugPrint('Mesaj stream hatası: $e');
        }
        if (mounted) {
          setState(() {
            _isLoadingMessages = false;
          });
        }
      },
    );
  }

  types.Message _convertToChatMessage(ChatMessageModel chatMessage) {
    final author = types.User(
      id: chatMessage.senderId,
      firstName: chatMessage.senderName,
      imageUrl: chatMessage.senderAvatarUrl,
    );
    final createdAt = chatMessage.createdAt.millisecondsSinceEpoch;

    if (chatMessage.imageUrl != null) {
      return types.ImageMessage(
        author: author,
        createdAt: createdAt,
        id: chatMessage.id,
        name: chatMessage.text.isNotEmpty ? chatMessage.text : 'Görsel',
        size: 1,
        uri: chatMessage.imageUrl!,
      );
    }

    if (chatMessage.fileUrl != null) {
      return types.FileMessage(
        author: author,
        createdAt: createdAt,
        id: chatMessage.id,
        name: chatMessage.text.isNotEmpty ? chatMessage.text : 'Dosya',
        size: 1,
        uri: chatMessage.fileUrl!,
      );
    }

    if (chatMessage.audioUrl != null) {
      return types.CustomMessage(
        author: author,
        createdAt: createdAt,
        id: chatMessage.id,
        metadata: {
          'type': 'audio',
          'audioUrl': chatMessage.audioUrl,
          'duration': chatMessage.audioDuration ?? 0,
        },
      );
    }

    return types.TextMessage(
      author: author,
      createdAt: createdAt,
      id: chatMessage.id,
      text: chatMessage.text,
    );
  }

  void _handleSendPressed(types.PartialText message) async {
    try {
      await ChatService.sendMessage(
        receiverId: widget.receiverId,
        receiverEmail: widget.receiverEmail,
        text: message.text,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Mesaj gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _handleAttachmentPressed() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosya ekleme özelliği yakında eklenecek'),
      ),
    );
  }

  void _handleMessageTap(BuildContext context, types.Message message) {
    if (message is types.ImageMessage) {
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(message.uri),
        ),
      );
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    if (kDebugMode) {
      debugPrint('Link önizlemesi alındı: ${previewData.link}');
    }
  }

  void _onEmojiSelected(String emoji) {
    _handleSendPressed(types.PartialText(text: emoji));
  }

  void _showEmojiPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SimpleEmojiPicker(
            onEmojiSelected: _onEmojiSelected,
          ),
        );
      },
    );
  }

  Future<void> _startRecording() async {
    try {
      final success = await AudioMessageService.startRecording(
        onDurationUpdate: (duration) {
          if (mounted) {
            setState(() {
              _recordingDuration = duration;
            });
          }
        },
      );

      if (success && mounted) {
        setState(() {
          _isRecording = true;
          _recordingDuration = 0;
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mikrofon izni gerekli'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ses kaydı başlatılamadı: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses kaydı başlatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopRecordingAndSend() async {
    final recordedDuration = _recordingDuration;

    try {
      final filePath = await AudioMessageService.stopRecording();

      if (filePath == null || filePath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Kayıt edilen dosya bulunamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _isRecording = false;
          _recordingDuration = 0;
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 16),
                Text('Ses kaydı yükleniyor...'),
              ],
            ),
            duration: Duration(seconds: 30),
          ),
        );
      }

      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser == null) return;

      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final conversationId = ChatMessageModel.createConversationId(
        currentUser.id,
        widget.receiverId,
      );

      String? audioUrl;
      try {
        audioUrl = await AudioMessageService.uploadAudioToStorage(
          filePath: filePath,
          messageId: messageId,
          conversationId: conversationId,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('Ses yükleme hatası: $e');
        }
      }

      if (audioUrl == null || audioUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Ses dosyası yüklenemedi. İnternet bağlantınızı ve Firebase Storage ayarlarını kontrol edin.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      await ChatService.sendMessage(
        receiverId: widget.receiverId,
        receiverEmail: widget.receiverEmail,
        text: '🎤 Sesli mesaj',
        audioUrl: audioUrl,
        audioDuration: recordedDuration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesli mesaj gönderildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Ses kaydı gönderilemedi: $e');
      }
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses kaydı gönderilemedi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelRecording() async {
    await AudioMessageService.cancelRecording();
    if (mounted) {
      setState(() {
        _isRecording = false;
        _recordingDuration = 0;
      });
    }
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  Widget _buildMessagesLoadingPlaceholder() {
    return ColoredBox(
      color: const Color(0xFFF5F5F5),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Align(
                alignment: index.isEven
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (index.isEven) ...[
                      Container(
                        width: 40,
                        height: 40,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Container(
                      width: 200,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    AudioMessageService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null || _receiverUser == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Yükleniyor...'),
        ),
        body: Center(
          child: Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: 200,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.receiverAvatarUrl != null
                  ? NetworkImage(widget.receiverAvatarUrl!)
                  : null,
              child: widget.receiverAvatarUrl == null
                  ? Text(
                      widget.receiverName.isNotEmpty
                          ? widget.receiverName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(color: Colors.white),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.receiverName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _forceRefresh,
            tooltip: 'Yenile',
          ),
          IconButton(
            icon: const Icon(Icons.emoji_emotions_outlined),
            onPressed: _showEmojiPicker,
            tooltip: 'Emoji seç',
          ),
        ],
        backgroundColor: Colors.white,
        elevation: 1,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (_isLoadingMessages && _messages.isEmpty)
            _buildMessagesLoadingPlaceholder()
          else
            Chat(
              messages: _messages,
              onAttachmentPressed: _handleAttachmentPressed,
              onMessageTap: _handleMessageTap,
              onPreviewDataFetched: _handlePreviewDataFetched,
              onSendPressed: _handleSendPressed,
              showUserAvatars: true,
              showUserNames: true,
              user: _currentUser!,
              customMessageBuilder: (message, {required messageWidth}) {
                final metadata = message.metadata;
                if (metadata != null && metadata['type'] == 'audio') {
                  final audioUrl = metadata['audioUrl'] as String?;
                  final duration = metadata['duration'] as int?;
                  final isSent = message.author.id == _currentUser?.id;

                  if (audioUrl != null) {
                    return AudioMessagePlayer(
                      audioUrl: audioUrl,
                      duration: duration,
                      isSent: isSent,
                    );
                  }
                }
                return const SizedBox.shrink();
              },
              theme: const DefaultChatTheme(
                primaryColor: Color(0xFF1976D2),
                backgroundColor: Color(0xFFF5F5F5),
                inputBackgroundColor: Colors.white,
                inputTextColor: Colors.black87,
                receivedMessageBodyTextStyle: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                sentMessageBodyTextStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
              ),
            ),
          if (_isRecording)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  border: Border(
                    top: BorderSide(color: Colors.red.shade200, width: 2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDuration(_recordingDuration),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _cancelRecording,
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _stopRecordingAndSend,
                      icon: const Icon(Icons.send),
                      label: const Text('Gönder'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isRecording
          ? null
          : FloatingActionButton(
              mini: true,
              backgroundColor: Colors.blue,
              onPressed: _startRecording,
              tooltip: 'Sesli mesaj gönder',
              child: const Icon(Icons.mic, color: Colors.white),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
