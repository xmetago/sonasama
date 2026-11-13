import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/hive_database_service.dart';
import '../services/friend_category_service.dart';
import '../models/friend_category_model.dart';
import '../services/user_session_service.dart';
import '../models/registration_model.dart';
import '../models/friendship_model.dart';
import 'user_gamified_score_page.dart';
import 'chat_detail_page.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/friendship_category_dialog.dart';
import '../widgets/friendship_incoming_requests_dialog.dart';
import '../widgets/friendship_user_card.dart';
import '../utils/app_theme.dart';
import '../widgets/shared/app_snack.dart';

class FriendshipManagementPage extends StatefulWidget {
  final String userEmail;
  
  const FriendshipManagementPage({
    super.key,
    required this.userEmail,
  });

  @override
  State<FriendshipManagementPage> createState() => _FriendshipManagementPageState();
}

class _FriendshipManagementPageState extends State<FriendshipManagementPage> {
  static const double _avatarSize = 48;
  static const double _actionIconSize = 16;
  static const double _headerIconSize = 18;

  // Kategori limitleri
  static const int GRUP_19_LIMIT = 19;
  static const int ARKADAS_LIMIT = 38;
  static const int TAKIPCI_LIMIT = 114;
  static const int HERKES_LIMIT = 6346; // Herkes kategorisi limiti

  // Veritabanından gelen veriler
  List<RegistrationModel> _allUsers = [];
  final List<Map<String, dynamic>> _pendingRequests = [];
  final Map<String, List<RegistrationModel>> _categorizedUsers = {
    'Grup-19': [],
    'Arkadaş': [],
    'Takipçi': [],
    'Herkes': [],
  };
  
  // Silinen ve engellenen kullanıcıları takip etmek için
  final Set<String> _deletedUserIds = {};
  final Set<String> _blockedUserIds = {};

  // Keşfet / Tümü sekmesi için önbellek kaldırıldı — kategorisiz liste dinamik hesaplanır

  // Performans bilgisi mesajları için
  String _performanceMessage = '';
  bool _showPerformanceMessage = false;
  Color _performanceMessageColor = const Color(0xFFE3F2FD); // Varsayılan mavi
  IconData _performanceMessageIcon = Icons.info_outline; // Varsayılan ikon
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool _isLoading = true;

  final List<String> _categories = ['Tümü', 'Grup-19', 'Arkadaş', 'Takipçi', 'Herkes', 'Engellenenler'];

  @override
  void initState() {
    super.initState();
    // Tek yönlü arkadaş kategorileri servisini hazırla
    FriendCategoryService.initialize().then((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Veritabanından verileri yükle
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Tüm kullanıcıları yükle
      _allUsers = HiveDatabaseService.getAllRegistrations();
      
      // Mevcut kullanıcının arkadaşlıklarını yükle
      await _loadUserFriendships();

      await _loadBlockedUsers();
      
      await _loadPendingRequests();
      
    } catch (e) {
      print('Veri yükleme hatası: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Kullanıcının arkadaş kategorilerini yükle (yeni sistem ile uyumlu)
  Future<void> _loadUserFriendships() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    try {
      // Eski email tabanlı kutudan yeni sisteme tek seferlik taşıma
      await FriendCategoryService.migrateLegacyCategoriesIfNeeded(
        ownerUserId: currentUser.id,
        ownerEmail: currentUser.email,
        allUsers: _allUsers,
      );

      // Yeni sistemden arkadaş kategorilerini çek
      final friendCategories = FriendCategoryService.listByOwner(currentUser.id);
      
      print('DEBUG: Loading friend categories for ${currentUser.email}');
      print('DEBUG: Found ${friendCategories.length} friend categories from FriendCategoryService');

      // Temizle
      _categorizedUsers.forEach((key, value) => value.clear());

      // Kategorilere göre kullanıcıları grupla
      for (final record in friendCategories) {
        final targetUserId = record.targetUserId;
        final category = record.category;
        
        // Kullanıcıyı bul
        final otherUser = _allUsers.firstWhere(
          (user) => user.id == targetUserId,
          orElse: () => RegistrationModel(
            id: targetUserId,
            judgeName: 'Bilinmeyen Kullanıcı',
            email: 'unknown@example.com',
            password: '',
            country: '',
            oath: false,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          ),
        );

        // Kategoriyi normalize et
        String normalizedCategory = category.toLowerCase();
        if (normalizedCategory.contains('grup') || normalizedCategory.contains('grup-19')) {
          normalizedCategory = 'Grup-19';
        } else if (normalizedCategory.contains('arkadaş') || normalizedCategory.contains('arkadas')) {
          normalizedCategory = 'Arkadaş';
        } else if (normalizedCategory.contains('takipçi') || normalizedCategory.contains('takipci')) {
          normalizedCategory = 'Takipçi';
        } else {
          normalizedCategory = 'Herkes';
        }

        if (_categorizedUsers.containsKey(normalizedCategory)) {
          _categorizedUsers[normalizedCategory]!.add(otherUser);
        }
      }

      print('✅ ${friendCategories.length} kategori kaydı yüklendi');
    } catch (e) {
      print('❌ Arkadaşlık yükleme hatası: $e');
    }
  }

  Future<void> _loadBlockedUsers() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    try {
      final blocked = HiveDatabaseService.getBlockedUsers(currentUser.id);
      _blockedUserIds.clear();
      _blockedUserIds.addAll(blocked.map((f) => f.recipientId));
    } catch (e) {
      print('❌ Engellenen kullanıcılar yüklenirken hata: $e');
    }
  }

  /// Herhangi bir kategoriye eklenmemiş kullanıcılar (Tümü sekmesi)
  List<RegistrationModel> _getUncategorizedUsers() {
    final currentUser = UserSessionService.getCurrentUser();
    return _allUsers.where((user) {
      if (currentUser != null && user.id == currentUser.id) return false;
      if (_isUserDeleted(user.id) || _isUserBlocked(user.id)) return false;
      return _getUserCategory(user) == null;
    }).toList();
  }

  // Bekleyen arkadaşlık isteklerini yükle
  Future<void> _loadPendingRequests() async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    try {
      // Veritabanından bekleyen arkadaşlık isteklerini yükle
      final pendingFriendships = HiveDatabaseService.getPendingFriendships(currentUser.id);
      
      _pendingRequests.clear();
      
      for (final friendship in pendingFriendships) {
        // İstek gönderen kullanıcıyı bul
        final requester = _allUsers.firstWhere(
          (user) => user.id == friendship.requesterId,
          orElse: () => RegistrationModel(
            id: friendship.requesterId,
            judgeName: 'Bilinmeyen Kullanıcı',
            email: 'unknown@example.com',
            password: '',
            country: '',
            oath: false,
            createdAt: DateTime.now(),
            lastLoginAt: DateTime.now(),
          ),
        );

        // Profil resmini SettingsModel'den de kontrol et
        final requesterSettings = HiveDatabaseService.getSettings(requester.email);
        final requesterProfileImage = requesterSettings?.profileImageUrl ?? requester.profileImage;
        
        _pendingRequests.add({
          'id': friendship.id,
          'requesterId': friendship.requesterId,
          'requesterName': requester.judgeName,
          'requesterEmail': requester.email,
          'requesterProfileImage': requesterProfileImage,
          'status': 'pending',
        });
      }

      print('✅ ${_pendingRequests.length} bekleyen arkadaşlık isteği yüklendi');
    } catch (e) {
      print('❌ Bekleyen istekler yüklenirken hata: $e');
    }
  }

  // Kategori limitlerini kontrol et
  bool _canAddToCategory(String category) {
    int currentCount = _categorizedUsers[category]?.length ?? 0;
    
    switch (category) {
      case 'Grup-19':
        return currentCount < GRUP_19_LIMIT;
      case 'Arkadaş':
        return currentCount < ARKADAS_LIMIT;
      case 'Takipçi':
        return currentCount < TAKIPCI_LIMIT;
      case 'Herkes':
        return currentCount < HERKES_LIMIT;
      default:
        return false;
    }
  }

  /// Mevcut kategoriden başka bir kategoriye taşınabilir mi?
  bool _canMoveToCategory(RegistrationModel user, String category) {
    if (_getUserCategory(user) == category) return true;
    return _canAddToCategory(category);
  }

  void _applyCategoryChange(RegistrationModel user, String category) {
    final current = _getUserCategory(user);
    if (current == category) return;
    _addUserToCategory(user, category);
  }

  // Kategori sayısını al
  int _getCategoryCount(String category) {
    if (category == 'Tümü') {
      return _getUncategorizedUsers().length;
    }
    if (category == 'Engellenenler') {
      return _allUsers.where((user) => _isUserBlocked(user.id) && !_isUserDeleted(user.id)).length;
    }
    return _categorizedUsers[category]?.length ?? 0;
  }

  // Kategori limitini al
  int _getCategoryLimit(String category) {
    switch (category) {
      case 'Grup-19':
        return GRUP_19_LIMIT;
      case 'Arkadaş':
        return ARKADAS_LIMIT;
      case 'Takipçi':
        return TAKIPCI_LIMIT;
      case 'Herkes':
        return HERKES_LIMIT;
      case 'Engellenenler':
        return -1; // Sınırsız
      default:
        return 0;
    }
  }

  // Kullanıcı arama fonksiyonu - Performans optimizasyonu
  List<RegistrationModel> _getFilteredUsers() {
    List<RegistrationModel> allUsers = [];
    
    if (_selectedCategory == 'Tümü') {
      final uncategorized = _getUncategorizedUsers();

      if (_searchQuery.isEmpty) {
        return uncategorized;
      }
      
      if (_searchQuery.length >= 4) {
        final searchLower = _searchQuery.toLowerCase();
        return uncategorized.where((user) => 
          user.judgeName.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower)
        ).take(5).toList();
      }
      
      return [];
    } else if (_selectedCategory == 'Engellenenler') {
      // Sadece engellenen kullanıcıları göster
      allUsers = _allUsers.where((user) => 
        _isUserBlocked(user.id) && !_isUserDeleted(user.id)
      ).toList();
      
      // Engellenen kullanıcılar için normal arama yap
      if (_searchQuery.isEmpty) {
        return allUsers;
      }
      
      return allUsers.where((user) => 
        user.judgeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    } else {
      // Seçili kategorideki kullanıcıları göster
      allUsers = _categorizedUsers[_selectedCategory]?.where((user) => 
        !_isUserDeleted(user.id) && !_isUserBlocked(user.id)
      ).toList() ?? [];
      
      // Kategori seçiliyse normal arama yap
      if (_searchQuery.isEmpty) {
        return allUsers;
      }
      
      return allUsers.where((user) => 
        user.judgeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        user.email.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
  }

  // Kullanıcının silinip silinmediğini kontrol et
  bool _isUserDeleted(String userId) {
    return _deletedUserIds.contains(userId);
  }

  // Kullanıcının engellenip engellenmediğini kontrol et
  bool _isUserBlocked(String userId) {
    return _blockedUserIds.contains(userId);
  }

  // Yargıç adına tıklandığında modern dialog açılır
  void _showFriendshipDialog(RegistrationModel targetUser) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FriendshipCategoryDialog(
          targetUser: targetUser,
          currentCategory: () => _getUserCategory(targetUser),
          canMoveTo: (categoryName) => _canMoveToCategory(targetUser, categoryName),
          categoryCount: _getCategoryCount,
          categoryLimit: _getCategoryLimit,
          onApply: (categoryName) => _applyCategoryChange(targetUser, categoryName),
        );
      },
    );
  }

  /// Seçilen kullanıcı ile sohbet sayfasını açar.
  void _openChatPage(RegistrationModel targetUser) {
    // Avatar URL'i oluştur (profil resmi varsa onu kullan, yoksa placeholder)
    final avatarUrl = targetUser.profileImage ?? 
      "https://ui-avatars.com/api/?name=${Uri.encodeComponent(targetUser.judgeName)}&background=random";
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChatDetailPage(
          receiverId: targetUser.id,
          receiverEmail: targetUser.email,
          receiverName: targetUser.judgeName,
          receiverAvatarUrl: avatarUrl,
          userEmail: widget.userEmail,
        ),
      ),
    );
  }

  /// Seçilen kullanıcı için oyunlaştırılmış puan ekranını açar.
  void _openUserScorePage(RegistrationModel targetUser) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => UserGamifiedScorePage(
          targetUser: targetUser,
          onManageCategory: () {
            if (!mounted) return;
            _showFriendshipDialog(targetUser);
          },
        ),
      ),
    );
  }

  Widget _buildCategoryButtonWithLimit(String title, Color color, VoidCallback onPressed) {
    bool canAdd = _canAddToCategory(title);
    int currentCount = _getCategoryCount(title);
    int limit = _getCategoryLimit(title);
    String limitText = limit == -1 ? 'Sınırsız' : '$currentCount/$limit';
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ElevatedButton(
        onPressed: canAdd ? () {
          Navigator.of(context).pop();
          onPressed();
        } : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: canAdd ? color : AppTheme.dividerColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              limitText,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Arkadaşlık isteği gönderme
  Future<void> _sendFriendshipRequest(RegistrationModel targetUser, String category) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    if (!_canAddToCategory(category)) {
      showAppSnack(context, '$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}', backgroundColor: const Color(0xFFF44336), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
      return;
    }

    try {
      setState(() {
        _categorizedUsers.forEach((cat, users) {
          users.removeWhere((u) => u.id == targetUser.id);
        });
        if (_categorizedUsers[category] != null) {
          _categorizedUsers[category]!.add(targetUser);
        }
      });

      await _saveFriendCategoryToDatabase(currentUser, targetUser, category);

      // Performans bilgisi mesajını göster
      _showPerformanceInfo(
        '✅ ${targetUser.judgeName} $category kategorisine eklendi!',
        backgroundColor: AppTheme.infoUltraLight,
        icon: Icons.person_add,
      );
    } catch (e) {
      showAppSnack(context, 'Arkadaşlık isteği gönderilirken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }

  // Gelen arkadaşlık isteği dialog'u
  void _showIncomingRequestDialog(Map<String, dynamic> request) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            '${request['requesterName']} Arkadaşlık İsteği',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${request['requesterName']} size arkadaşlık isteği gönderdi.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              const Text(
                'Bu kişiyi hangi kategoride kabul etmek istiyorsunuz?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20),
              _buildCategoryButtonWithLimit('Grup-19', AppTheme.warningColor, () => _acceptFriendship(request, 'Grup-19')),
              _buildCategoryButtonWithLimit('Arkadaş', AppTheme.successColor, () => _acceptFriendship(request, 'Arkadaş')),
              _buildCategoryButtonWithLimit('Takipçi', AppTheme.infoColor, () => _acceptFriendship(request, 'Takipçi')),
              _buildCategoryButtonWithLimit('Herkes', AppTheme.primaryColor, () => _acceptFriendship(request, 'Herkes')),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _rejectFriendship(request);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text(
                'Reddet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  // Arkadaşlık kabul etme
  Future<void> _acceptFriendship(Map<String, dynamic> request, String category) async {
    if (!_canAddToCategory(category)) {
      showAppSnack(context, '$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}', backgroundColor: const Color(0xFFF44336), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
      return;
    }

    try {
      Navigator.of(context).pop();
      
      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser == null) return;
      
      // Kullanıcıyı bul ve kategoriye ekle
      final requester = _allUsers.firstWhere(
        (user) => user.id == request['requesterId'],
        orElse: () => RegistrationModel(
          id: request['requesterId'],
          judgeName: request['requesterName'],
          email: request['requesterEmail'],
          password: '',
          country: '',
          oath: false,
          createdAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        ),
      );

      setState(() {
        if (_categorizedUsers[category] != null) {
          _categorizedUsers[category]!.add(requester);
        }
        
        // Bekleyen istekten kaldır
        _pendingRequests.removeWhere((r) => r['id'] == request['id']);
      });

      // Mevcut arkadaşlık kaydını kontrol et ve güncelle
      final existingFriendship = HiveDatabaseService.getFriendshipByUsers(
        request['requesterId'], 
        currentUser.id
      );
      
      if (existingFriendship != null) {
        final updatedFriendship = existingFriendship.copyWith(
          status: FriendshipStatus.accepted,
          updatedAt: DateTime.now(),
          message: 'Kategori: $category',
        );
        await HiveDatabaseService.updateFriendship(updatedFriendship);
      }

      await _saveFriendCategoryToDatabase(currentUser, requester, category);
      
      // Test: Kullanıcı tutarlılığını kontrol et
      _testUserCategoryConsistency();
      
      // Performans bilgisi mesajını göster
      _showPerformanceInfo(
        '✅ ${request['requesterName']} arkadaşlığı kabul edildi! Kategori: $category',
        backgroundColor: AppTheme.successUltraLight, // Yeşil arka plan
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      showAppSnack(context, 'Arkadaşlık kabul edilirken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }

  // Arkadaşlık reddetme
  Future<void> _rejectFriendship(Map<String, dynamic> request) async {
    try {
      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser == null) return;

      setState(() {
        _pendingRequests.removeWhere((r) => r['id'] == request['id']);
      });

      // Veritabanındaki arkadaşlık durumunu reddedildi olarak güncelle
      await HiveDatabaseService.updateFriendshipStatus(
        request['requesterId'], 
        currentUser.id, 
        FriendshipStatus.rejected
      );
      
      showAppSnack(context, 'Arkadaşlık reddedildi', backgroundColor: AppTheme.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    } catch (e) {
      showAppSnack(context, 'Arkadaşlık reddedilirken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }

  // Profil resmi widget'ı - Base64 ve Network URL desteği ile iyileştirilmiş
  Widget _buildProfileImage(String? imageUrl, String userName, {double size = _avatarSize}) {
    final radius = size / 2;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildDefaultAvatar(userName, size: size);
    }
    
    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',')[1];
        final imageBytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.memory(
            imageBytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(userName, size: size);
            },
          ),
        );
      } catch (e) {
        return _buildDefaultAvatar(userName, size: size);
      }
    }
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(radius),
            color: Colors.grey[300],
          ),
          child: Center(
            child: SizedBox(
              width: size * 0.4,
              height: size * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey[600]!,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(userName, size: size),
        memCacheWidth: (size * 2).round(),
        memCacheHeight: (size * 2).round(),
        maxWidthDiskCache: (size * 4).round(),
        maxHeightDiskCache: (size * 4).round(),
      ),
    );
  }

  Widget _buildDefaultAvatar(String userName, {double size = _avatarSize}) {
    final initial = userName.isNotEmpty 
        ? userName.substring(0, 1).toUpperCase() 
        : '?';
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size / 2),
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFFA1887F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.45,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    String? tooltip,
    Color? backgroundColor,
  }) {
    return Tooltip(
      message: tooltip ?? '',
      child: Material(
        color: backgroundColor ?? color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: _actionIconSize, color: color),
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Grup-19':
        return const Color(0xFFD97706);
      case 'Arkadaş':
        return AppTheme.successColor;
      case 'Takipçi':
        return AppTheme.infoColor;
      case 'Herkes':
        return AppTheme.primaryColor;
      default:
        return AppTheme.textTertiary;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Grup-19':
        return Icons.groups_outlined;
      case 'Arkadaş':
        return Icons.favorite_border;
      case 'Takipçi':
        return Icons.visibility_outlined;
      case 'Herkes':
        return Icons.public;
      case 'Engellenenler':
        return Icons.block_outlined;
      default:
        return Icons.person_outline;
    }
  }

  String _categoryTabLabel(String category) {
    if (category == 'Tümü') return 'Kategorisiz';
    return category;
  }

  Widget _buildCategoryBadge(String? category, {bool blocked = false}) {
    final label = blocked ? 'Engellenmiş' : (category ?? 'Henüz eklenmedi');
    final color = blocked
        ? AppTheme.warningColor
        : (category != null ? _categoryColor(category) : AppTheme.textSecondary);
    final icon = blocked
        ? Icons.block_outlined
        : (category != null ? _categoryIcon(category) : Icons.person_add_outlined);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.55), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTabChip(String category) {
    final isSelected = _selectedCategory == category;
    final accent = category == 'Tümü'
        ? AppTheme.infoColor
        : category == 'Engellenenler'
            ? AppTheme.textSecondary
            : _categoryColor(category);
    final count = _getCategoryCount(category);
    final limit = _getCategoryLimit(category);
    final countLabel = category == 'Tümü' || limit == -1 ? '$count' : '$count/$limit';

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedCategory = category),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? accent.withOpacity(0.12) : AppTheme.cardBackgroundColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? accent : AppTheme.dividerColor,
                width: isSelected ? 1.5 : 1,
              ),
              boxShadow: isSelected ? AppTheme.cardShadow : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _categoryIcon(category),
                  size: 14,
                  color: isSelected ? accent : AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Text(
                  _categoryTabLabel(category),
                  style: AppTheme.bodySmall.copyWith(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? accent : AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  countLabel,
                  style: AppTheme.caption.copyWith(
                    color: isSelected ? accent : AppTheme.textTertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChipBar() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: _categories.map(_buildCategoryTabChip).toList(),
      ),
    );
  }

  Widget _buildUserCard(RegistrationModel user) {
    final settings = HiveDatabaseService.getSettings(user.email);
    final profileImageUrl = settings?.profileImageUrl ?? user.profileImage;
    final category = _getUserCategory(user);
    final isBlockedSection = _selectedCategory == 'Engellenenler';
    final isAdmin = HiveDatabaseService.isAdmin(widget.userEmail);

    return FriendshipUserCard(
      avatar: _buildProfileImage(profileImageUrl, user.judgeName),
      judgeName: user.judgeName,
      categoryBadge: _buildCategoryBadge(category, blocked: isBlockedSection),
      onOpenChat: () => _openChatPage(user),
      scoreButton: _buildCompactIconButton(
        icon: Icons.star_rounded,
        color: AppTheme.warningColor,
        backgroundColor: AppTheme.warningUltraLight,
        tooltip: 'Puan',
        onTap: () => _openUserScorePage(user),
      ),
      removeButton: _buildCompactIconButton(
        icon: isAdmin ? Icons.delete_outline : Icons.block_outlined,
        color: isAdmin ? AppTheme.errorColor : AppTheme.warningColor,
        backgroundColor: isAdmin ? AppTheme.errorUltraLight : AppTheme.warningUltraLight,
        tooltip: isAdmin ? 'Kullanıcıyı Sil' : 'Kullanıcıyı Engelle',
        onTap: () => _removeUser(user),
      ),
      moreButton: _selectedCategory != 'Tümü' && !isBlockedSection
          ? _buildCompactIconButton(
              icon: Icons.more_horiz,
              color: AppTheme.textSecondary,
              tooltip: 'Kategori değiştir',
              onTap: () => _showFriendshipDialog(user),
            )
          : null,
      footer: isBlockedSection
          ? Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _unblockUser(user),
                  icon: const Icon(Icons.check_circle_outline, size: 16),
                  label: const Text('Engeli Kaldır'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.successColor,
                    side: BorderSide(color: AppTheme.successColor.withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
            )
          : _selectedCategory == 'Tümü'
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildQuickCategoryButton('Arkadaş', AppTheme.successColor, user, 'Arkadaş'),
                        const SizedBox(width: 6),
                        _buildQuickCategoryButton('Grup-19', const Color(0xFFD97706), user, 'Grup-19'),
                        const SizedBox(width: 6),
                        _buildQuickCategoryButton('Takipçi', AppTheme.infoColor, user, 'Takipçi'),
                        const SizedBox(width: 6),
                        _buildQuickCategoryButton('Herkes', AppTheme.primaryColor, user, 'Herkes'),
                      ],
                    ),
                  ),
                )
              : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredUsers = _getFilteredUsers();
    
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: AppTheme.successColor,
                ),
              )
            : Column(
                children: [
                  // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                  ),
                  
                  // Başlık ve Action Butonları - AppTheme ile modern tasarım
                  Container(
                    margin: const EdgeInsets.all(12.0),
                    padding: const EdgeInsets.all(4.0),
                    decoration: AppTheme.cardDecoration(),

                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Sol: gelen arkadaşlık istekleri
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(MdiIcons.accountHeart, color: AppTheme.successColor, size: _headerIconSize),
                                padding: const EdgeInsets.all(4),
                                visualDensity: VisualDensity.compact,
                                constraints: const BoxConstraints(
                                  minWidth: 32,
                                  minHeight: 32,
                                ),
                                onPressed: () {
                                  if (_pendingRequests.isNotEmpty) {
                                    _showIncomingRequestsList();
                                  } else {
                                    showAppSnack(context, 'Bekleyen arkadaşlık isteği yok', backgroundColor: AppTheme.infoColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ));
                                  }
                                },
                              ),
                            ),
                            if (_pendingRequests.isNotEmpty)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.accentColor,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 20,
                                    minHeight: 20,
                                  ),
                                  child: Text(
                                    '${_pendingRequests.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 10),
                        // Orta: başlık
                        Text(
                          '|| KİŞİLER ||',
                          style: AppTheme.headline4.copyWith(
                            color: AppTheme.successColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        // Sağ: toplam kişi sayısı
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.successColor.withOpacity(0.25),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            '${filteredUsers.length}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Arama alanı - AppTheme ile modern tasarım
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: AppTheme.cardDecoration(),
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _selectedCategory == 'Tümü' 
                            ? 'Kategorisiz kişilerde ara (min 4 karakter)...'
                            : 'Yargıç adı ile ara...',
                        hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                        prefixIcon: Icon(MdiIcons.magnify, color: AppTheme.successColor, size: 20),
                        prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor,
                            width: 1,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.dividerColor,
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: AppTheme.successColor,
                            width: 2,
                          ),
                        ),
                        filled: true,
                        fillColor: AppTheme.calmGreenUltraLight,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 4),
                _buildCategoryChipBar(),
                
                // Performans bilgisi (sadece Tümü sekmesinde)
                if (_selectedCategory == 'Tümü' && _searchQuery.isEmpty && _showPerformanceMessage)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _performanceMessageColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.successColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _performanceMessageIcon,
                          color: AppTheme.successColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _performanceMessage,
                            style: AppTheme.bodyMedium.copyWith(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                
                // Kullanıcı listesi - AppTheme ile modern tasarım
                Expanded(
                  child: filteredUsers.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                MdiIcons.accountOff,
                                size: 48,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedCategory == 'Tümü' && _searchQuery.isEmpty
                                    ? 'Kategorisiz kişi kalmadı'
                                    : _searchQuery.isEmpty 
                                        ? 'Henüz kullanıcı bulunamadı'
                                        : _searchQuery.length < 4
                                            ? 'En az 4 karakter girin'
                                            : '"$_searchQuery" için sonuç bulunamadı',
                                style: AppTheme.bodyLarge.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            return _buildUserCard(filteredUsers[index]);
                          },
                        ),
                ),
              ],
            ),
      ),
    );
  }

  // Kullanıcının mevcut kategorisini al
  String? _getUserCategory(RegistrationModel user) {
    for (final entry in _categorizedUsers.entries) {
      if (entry.value.any((u) => u.id == user.id)) {
        return entry.key;
      }
    }
    return null;
  }

  // Hızlı kategori değiştirme butonu - AppTheme ile modern tasarım
  Widget _buildQuickCategoryButton(String title, Color color, RegistrationModel user, String category) {
    final currentCategory = _getUserCategory(user);
    final isCurrentCategory = currentCategory == category;
    final canAdd = _canAddToCategory(category);
    
    return GestureDetector(
      onTap: () {
        if (isCurrentCategory) {
          // Mevcut kategoriden kaldır
          _removeUserFromCategory(user, category);
        } else if (canAdd) {
          // Yeni kategoriye ekle
          _addUserToCategory(user, category);
        } else {
          // Limit dolu uyarısı
          showAppSnack(context, '$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        decoration: BoxDecoration(
          color: isCurrentCategory ? color : AppTheme.calmGreenUltraLight,
          border: Border.all(
            color: isCurrentCategory ? color : AppTheme.dividerColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCurrentCategory ? Colors.white : AppTheme.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // Performans bilgisi mesajını göster - AppTheme ile modern tasarım
  void _showPerformanceInfo(String message, {Color? backgroundColor, IconData? icon}) {
    setState(() {
      _performanceMessage = message;
      _showPerformanceMessage = true;
      _performanceMessageColor = backgroundColor ?? AppTheme.infoUltraLight;
      _performanceMessageIcon = icon ?? Icons.info_outline;
    });
    
    // 5 saniye sonra mesajı gizle
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          _showPerformanceMessage = false;
        });
      }
    });
  }

  // Test fonksiyonu - Aynı kullanıcının birden fazla kategoriye eklenip eklenmediğini kontrol et
  void _testUserCategoryConsistency() {
    final allFriendships = HiveDatabaseService.getAllFriendships();
    final currentUser = UserSessionService.getCurrentUser();
    
    if (currentUser == null) return;
    
    // Her kullanıcı için kategori sayısını kontrol et
    final userCategoryCounts = <String, int>{};
    
    for (final friendship in allFriendships) {
      if (friendship.requesterId == currentUser.id || friendship.recipientId == currentUser.id) {
        final otherUserId = friendship.requesterId == currentUser.id 
            ? friendship.recipientId 
            : friendship.requesterId;
        
        userCategoryCounts[otherUserId] = (userCategoryCounts[otherUserId] ?? 0) + 1;
      }
    }
    
    // Birden fazla kategoriye eklenmiş kullanıcıları bul
    final duplicateUsers = userCategoryCounts.entries
        .where((entry) => entry.value > 1)
        .map((entry) => entry.key)
        .toList();
    
    if (duplicateUsers.isNotEmpty) {
      print('⚠️ UYARI: Aşağıdaki kullanıcılar birden fazla kategoriye eklenmiş:');
      for (final userId in duplicateUsers) {
        print('   - Kullanıcı ID: $userId (${userCategoryCounts[userId]} kategori)');
      }
    } else {
      print('✅ Tüm kullanıcılar sadece bir kategoriye eklenmiş');
    }
  }

  // Veritabanına tek yönlü kategori kaydetme
  Future<void> _saveFriendCategoryToDatabase(RegistrationModel currentUser, RegistrationModel targetUser, String category) async {
    try {
      final deterministicId = '${currentUser.id}_${targetUser.id}';
      final existing = FriendCategoryService.getByOwnerAndTarget(currentUser.id, targetUser.id);
      if (existing != null) {
        final updated = existing.copyWith(category: category, updatedAt: DateTime.now());
        await FriendCategoryService.upsert(updated);
        print('✅ Mevcut kategori kaydı güncellendi: ${updated.id}');
      } else {
        final record = FriendCategoryModel(
          id: deterministicId,
          ownerUserId: currentUser.id,
          targetUserId: targetUser.id,
          category: category,
          createdAt: DateTime.now(),
        );
        await FriendCategoryService.upsert(record);
        print('✅ Yeni kategori kaydı oluşturuldu: ${record.id}');
      }
      await HiveDatabaseService.syncCategoryFriendship(
        currentUser.id,
        targetUser.id,
        category,
      );
      await FriendCategoryService.syncLegacyBox(
        ownerEmail: currentUser.email,
        targetEmail: targetUser.email,
        category: category,
      );
    } catch (e) {
      print('❌ Kategori kaydedilirken hata: $e');
      rethrow;
    }
  }

  // Veritabanından arkadaş kategorisini kaldırma (yeni sistem)
  Future<void> _removeFriendCategoryFromDatabase(RegistrationModel currentUser, RegistrationModel targetUser) async {
    try {
      final existing = FriendCategoryService.getByOwnerAndTarget(currentUser.id, targetUser.id);
      if (existing != null) {
        await FriendCategoryService.delete(existing.id);
        print('✅ Kategori kaydı silindi: ${existing.id}');
      }
      await HiveDatabaseService.removeCategoryFriendship(currentUser.id, targetUser.id);
      await FriendCategoryService.removeLegacyBoxEntry(
        ownerEmail: currentUser.email,
        targetEmail: targetUser.email,
      );
    } catch (e) {
      print('❌ Kategori silinirken hata: $e');
      rethrow;
    }
  }

  // Kullanıcıyı kategoriye ekle
  void _addUserToCategory(RegistrationModel user, String category) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      // Önce mevcut kategorilerden kaldır
      _categorizedUsers.forEach((cat, users) {
        users.removeWhere((u) => u.id == user.id);
      });
      
      // Yeni kategoriye ekle
      if (_categorizedUsers[category] != null) {
        _categorizedUsers[category]!.add(user);
      }
    });

    // Veritabanına kaydet
    try {
      await _saveFriendCategoryToDatabase(currentUser, user, category);
      
      // Test: Kullanıcı tutarlılığını kontrol et
      _testUserCategoryConsistency();
    } catch (e) {
      print('Kategori ekleme hatası: $e');
    }
    
    // Performans bilgisi mesajını göster
    _showPerformanceInfo(
      '✅ ${user.judgeName} başarıyla $category kategorisine eklendi',
      backgroundColor: AppTheme.successUltraLight, // Yeşil arka plan
      icon: Icons.check_circle_outline,
    );
  }

  // Kullanıcıyı kategoriden kaldır
  void _removeUserFromCategory(RegistrationModel user, String category) async {
    final currentUser = UserSessionService.getCurrentUser();
    if (currentUser == null) return;

    setState(() {
      _categorizedUsers[category]?.removeWhere((u) => u.id == user.id);
    });

    // Veritabanından da kaldır (yeni sistem)
    try {
      await _removeFriendCategoryFromDatabase(currentUser, user);
    } catch (e) {
      print('Kategori kaldırma hatası: $e');
    }
    
    // Performans bilgisi mesajını göster
    _showPerformanceInfo(
      '❌ ${user.judgeName} $category kategorisinden kaldırıldı',
      backgroundColor: AppTheme.errorUltraLight, // Kırmızı arka plan
      icon: Icons.remove_circle_outline,
    );
  }

  // Gelen arkadaşlık istekleri listesi
  void _showIncomingRequestsList() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return FriendshipIncomingRequestsDialog(
          itemCount: _pendingRequests.length,
          itemBuilder: (context, index) {
                final request = _pendingRequests[index];
                
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    visualDensity: VisualDensity.compact,
                    leading: _buildProfileImage(request['requesterProfileImage'], request['requesterName'], size: 36),
                    title: Text(
                      request['requesterName'],
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildCompactIconButton(
                          icon: Icons.check,
                          color: AppTheme.successColor,
                          backgroundColor: AppTheme.successUltraLight,
                          tooltip: 'Kabul et',
                          onTap: () {
                            Navigator.of(context).pop();
                            _showIncomingRequestDialog(request);
                          },
                        ),
                        const SizedBox(width: 4),
                        _buildCompactIconButton(
                          icon: Icons.close,
                          color: AppTheme.errorColor,
                          backgroundColor: AppTheme.errorUltraLight,
                          tooltip: 'Reddet',
                          onTap: () {
                            Navigator.of(context).pop();
                            _rejectFriendship(request);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
        );
      },
    );
  }

  // Kullanıcı engelleme/kaldırma
  Future<void> _removeUser(RegistrationModel user) async {
    final isAdmin = HiveDatabaseService.isAdmin(widget.userEmail);
    
    if (isAdmin) {
      // Admin kullanıcı - Silme işlemi
      await _deleteUserAsAdmin(user);
    } else {
      // Normal kullanıcı - Engelleme işlemi
      await _blockUser(user);
    }
  }

  // Admin kullanıcı için silme işlemi
  Future<void> _deleteUserAsAdmin(RegistrationModel user) async {
    try {
      // Onay dialog'u göster
      bool? shouldDelete = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Kullanıcıyı Sil',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Text(
              '${user.judgeName} kullanıcısını tüm kategorilerden silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!',
              style: const TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'İptal',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text(
                  'Sil',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      if (shouldDelete != true) return;

      // Loading göster
      setState(() {
        _isLoading = true;
      });

      // Kullanıcıyı silinenler listesine ekle
      setState(() {
        _deletedUserIds.add(user.id);
        
        // Tüm kategorilerden kullanıcıyı kaldır
        _categorizedUsers.forEach((category, users) {
          users.removeWhere((u) => u.id == user.id);
        });
        
        // Bekleyen isteklerden de kaldır
        _pendingRequests.removeWhere((r) => r['requesterId'] == user.id);
      });

      // Veritabanından da sil
      try {
        await HiveDatabaseService.deleteRegistration(user.id);
      } catch (e) {
        print('Veritabanından silme hatası: $e');
      }

      // Loading'i kapat
      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, '${user.judgeName} başarıyla silindi', backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, 'Kullanıcı silinirken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }

  // Normal kullanıcı için engelleme işlemi
  Future<void> _blockUser(RegistrationModel user) async {
    try {
      // Engelleme onay dialog'u göster
      bool? shouldBlock = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Kullanıcıyı Engelle',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${user.judgeName} kullanıcısını engellemek istediğinizden emin misiniz?',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3E0),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFF9800)),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Engelleme sonrası:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF9800),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '• Tüm kategorilerden çıkarılır',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '• Artık arkadaşlık isteği gönderemez',
                        style: TextStyle(fontSize: 14),
                      ),
                      Text(
                        '• İstediğiniz zaman engeli kaldırabilirsiniz',
                        style: TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text(
                  'İptal',
                  style: TextStyle(fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF9800)),
                child: const Text(
                  'Engelle',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },
      );

      if (shouldBlock != true) return;

      // Loading göster
      setState(() {
        _isLoading = true;
      });

      // Kullanıcıyı engellenenler listesine ekle
      setState(() {
        _blockedUserIds.add(user.id);
        
        _categorizedUsers.forEach((category, users) {
          users.removeWhere((u) => u.id == user.id);
        });
        
        _pendingRequests.removeWhere((r) => r['requesterId'] == user.id);
      });

      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser != null) {
        await HiveDatabaseService.blockUser(currentUser.id, user.id);
        await _removeFriendCategoryFromDatabase(currentUser, user);
      }

      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, '${user.judgeName} başarıyla engellendi', backgroundColor: AppTheme.warningColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ), action: SnackBarAction(
            label: 'Engeli Kaldır',
            textColor: Colors.white,
            onPressed: () => _unblockUser(user),
          ));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, 'Kullanıcı engellenirken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }

  // Kullanıcı engelini kaldırma
  Future<void> _unblockUser(RegistrationModel user) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Kullanıcıyı engellenenler listesinden çıkar
      setState(() {
        _blockedUserIds.remove(user.id);
      });

      final currentUser = UserSessionService.getCurrentUser();
      if (currentUser != null) {
        await HiveDatabaseService.unblockUser(currentUser.id, user.id);
      }

      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, '${user.judgeName} engeli kaldırıldı', backgroundColor: AppTheme.successColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      showAppSnack(context, 'Engel kaldırılırken hata oluştu: $e', backgroundColor: AppTheme.errorColor, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ));
    }
  }
}
