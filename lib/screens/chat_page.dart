import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../services/friend_category_service.dart';
import '../services/user_session_service.dart';
import '../services/chat_service.dart';
import '../models/registration_model.dart';
import 'chat_detail_page.dart';

class Friend {
  final String name;
  final String avatarUrl;
  final bool isActive;
  final String lastMessage;
  final String lastMessageTime;
  final RegistrationModel? userModel; // Gerçek kullanıcı modeli

  Friend({
    required this.name, 
    required this.avatarUrl, 
    this.isActive = false,
    required this.lastMessage,
    required this.lastMessageTime,
    this.userModel,
  });
}

class ChatPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const ChatPage({super.key, this.userEmail});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool showLeftIcons = false;
  bool _isLoading = true;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  // Gerçek veriler için friends listesi
  List<Friend> friends = [];

  List<Friend> get activeFriends => friends.where((friend) => friend.isActive).toList();

  @override
  void initState() {
    super.initState();
    // FriendCategoryService'i başlat ve verileri yükle
    FriendCategoryService.initialize().then((_) {
      _loadGrup19Friends();
    });
  }

  /// Grup-19 kategorisindeki kullanıcıları yükle
  Future<void> _loadGrup19Friends({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
        });
        if (isRefresh) {
          _refreshController.refreshCompleted();
        }
        return;
      }

      // Normalize edilmiş kategoriyi kontrol et
      final allCategories = FriendCategoryService.listByOwner(currentUser.id);
      final grup19UserIds = <String>{};
      
      for (final category in allCategories) {
        final categoryLower = category.category.toLowerCase();
        if (categoryLower.contains('grup') && categoryLower.contains('19')) {
          grup19UserIds.add(category.targetUserId);
        }
      }

      // Tüm kullanıcıları al
      final allUsers = HiveDatabaseService.getAllRegistrations();
      
      // Grup-19 kategorisindeki kullanıcıları bul ve Friend listesine dönüştür
      friends = [];
      
      for (final userId in grup19UserIds) {
        try {
          final user = allUsers.firstWhere(
            (u) => u.id == userId,
          );
          
          if (user.id != currentUser.id) {
          // Online/offline durumunu kontrol et (son 15 dakika içinde giriş yaptıysa online)
          final now = DateTime.now();
          final timeDiff = now.difference(user.lastLoginAt);
          final isActive = timeDiff.inMinutes < 15;

          // Son mesaj zamanını formatla
          final lastMessageTime = _formatLastLoginTime(user.lastLoginAt);

          // Avatar URL'i oluştur (profil resmi varsa onu kullan, yoksa placeholder)
          final avatarUrl = user.profileImage ?? 
            "https://ui-avatars.com/api/?name=${Uri.encodeComponent(user.judgeName)}&background=random";

          // Son mesajı al (async - şimdilik sync versiyonunu kullan)
          final lastMessage = ChatService.getLastMessageSync(currentUser.id, user.id);
          String lastMessageText = "Henüz mesaj yok";
          String lastMessageTimeText = lastMessageTime;
          
          if (lastMessage != null) {
            lastMessageText = lastMessage.text;
            lastMessageTimeText = _formatLastMessageTime(lastMessage.createdAt);
          }

            friends.add(Friend(
              name: user.judgeName,
              avatarUrl: avatarUrl,
              isActive: isActive,
              lastMessage: lastMessageText,
              lastMessageTime: lastMessageTimeText,
              userModel: user,
            ));
          }
        } catch (e) {
          // Kullanıcı bulunamadı, devam et
          print('⚠️ Kullanıcı bulunamadı: $userId');
        }
      }

      // Kullanıcıları online durumuna göre sırala (önce online olanlar)
      friends.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return 0;
      });

      print('✅ Grup-19 kategorisinden ${friends.length} kullanıcı yüklendi');
      
      setState(() {
        _isLoading = false;
      });
      
      if (isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      print('❌ Arkadaşlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (isRefresh) {
        _refreshController.refreshFailed();
      }
    }
  }
  
  /// Pull to refresh callback
  void _onRefresh() async {
    await _loadGrup19Friends(isRefresh: true);
  }

  /// Son giriş zamanını formatla
  String _formatLastLoginTime(DateTime lastLoginAt) {
    final now = DateTime.now();
    final difference = now.difference(lastLoginAt);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün';
    } else {
      // Tarih formatı: "14:30" veya "15/01"
      final hour = lastLoginAt.hour.toString().padLeft(2, '0');
      final minute = lastLoginAt.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  /// Son mesaj zamanını formatla
  String _formatLastMessageTime(DateTime messageTime) {
    final now = DateTime.now();
    final difference = now.difference(messageTime);

    if (difference.inMinutes < 1) {
      return 'Şimdi';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} dk önce';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} sa önce';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      // Tarih formatı: "14:30"
      final hour = messageTime.hour.toString().padLeft(2, '0');
      final minute = messageTime.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                  SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {
                      // Global utility fonksiyonunu kullan
                      if (widget.userEmail != null) {
                        showSavedDavalarDialog(context, widget.userEmail!);
                      }
                    },
                  ),
                ],
              ),
            ),
            
            // Chat Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        showLeftIcons = !showLeftIcons;
                      });
                    },
                    child: Icon(
                      MdiIcons.menuOpen,
                      size: 34,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'SOHBETLER (${friends.length}/19)',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  if (friends.length < 19)
                    IconButton(
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                      onPressed: () {
                        // Yeni arkadaş ekle - friendship_management_page'e yönlendir
                        if (widget.userEmail != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Scaffold(
                                body: Center(
                                  child: Text('Arkadaş ekleme sayfasına yönlendirilecek'),
                                ),
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  // Yenile butonu
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () {
                      _loadGrup19Friends();
                    },
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: _isLoading
                  ? Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.grey[100]!,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        width: 150,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    )
                  : SmartRefresher(
                      controller: _refreshController,
                      onRefresh: _onRefresh,
                      enablePullDown: true,
                      enablePullUp: false,
                      header: const WaterDropHeader(
                        complete: Icon(Icons.check, color: Colors.blue),
                        waterDropColor: Colors.blue,
                      ),
                      child: Container(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Left Icons
                          if (showLeftIcons) ...[
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: 60,
                              child: SingleChildScrollView(
                                child: Column(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.campaign, size: 24, color: Colors.black54),
                                      onPressed: () {},
                                    ),
                                    const SizedBox(height: 76),
                                    const Icon(Icons.save_as_outlined, size: 24, color: Colors.black54),
                                    const SizedBox(height: 76),
                                    const Icon(Icons.edit_document, size: 24, color: Colors.black54),
                                    const SizedBox(height: 76),
                                    Image.asset('lib/icons/06_left_row_ahizelitelefon_icon.png', width: 24, height: 24),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                          ],

                          // Friends List
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Aktif arkadaşlar
                                if (activeFriends.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: Text(
                                      "🟢 Şu an Aktif Olanlar",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: 100,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: activeFriends.length,
                                      itemBuilder: (context, index) {
                                        final friend = activeFriends[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 16),
                                          child: Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 32,
                                                    backgroundImage: NetworkImage(friend.avatarUrl),
                                                    onBackgroundImageError: (_, __) {
                                                      // Hata durumunda varsayılan avatar göster
                                                    },
                                                    child: friend.avatarUrl.contains('ui-avatars.com') 
                                                        ? null 
                                                        : const Icon(Icons.person, size: 32),
                                                  ),
                                                  Positioned(
                                                    right: 0,
                                                    bottom: 0,
                                                    child: Container(
                                                      width: 14,
                                                      height: 14,
                                                      decoration: BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        color: Colors.green,
                                                        border: Border.all(color: Colors.white, width: 2),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                width: 70,
                                                child: GestureDetector(
                                                  onTap: () {
                                                    // Aktif arkadaşa tıklandığında da sohbet sayfasına git
                                                    if (friend.userModel != null) {
                                                      Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => ChatDetailPage(
                                                            receiverId: friend.userModel!.id,
                                                            receiverEmail: friend.userModel!.email,
                                                            receiverName: friend.name,
                                                            receiverAvatarUrl: friend.avatarUrl,
                                                            userEmail: widget.userEmail,
                                                          ),
                                                        ),
                                                      );
                                                    }
                                                  },
                                                  child: Text(
                                                    friend.name,
                                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                                                    textAlign: TextAlign.center,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                ],

                                // Tüm arkadaşlar listesi
                                Text(
                                  "👥 Tüm Arkadaşlar",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Expanded(
                                  child: friends.isEmpty
                                      ? Center(
                                          child: Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.people_outline,
                                                size: 64,
                                                color: Colors.grey[400],
                                              ),
                                              const SizedBox(height: 16),
                                              Text(
                                                'Grup-19 kategorisinde henüz arkadaş yok',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.grey[600],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 8),
                                              Text(
                                                'Arkadaş eklemek için yukarıdaki + butonunu kullanın',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[500],
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: friends.length,
                                          itemBuilder: (context, index) {
                                            final friend = friends[index];
                                            return Card(
                                              margin: const EdgeInsets.only(bottom: 8),
                                              elevation: 2,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(12),
                                              ),
                                              child: ListTile(
                                                leading: Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 25,
                                                      backgroundImage: NetworkImage(friend.avatarUrl),
                                                      onBackgroundImageError: (_, __) {
                                                        // Hata durumunda varsayılan avatar göster
                                                      },
                                                      child: friend.avatarUrl.contains('ui-avatars.com') 
                                                          ? null 
                                                          : const Icon(Icons.person, size: 25),
                                                    ),
                                                    if (friend.isActive)
                                                      Positioned(
                                                        right: 0,
                                                        bottom: 0,
                                                        child: Container(
                                                          width: 12,
                                                          height: 12,
                                                          decoration: BoxDecoration(
                                                            shape: BoxShape.circle,
                                                            color: Colors.green,
                                                            border: Border.all(color: Colors.white, width: 2),
                                                          ),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                                title: Text(
                                                  friend.name,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                subtitle: Text(
                                                  friend.lastMessage,
                                                  style: TextStyle(
                                                    color: Colors.grey[600],
                                                    fontSize: 12,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                trailing: Text(
                                                  friend.lastMessageTime,
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 10,
                                                  ),
                                                ),
                                                onTap: () {
                                                  // Sohbet detay sayfasına git
                                                  if (friend.userModel != null) {
                                                    Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) => ChatDetailPage(
                                                          receiverId: friend.userModel!.id,
                                                          receiverEmail: friend.userModel!.email,
                                                          receiverName: friend.name,
                                                          receiverAvatarUrl: friend.avatarUrl,
                                                          userEmail: widget.userEmail,
                                                        ),
                                                      ),
                                                    );
                                                  }
                                                },
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
} 