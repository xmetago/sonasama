import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../services/friend_category_service.dart';
import '../services/user_session_service.dart';
import '../services/chat_service.dart';
import '../models/registration_model.dart';
import 'chat_detail_page.dart';
import 'friendship_management_page.dart';
import 'package:its19/utils/app_logger.dart';

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
  /// Test: sohbet listesi yüklenemesin.
  final bool forceLoadError;

  const ChatPage({super.key, this.userEmail, this.forceLoadError = false});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  bool _isLoading = true;
  String? _loadError;
  final RefreshController _refreshController = RefreshController(initialRefresh: false);
  
  // Gerçek veriler için friends listesi
  List<Friend> friends = [];

  List<Friend> get activeFriends => friends.where((friend) => friend.isActive).toList();

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // FriendCategoryService'i başlat ve verileri yükle
    FriendCategoryService.initialize().then((_) {
      _loadGrup19Friends();
    });
  }

  /// Oturum yoksa sayfaya verilen e-postadan kullanıcıyı aç.
  RegistrationModel? _resolveCurrentUser() {
    final session = UserSessionService.getCurrentUser();
    if (session != null) return session;
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) return null;
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(email);
      if (user != null) {
        UserSessionService.setCurrentUser(user);
      }
      return user;
    } catch (_) {
      return null;
    }
  }

  /// Grup-19 kategorisindeki kullanıcıları yükle
  Future<void> _loadGrup19Friends({bool isRefresh = false}) async {
    if (!isRefresh) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      if (widget.forceLoadError) {
        throw Exception('Sohbetler yüklenemedi');
      }
      final currentUser = _resolveCurrentUser();
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          friends = [];
          _loadError = 'Giriş gerekli. Sohbetleri görmek için oturum aç.';
        });
        if (isRefresh) {
          _refreshController.refreshFailed();
        }
        return;
      }

      // Tüm kullanıcıları al
      final allUsers = HiveDatabaseService.getAllRegistrations();

      await FriendCategoryService.migrateLegacyCategoriesIfNeeded(
        ownerUserId: currentUser.id,
        ownerEmail: currentUser.email,
        allUsers: allUsers,
      );

      // Normalize edilmiş kategoriyi kontrol et
      final allCategories = FriendCategoryService.listByOwner(currentUser.id);
      final grup19UserIds = <String>{};
      
      for (final category in allCategories) {
        final categoryLower = category.category.toLowerCase();
        if (categoryLower.contains('grup') && categoryLower.contains('19')) {
          grup19UserIds.add(category.targetUserId);
        }
      }

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
          appLog('⚠️ Kullanıcı bulunamadı: $userId');
        }
      }

      // Kullanıcıları online durumuna göre sırala (önce online olanlar)
      friends.sort((a, b) {
        if (a.isActive && !b.isActive) return -1;
        if (!a.isActive && b.isActive) return 1;
        return 0;
      });

      appLog('✅ Grup-19 kategorisinden ${friends.length} kullanıcı yüklendi');
      
      setState(() {
        _isLoading = false;
        _loadError = null;
      });
      
      if (isRefresh) {
        _refreshController.refreshCompleted();
      }
    } catch (e) {
      appLog('❌ Arkadaşlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
        friends = [];
        _loadError = 'Sohbetler yüklenemedi';
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

  String? get _sessionEmail =>
      widget.userEmail ?? UserSessionService.getCurrentUser()?.email;

  Future<void> _openChat(Friend friend) async {
    final user = friend.userModel;
    if (user == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          receiverId: user.id,
          receiverEmail: user.email,
          receiverName: friend.name,
          receiverAvatarUrl: friend.avatarUrl,
          userEmail: widget.userEmail,
        ),
      ),
    );
    if (!mounted) return;
    await _loadGrup19Friends();
  }

  void _openAddFriend() {
    final email = _sessionEmail;
    if (email == null || email.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FriendshipManagementPage(userEmail: email),
      ),
    );
  }

  void _openSavedDavalar() {
    final email = _sessionEmail;
    if (email == null || email.isEmpty) return;
    showSavedDavalarDialog(context, email);
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

  Widget _mutedRailIcon(SeyirPalette palette, IconData icon) {
    return IgnorePointer(
      child: SizedBox(
        width: SeyirTokens.tapTarget,
        height: SeyirTokens.tapTarget,
        child: Icon(icon, size: 24, color: palette.textMuted),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final email = _sessionEmail;
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          inset: _isLoading ? EdgeInsets.zero : const EdgeInsets.all(SeyirTokens.space4),
          openGap: _isLoading ? 0 : SeyirTokens.space4,
          panelWidth: _isLoading ? 0 : 60,
          items: [
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: _mutedRailIcon(palette, Icons.campaign),
            ),
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: Column(
                children: [
                  const SizedBox(height: 76),
                  if (email == null || email.isEmpty)
                    _mutedRailIcon(palette, Icons.save_as_outlined)
                  else
                    IconButton(
                      tooltip: 'Kayıtlı davalar',
                      style: delilIconButtonStyle(foreground: palette.textPrimary),
                      onPressed: _openSavedDavalar,
                      icon: Icon(Icons.save_as_outlined, size: 24, color: palette.textPrimary),
                    ),
                  const SizedBox(height: 76),
                  _mutedRailIcon(palette, Icons.edit_document),
                  const SizedBox(height: 76),
                  Image.asset(
                    'lib/icons/06_left_row_ahizelitelefon_icon.png',
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header Section
            Container(
              color: palette.card,
              child: Column(
                children: [
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                  SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {
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
              color: palette.card,
              padding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space4,
                vertical: SeyirTokens.space2,
              ),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Menü',
                    style: delilIconButtonStyle(foreground: Colors.red),
                    onPressed: toggle,
                    icon: const Icon(
                      MdiIcons.menuOpen,
                      size: 28,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: SeyirTokens.space4),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
                      decoration: const BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: SeyirTokens.radiusMdAll,
                      ),
                      child: Text(
                        'SOHBETLER (${friends.length}/19)',
                        textAlign: TextAlign.center,
                        style: palette.title(color: Colors.white),
                      ),
                    ),
                  ),
                  if (friends.length < 19)
                    IconButton(
                      tooltip: 'Arkadaş ekle',
                      style: delilIconButtonStyle(foreground: Colors.green),
                      icon: const Icon(Icons.person_add_alt_1, color: Colors.green),
                      onPressed: _openAddFriend,
                    ),
                  IconButton(
                    tooltip: 'Yenile',
                    style: delilIconButtonStyle(foreground: Colors.blue),
                    icon: const Icon(Icons.refresh, color: Colors.blue),
                    onPressed: () {
                      _loadGrup19Friends();
                    },
                  ),
                ],
              ),
            ),

              ],
            );
          },
          body: _isLoading
                  ? Shimmer.fromColors(
                      baseColor: palette.surfaceMuted,
                      highlightColor: palette.card,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(SeyirTokens.space4),
                        itemCount: 5,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: SeyirTokens.space3),
                            child: Row(
                              children: [
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: palette.border,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: SeyirTokens.space3),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: double.infinity,
                                        height: 16,
                                        decoration: BoxDecoration(
                                          color: palette.border,
                                          borderRadius: SeyirTokens.radiusSmAll,
                                        ),
                                      ),
                                      const SizedBox(height: SeyirTokens.space2),
                                      Container(
                                        width: 150,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: palette.border,
                                          borderRadius: SeyirTokens.radiusSmAll,
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
                      child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (activeFriends.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: SeyirTokens.space4),
                                    child: Text(
                                      "🟢 Şu an Aktif Olanlar",
                                      style: palette.body(
                                        weight: FontWeight.w700,
                                        color: palette.textSecondary,
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
                                          padding: const EdgeInsets.only(right: SeyirTokens.space4),
                                          child: Column(
                                            children: [
                                              Stack(
                                                children: [
                                                  CircleAvatar(
                                                    radius: 32,
                                                    backgroundImage: NetworkImage(friend.avatarUrl),
                                                    onBackgroundImageError: (_, __) {},
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
                                                        border: Border.all(color: palette.card, width: 2),
                                                      ),
                                                    ),
                                                  )
                                                ],
                                              ),
                                              const SizedBox(height: 6),
                                              SizedBox(
                                                width: 70,
                                                child: GestureDetector(
                                                  onTap: () => _openChat(friend),
                                                  child: Text(
                                                    friend.name,
                                                    style: palette.caption(
                                                      weight: FontWeight.w500,
                                                      color: palette.textPrimary,
                                                    ),
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
                                  const SizedBox(height: SeyirTokens.space6),
                                ],

                                if (_loadError == null) ...[
                                  Text(
                                    "👥 Tüm Arkadaşlar",
                                    style: palette.body(
                                      weight: FontWeight.w700,
                                      color: palette.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: SeyirTokens.space3),
                                ],
                                Expanded(
                                  child: _loadError != null
                                      ? DelilLoadError(
                                          message: _loadError!,
                                          onRetry: _loadGrup19Friends,
                                        )
                                      : friends.isEmpty
                                      ? const Center(
                                          child: DelilSoftEmpty(
                                            title: 'Grup-19 kategorisinde henüz arkadaş yok',
                                            message: 'Arkadaş eklemek için yukarıdaki + butonunu kullanın',
                                            icon: Icons.people_outline,
                                          ),
                                        )
                                      : ListView.builder(
                                          itemCount: friends.length,
                                          itemBuilder: (context, index) {
                                            final friend = friends[index];
                                            return Card(
                                              color: palette.card,
                                              margin: const EdgeInsets.only(bottom: SeyirTokens.space2),
                                              elevation: 0,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: SeyirTokens.radiusMdAll,
                                                side: BorderSide(color: palette.border),
                                              ),
                                              child: ListTile(
                                                leading: Stack(
                                                  children: [
                                                    CircleAvatar(
                                                      radius: 25,
                                                      backgroundImage: NetworkImage(friend.avatarUrl),
                                                      onBackgroundImageError: (_, __) {},
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
                                                            border: Border.all(color: palette.card, width: 2),
                                                          ),
                                                        ),
                                                      )
                                                  ],
                                                ),
                                                title: Text(
                                                  friend.name,
                                                  style: palette.body(weight: FontWeight.w700),
                                                ),
                                                subtitle: Text(
                                                  friend.lastMessage,
                                                  style: palette.caption(color: palette.textSecondary),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                trailing: Text(
                                                  friend.lastMessageTime,
                                                  style: palette.caption(color: palette.textMuted),
                                                ),
                                                onTap: () => _openChat(friend),
                                              ),
                                            );
                                          },
                                        ),
                                ),
                              ],
                            ),
                      ),
        ),
      ),
    );
  }
}
