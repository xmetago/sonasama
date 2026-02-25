import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
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
  final TextEditingController _messageController = TextEditingController();
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  // Ses kaydı durumu
  bool _isRecording = false;
  int _recordingDuration = 0;
  bool _isLoadingMessages = false;

  @override
  void initState() {
    super.initState();
    _initializeUsers();
    _loadMessages(); // Async çağrı
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

  Future<void> _loadMessages({bool isRefresh = false}) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) {
      if (isRefresh) _refreshController.refreshCompleted();
      return;
    }

    if (isRefresh) {
      setState(() {
        _isLoadingMessages = true;
      });
    }

    try {
      final messages = await ChatService.getMessages(currentUser.id, widget.receiverId);
      if (mounted) {
        // Mesajları benzersiz ID'lere göre filtrele ve sırala
        final uniqueMessages = <String, types.Message>{};
        for (final chatMessage in messages) {
          final message = _convertToChatMessage(chatMessage);
          uniqueMessages[message.id] = message;
        }
        
        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? 0;
            final bTime = b.createdAt ?? 0;
            return aTime.compareTo(bTime); // Artan sıra: en eski → en yeni
          });
        
        setState(() {
          _messages.clear();
          _messages.addAll(sortedMessages);
          _isLoadingMessages = false;
        });
      }

      // Mesajları okundu olarak işaretle
      await ChatService.markConversationAsRead(currentUser.id, widget.receiverId);
      
      if (isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('⚠️ Mesajlar yüklenirken hata: $e');
      // Hata durumunda Hive'dan yükle
      final messages = ChatService.getMessagesSync(currentUser.id, widget.receiverId);
      if (mounted) {
        // Mesajları benzersiz ID'lere göre filtrele ve sırala
        final uniqueMessages = <String, types.Message>{};
        for (final chatMessage in messages) {
          final message = _convertToChatMessage(chatMessage);
          uniqueMessages[message.id] = message;
        }
        
        final sortedMessages = uniqueMessages.values.toList()
          ..sort((a, b) {
            final aTime = a.createdAt ?? 0;
            final bTime = b.createdAt ?? 0;
            return aTime.compareTo(bTime); // Artan sıra: en eski → en yeni
          });
        
        setState(() {
          _messages.clear();
          _messages.addAll(sortedMessages);
          _isLoadingMessages = false;
        });
      }
      
      if (isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }
  

  void _startListening() {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    _messagesSubscription = ChatService.watchConversation(
      currentUser.id,
      widget.receiverId,
    ).listen((chatMessages) {
      if (!mounted) return;
      
      // Mesajları benzersiz ID'lere göre filtrele ve sırala
      final uniqueMessages = <String, types.Message>{};
      for (final chatMessage in chatMessages) {
        final message = _convertToChatMessage(chatMessage);
        uniqueMessages[message.id] = message;
      }
      
      // Listeyi oluştur ve sırala (en eski → en yeni)
      // flutter_chat_ui paketi mesajları üstten alta doğru gösterir
      // En eski mesaj üstte, en yeni mesaj altta olmalı
      final sortedMessages = uniqueMessages.values.toList()
        ..sort((a, b) {
          final aTime = a.createdAt ?? 0;
          final bTime = b.createdAt ?? 0;
          return aTime.compareTo(bTime); // Artan sıra: en eski → en yeni
        });
      
      // Debug: Mesaj sıralamasını kontrol et
      if (sortedMessages.isNotEmpty) {
        print('📨 Mesaj sıralaması:');
        for (int i = 0; i < sortedMessages.length; i++) {
          final msg = sortedMessages[i];
          print('  [$i] ID: ${msg.id}, Zaman: ${msg.createdAt}, Metin: ${msg is types.TextMessage ? msg.text : "Diğer"}');
        }
      }
      
      setState(() {
        _messages.clear();
        _messages.addAll(sortedMessages);
      });

      // Yeni mesajlar geldiğinde okundu olarak işaretle
      ChatService.markConversationAsRead(currentUser.id, widget.receiverId);
    });
  }

  types.Message _convertToChatMessage(ChatMessageModel chatMessage) {

    // Görsel mesaj
    if (chatMessage.imageUrl != null) {
      return types.ImageMessage(
        author: types.User(
          id: chatMessage.senderId,
          firstName: chatMessage.senderName,
          imageUrl: chatMessage.senderAvatarUrl,
        ),
        createdAt: chatMessage.createdAt.millisecondsSinceEpoch,
        id: chatMessage.id,
        name: chatMessage.text.isNotEmpty ? chatMessage.text : 'Görsel',
        size: 0, // Boyut bilgisi yoksa 0
        uri: chatMessage.imageUrl!,
      );
    }

    // Dosya mesajı
    if (chatMessage.fileUrl != null) {
      return types.FileMessage(
        author: types.User(
          id: chatMessage.senderId,
          firstName: chatMessage.senderName,
          imageUrl: chatMessage.senderAvatarUrl,
        ),
        createdAt: chatMessage.createdAt.millisecondsSinceEpoch,
        id: chatMessage.id,
        name: chatMessage.text.isNotEmpty ? chatMessage.text : 'Dosya',
        size: 0,
        uri: chatMessage.fileUrl!,
      );
    }

    // Sesli mesaj
    if (chatMessage.audioUrl != null) {
      return types.CustomMessage(
        author: types.User(
          id: chatMessage.senderId,
          firstName: chatMessage.senderName,
          imageUrl: chatMessage.senderAvatarUrl,
        ),
        createdAt: chatMessage.createdAt.millisecondsSinceEpoch,
        id: chatMessage.id,
        metadata: {
          'type': 'audio',
          'audioUrl': chatMessage.audioUrl,
          'duration': chatMessage.audioDuration ?? 0,
        },
      );
    }

    // Metin mesajı
    return types.TextMessage(
      author: types.User(
        id: chatMessage.senderId,
        firstName: chatMessage.senderName,
        imageUrl: chatMessage.senderAvatarUrl,
      ),
      createdAt: chatMessage.createdAt.millisecondsSinceEpoch,
      id: chatMessage.id,
      text: chatMessage.text,
    );
  }

  void _handleSendPressed(types.PartialText message) async {
    try {
      // Mesajı gönder - stream otomatik olarak güncelleyecek
      await ChatService.sendMessage(
        receiverId: widget.receiverId,
        receiverEmail: widget.receiverEmail,
        text: message.text,
      );
      // Manuel ekleme yapmıyoruz - stream zaten ekleyecek
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
    // Dosya ekleme özelliği gelecekte eklenecek
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dosya ekleme özelliği yakında eklenecek'),
      ),
    );
  }

  void _handleMessageTap(BuildContext context, types.Message message) {
    // Mesaja tıklandığında yapılacak işlemler
    if (message is types.ImageMessage) {
      // Görseli büyüt
      showDialog(
        context: context,
        builder: (context) => Dialog(
          child: Image.network(message.uri),
        ),
      );
    } else if (message is types.CustomMessage) {
      // Sesli mesaj için özel işlem (zaten AudioMessagePlayer widget'ı içinde oynatılıyor)
      final metadata = message.metadata;
      if (metadata != null && metadata['type'] == 'audio') {
        // Sesli mesaj oynatıcı widget'ı zaten gösteriliyor
      }
    }
  }

  /// Link önizlemesi için callback
  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    // flutter_chat_ui otomatik olarak link preview'ları gösterir
    // Bu callback preview verisi alındığında çağrılır
    print('🔗 Link önizlemesi alındı: ${previewData.link}');
  }

  /// Emoji seçildiğinde çağrılır
  void _onEmojiSelected(String emoji) async {
    // Seçilen emojiyi clipboard'a kopyala
    await Clipboard.setData(ClipboardData(text: emoji));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Emoji kopyalandı: $emoji - Mesaj alanına yapıştırabilirsiniz (Ctrl+V / Cmd+V)'),
          duration: const Duration(seconds: 2),
          action: SnackBarAction(
            label: 'Tamam',
            onPressed: () {},
          ),
        ),
      );
    }
  }

  /// Emoji picker widget'ı (Bottom Sheet olarak)
  void _showEmojiPicker() {
    print('🎨 Emoji picker açılıyor...');
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
            onEmojiSelected: (emoji) {
              print('✅ Emoji seçildi: $emoji');
              _onEmojiSelected(emoji);
            },
          ),
        );
      },
    );
  }

  /// Ses kaydına başla
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
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Mikrofon izni gerekli'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Ses kaydı başlatılamadı: $e');
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

  /// Ses kaydını durdur ve gönder
  Future<void> _stopRecordingAndSend() async {
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

      // Loading göster
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

      // Mesaj ID'si oluştur
      final messageId = DateTime.now().millisecondsSinceEpoch.toString();
      final conversationId = ChatMessageModel.createConversationId(
        currentUser.id,
        widget.receiverId,
      );

      // Ses dosyasını Firebase Storage'a yükle
      String? audioUrl;
      try {
        audioUrl = await AudioMessageService.uploadAudioToStorage(
          filePath: filePath,
          messageId: messageId,
          conversationId: conversationId,
        );
      } catch (e) {
        print('❌ Ses yükleme hatası: $e');
      }

      if (audioUrl == null || audioUrl.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ses dosyası yüklenemedi. İnternet bağlantınızı ve Firebase Storage ayarlarını kontrol edin.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
        return;
      }

      // Mesajı gönder
      await ChatService.sendMessage(
        receiverId: widget.receiverId,
        receiverEmail: widget.receiverEmail,
        text: '🎤 Sesli mesaj',
        audioUrl: audioUrl,
        audioDuration: _recordingDuration,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Sesli mesaj gönderildi'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('❌ Ses kaydı gönderilemedi: $e');
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

  /// Ses kaydını iptal et
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

  @override
  void dispose() {
    _messagesSubscription?.cancel();
    _messageController.dispose();
    _refreshController.dispose();
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
                const SizedBox(height: 8),
                Container(
                  width: 150,
                  height: 16,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.receiverName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Online durumu gösterilebilir
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Emoji butonu
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
        children: [
          // Mesajlar yüklenirken shimmer göster
          if (_isLoadingMessages && _messages.isEmpty)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(
                color: Colors.white,
                child: ListView.builder(
                  itemCount: 5,
                  padding: const EdgeInsets.all(16),
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        mainAxisAlignment: index % 2 == 0 
                            ? MainAxisAlignment.start 
                            : MainAxisAlignment.end,
                        children: [
                          if (index % 2 == 0) ...[
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
                          if (index % 2 != 0) ...[
                            const SizedBox(width: 8),
                            Container(
                              width: 40,
                              height: 40,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            )
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
          // Ses kaydı göstergesi
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
                    // Kayıt ikonu
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Süre
                    Text(
                      _formatDuration(_recordingDuration),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const Spacer(),
                    // İptal butonu
                    TextButton(
                      onPressed: _cancelRecording,
                      child: const Text('İptal'),
                    ),
                    const SizedBox(width: 8),
                    // Gönder butonu
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
      // Ses kaydı butonu (floating action button)
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

