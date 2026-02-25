import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
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
import '../utils/app_theme.dart';

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
  
  // Performans bilgisi mesajları için
  String _performanceMessage = '';
  bool _showPerformanceMessage = false;
  Color _performanceMessageColor = const Color(0xFFE3F2FD); // Varsayılan mavi
  IconData _performanceMessageIcon = Icons.info_outline; // Varsayılan ikon
  
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'Tümü';
  bool _isCategoryDropdownOpen = false;
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
      
      // Bekleyen arkadaşlık isteklerini yükle
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

  // Kategori sayısını al
  int _getCategoryCount(String category) {
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
      // Tüm kullanıcıları göster, ancak silinen ve engellenen kullanıcıları filtrele
      allUsers = _allUsers.where((user) => 
        !_isUserDeleted(user.id) && !_isUserBlocked(user.id)
      ).toList();
      
      // Performans optimizasyonu: Arama yapılmadan önce sadece 19 rastgele kullanıcı göster
      if (_searchQuery.isEmpty) {
        // Rastgele 19 kullanıcı seç (veya daha az varsa hepsini)
        if (allUsers.length > 19) {
          allUsers.shuffle(); // Rastgele karıştır
          allUsers = allUsers.take(19).toList();
        }
        return allUsers;
      }
      
      // Arama yapılıyorsa ve 4+ karakter girildiyse, en yakın 5 sonuç döndür
      if (_searchQuery.length >= 4) {
        final searchLower = _searchQuery.toLowerCase();
        final matchingUsers = allUsers.where((user) => 
          user.judgeName.toLowerCase().contains(searchLower) ||
          user.email.toLowerCase().contains(searchLower)
        ).toList();
        
        // En yakın 5 sonuç döndür
        return matchingUsers.take(5).toList();
      }
      
      // 4 karakterden az girildiyse hiçbir sonuç gösterme
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
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
              maxWidth: MediaQuery.of(context).size.width * 0.9,
            ),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header bölümü
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.successColor, AppTheme.successDarkColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person_add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                targetUser.judgeName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                targetUser.email,
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Açıklama metni
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.calmGreenUltraLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.successColor,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu kişinin puanı',
                            style: AppTheme.bodySmall.copyWith(
                              color: AppTheme.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Kategori seçenekleri - Flexible ile sarılmış
                  Flexible(
                    child: _buildModernCategoryGrid(targetUser),
                  ),

                  const SizedBox(height: 16),

                  // İptal butonu
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: AppTheme.textButtonStyle.copyWith(
                        padding: MaterialStateProperty.all(
                          const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      child: Text(
                        'İptal',
                        style: AppTheme.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  // Modern kategori grid widget'ı
  Widget _buildModernCategoryGrid(RegistrationModel targetUser) {
    final categories = <Map<String, dynamic>>[
      {
        'title': 'Grup-19',
        'color': AppTheme.warningColor,
        'icon': Icons.group,
        'description': 'En yakın 19 arkadaş',
        'category': 'Grup-19',
      },
      {
        'title': 'Arkadaş',
        'color': AppTheme.successColor,
        'icon': Icons.favorite,
        'description': 'Güvenilir arkadaşlar',
        'category': 'Arkadaş',
      },
      {
        'title': 'Takipçi',
        'color': AppTheme.infoColor,
        'icon': Icons.visibility,
        'description': 'Takip ettiğiniz kişiler',
        'category': 'Takipçi',
      },
      {
        'title': 'Herkes',
        'color': AppTheme.primaryColor,
        'icon': Icons.public,
        'description': 'Tüm kullanıcılar',
        'category': 'Herkes',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final categoryName = category['category'] as String;
        final categoryColor = category['color'] as Color;
        final canAdd = _canAddToCategory(categoryName);
        final currentCount = _getCategoryCount(categoryName);
        final limit = _getCategoryLimit(categoryName);
        final limitText = limit == -1 ? '∞' : '$currentCount/$limit';
        
        return GestureDetector(
          onTap: canAdd ? () {
            Navigator.of(context).pop();
            _sendFriendshipRequest(targetUser, categoryName);
          } : null,
          child: Container(
            decoration: BoxDecoration(
              gradient: canAdd 
                ? LinearGradient(
                    colors: [
                      categoryColor,
                      categoryColor.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
              color: canAdd ? null : AppTheme.dividerColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: canAdd ? [
                BoxShadow(
                  color: categoryColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ] : null,
            ),
            child: Stack(
              children: [
                                 // Arka plan deseni
                 if (canAdd)
                   Positioned(
                     right: -8,
                     bottom: -8,
                     child: Icon(
                       category['icon'] as IconData,
                       size: 40,
                       color: Colors.white.withOpacity(0.1),
                     ),
                   ),

                                 // İçerik
                 Padding(
                   padding: const EdgeInsets.all(12),
                   child: Column(
                     crossAxisAlignment: CrossAxisAlignment.start,
                     children: [
                       // İkon ve limit
                       Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           Container(
                             padding: const EdgeInsets.all(6),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(6),
                             ),
                             child: Icon(
                               category['icon'] as IconData,
                               color: Colors.white,
                               size: 16,
                             ),
                           ),
                           Container(
                             padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.2),
                               borderRadius: BorderRadius.circular(8),
                             ),
                             child: Text(
                               limitText,
                               style: const TextStyle(
                                 color: Colors.white,
                                 fontSize: 10,
                                 fontWeight: FontWeight.bold,
                               ),
                             ),
                           ),
                         ],
                       ),

                       const Spacer(),

                       // Başlık
                       Text(
                         category['title'] as String,
                         style: const TextStyle(
                           color: Colors.white,
                           fontSize: 14,
                           fontWeight: FontWeight.bold,
                         ),
                       ),

                       const SizedBox(height: 2),

                       // Açıklama
                       Text(
                         category['description'] as String,
                         style: TextStyle(
                           color: Colors.white.withOpacity(0.8),
                           fontSize: 10,
                         ),
                         maxLines: 1,
                         overflow: TextOverflow.ellipsis,
                       ),
                     ],
                   ),
                 ),

                // Dolu kategori overlay'i
                if (!canAdd)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.lock,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}'),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }

    try {
      // Kullanıcıyı kategoriye ekle
      setState(() {
        if (_categorizedUsers[category] != null) {
          _categorizedUsers[category]!.add(targetUser);
        }
      });

      // Veritabanına tek yönlü kategori kaydet
      await _saveFriendCategoryToDatabase(currentUser, targetUser, category);

      // Performans bilgisi mesajını göster
      _showPerformanceInfo(
        '📤 ${targetUser.judgeName} için $category kategorisinde arkadaşlık isteği gönderildi!',
        backgroundColor: AppTheme.infoUltraLight, // Mavi arka plan
        icon: Icons.send,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadaşlık isteği gönderilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Email: ${request['requesterEmail']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}'),
          backgroundColor: const Color(0xFFF44336),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
        // Mevcut kaydı güncelle
        final updatedFriendship = existingFriendship.copyWith(
          status: FriendshipStatus.accepted,
          updatedAt: DateTime.now(),
          message: 'Kategori: $category',
        );
        await HiveDatabaseService.updateFriendship(updatedFriendship);
        print('✅ Mevcut arkadaşlık güncellendi: ${existingFriendship.id}');
      } else {
        // Yeni arkadaşlık kaydını veritabanına kaydet
        await _saveFriendCategoryToDatabase(currentUser, requester, category);
      }
      
      // Test: Kullanıcı tutarlılığını kontrol et
      _testUserCategoryConsistency();
      
      // Performans bilgisi mesajını göster
      _showPerformanceInfo(
        '✅ ${request['requesterName']} arkadaşlığı kabul edildi! Kategori: $category',
        backgroundColor: AppTheme.successUltraLight, // Yeşil arka plan
        icon: Icons.check_circle_outline,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadaşlık kabul edilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Arkadaşlık reddedildi'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Arkadaşlık reddedilirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Grup-19 ikonu widget'ı - "19" rakamını güzel bir şekilde gösterir
  Widget _buildGrup19Icon({double size = 24, Color color = Colors.purple}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color,
            color.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          '19',
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.6,
            fontWeight: FontWeight.bold,
            letterSpacing: -1,
          ),
        ),
      ),
    );
  }

  // Profil resmi widget'ı - Base64 ve Network URL desteği ile iyileştirilmiş
  Widget _buildProfileImage(String? imageUrl, String userName) {
    // Eğer profil resmi yoksa veya boşsa, direkt icon göster
    if (imageUrl == null || imageUrl.isEmpty) {
      return _buildDefaultAvatar(userName);
    }
    
    // Base64 formatındaki resimleri kontrol et (data:image/...;base64,...)
    if (imageUrl.startsWith('data:image')) {
      try {
        // Base64 string'i çıkar
        final base64String = imageUrl.split(',')[1];
        final imageBytes = base64Decode(base64String);
        
        return ClipRRect(
          borderRadius: BorderRadius.circular(25),
          child: Image.memory(
            imageBytes,
            width: 50,
            height: 50,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildDefaultAvatar(userName);
            },
          ),
        );
      } catch (e) {
        // Base64 decode hatası durumunda varsayılan avatar göster
        return _buildDefaultAvatar(userName);
      }
    }
    
    // Network URL'leri için CachedNetworkImage kullan
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: CachedNetworkImage(
        imageUrl: imageUrl,
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            color: Colors.grey[300],
          ),
          child: Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey[600]!,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => _buildDefaultAvatar(userName),
        memCacheWidth: 100,
        memCacheHeight: 100,
        maxWidthDiskCache: 200,
        maxHeightDiskCache: 200,
      ),
    );
  }

  // Varsayılan avatar widget'ı
  Widget _buildDefaultAvatar(String userName) {
    // Kullanıcı adının ilk harfini göster
    final initial = userName.isNotEmpty 
        ? userName.substring(0, 1).toUpperCase() 
        : '?';
    
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(25),
        gradient: const LinearGradient(
          colors: [Color(0xFF8D6E63), Color(0xFFA1887F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          initial,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),

                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 8,
                                children: [
                                  Text(
                                    "KİŞİLER",
                                    style: AppTheme.headline4.copyWith(
                                      color: AppTheme.successColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Gelen arkadaşlık istekleri (MdiIcons.accountHeart)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(MdiIcons.accountHeart, color: AppTheme.successColor, size: 20),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: () {
                                  if (_pendingRequests.isNotEmpty) {
                                    _showIncomingRequestsList();
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Bekleyen arkadaşlık isteği yok'),
                                        backgroundColor: AppTheme.infoColor,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
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
                        const SizedBox(width: 8),
                        // Bildirimler (MdiIcons.bell)
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                color: AppTheme.successColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                icon: Icon(MdiIcons.bell, color: AppTheme.successColor, size: 20),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 40,
                                  minHeight: 40,
                                ),
                                onPressed: () {
                                  _showNotifications();
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
                        const SizedBox(width: 12),
                        // Toplam kişi sayısı badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.successColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${filteredUsers.length}',
                            style: TextStyle(
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
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.successColor.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      style: AppTheme.bodyMedium,
                      decoration: InputDecoration(
                        hintText: _selectedCategory == 'Tümü' 
                            ? 'En az 4 karakter girerek arama yapın...'
                            : 'Yargıç adı veya email ile ara...',
                        hintStyle: AppTheme.bodySmall.copyWith(color: AppTheme.textTertiary),
                        prefixIcon: Icon(MdiIcons.magnify, color: AppTheme.successColor),
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
                  const SizedBox(height:7),

                // Kategori seçici - AppTheme ile modern tasarım
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isCategoryDropdownOpen = !_isCategoryDropdownOpen;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    _selectedCategory,
                                    style: AppTheme.headline4.copyWith(
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  // Grup-19 kategorisi seçiliyse sayıyı göster
                                  if (_selectedCategory == 'Grup-19') ...[
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warningColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        '${_getCategoryCount('Grup-19')}/${_getCategoryLimit('Grup-19')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.warningColor,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              Icon(
                                _isCategoryDropdownOpen ? MdiIcons.chevronUp : MdiIcons.chevronDown,
                                color: AppTheme.successColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isCategoryDropdownOpen)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackgroundColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.successColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: _categories.map((category) {
                              int count = _getCategoryCount(category);
                              int limit = _getCategoryLimit(category);
                              String limitText = limit == -1 ? 'Sınırsız' : '$count/$limit';
                              
                              final isSelected = category == _selectedCategory;
                              
                              return InkWell(
                                onTap: () {
                                  setState(() {
                                    _selectedCategory = category;
                                    _isCategoryDropdownOpen = false;
                                  });
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: isSelected 
                                        ? AppTheme.successColor.withOpacity(0.1)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        category,
                                        style: AppTheme.bodyMedium.copyWith(
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                          color: isSelected ? AppTheme.successColor : AppTheme.textPrimary,
                                        ),
                                      ),
                                      Text(
                                        limitText,
                                        style: AppTheme.bodySmall.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                    ],
                  ),
                ),
                
                // Performans bilgisi (sadece Tümü sekmesinde) - AppTheme ile modern tasarım
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
                                size: 64,
                                color: AppTheme.textMuted,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _selectedCategory == 'Tümü' && _searchQuery.isEmpty
                                    ? 'Rastgele 19 kullanıcı gösteriliyor'
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
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (context, index) {
                            final user = filteredUsers[index];
                            
                            // Profil resmini SettingsModel'den de kontrol et
                            final settings = HiveDatabaseService.getSettings(user.email);
                            final profileImageUrl = settings?.profileImageUrl ?? user.profileImage;
                            
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: AppTheme.cardBackgroundColor,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.successColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Kullanıcı bilgileri
                                  ListTile(
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                                    leading: _buildProfileImage(profileImageUrl, user.judgeName),
                                    title: InkWell(
                                      onTap: () => _openChatPage(user),
                                      child: Text(
                                        user.judgeName,
                                        style: AppTheme.headline4.copyWith(
                                          color: AppTheme.successColor,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                    subtitle: Text(
                                      user.email,
                                      style: AppTheme.bodySmall.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Yıldız/puan ikonu - tıklanabilir
                                        GestureDetector(
                                          onTap: () => _openUserScorePage(user),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.infoColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: _buildGrup19Icon(size: 24, color: AppTheme.infoColor),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () => _openUserScorePage(user),
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppTheme.warningColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Icon(
                                              Icons.star_rate,
                                              color: AppTheme.warningColor,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        // Çöp/engelleme ikonu
                                        Container(
                                          decoration: BoxDecoration(
                                            color: HiveDatabaseService.isAdmin(widget.userEmail) 
                                                ? AppTheme.errorUltraLight  // Admin için kırmızı (silme)
                                                : AppTheme.warningUltraLight, // Normal kullanıcı için turuncu (engelleme)
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              HiveDatabaseService.isAdmin(widget.userEmail) 
                                                  ? Icons.delete  // Admin için silme ikonu
                                                  : Icons.block_outlined,  // Normal kullanıcı için engelleme ikonu
                                              color: HiveDatabaseService.isAdmin(widget.userEmail) 
                                                  ? AppTheme.errorColor  // Admin için kırmızı
                                                  : AppTheme.warningColor, // Normal kullanıcı için turuncu
                                            ),
                                            onPressed: () => _removeUser(user),
                                            tooltip: HiveDatabaseService.isAdmin(widget.userEmail) 
                                                ? 'Kullanıcıyı Sil' 
                                                : 'Kullanıcıyı Engelle',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                                                     // Kategori seçenekleri veya engel kaldırma butonu
                                   Container(
                                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                     child: Column(
                                       crossAxisAlignment: CrossAxisAlignment.start,
                                       children: [
                                         if (_selectedCategory == 'Engellenenler') ...[
                                           // Engellenen kullanıcılar için sadece engel kaldırma butonu
                                           Container(
                                             padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                             decoration: BoxDecoration(
                                               color: AppTheme.warningUltraLight,
                                               border: Border.all(color: AppTheme.warningColor),
                                               borderRadius: BorderRadius.circular(20),
                                             ),
                                             child: Text(
                                               'Engellenmiş',
                                               style: TextStyle(
                                                 color: AppTheme.warningColor,
                                                 fontWeight: FontWeight.w600,
                                                 fontSize: 12,
                                               ),
                                             ),
                                           ),
                                           const SizedBox(height: 8),
                                           SizedBox(
                                             width: double.infinity,
                                             child: ElevatedButton.icon(
                                               onPressed: () => _unblockUser(user),
                                               icon: const Icon(Icons.check_circle_outline, size: 16),
                                               label: const Text('Engeli Kaldır'),
                                               style: AppTheme.successButtonStyle.copyWith(
                                                 padding: MaterialStateProperty.all(
                                                   const EdgeInsets.symmetric(vertical: 12),
                                                 ),
                                               ),
                                             ),
                                           ),
                                         ] else ...[
                                           // Normal kategoriler için kategori seçenekleri
                                           // Mevcut kategori gösterimi
                                           Container(
                                             padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                                             decoration: BoxDecoration(
                                               color: AppTheme.successUltraLight,
                                               border: Border.all(color: AppTheme.successColor),
                                               borderRadius: BorderRadius.circular(20),
                                             ),
                                             child: Text(
                                               _getUserCategory(user) ?? 'Kullanıcı',
                                               style: TextStyle(
                                                 color: AppTheme.successColor,
                                                 fontWeight: FontWeight.w600,
                                                 fontSize: 12,
                                               ),
                                             ),
                                           ),
                                           const SizedBox(height: 8),

                                           // Kategori değiştirme butonları
                                           Row(
                                             children: [
                                               Expanded(
                                                 child: _buildQuickCategoryButton(
                                                   'Arkadaş',
                                                   AppTheme.successColor,
                                                   user,
                                                   'Arkadaş',
                                                 ),
                                               ),
                                               const SizedBox(width: 8),
                                               Expanded(
                                                 child: _buildQuickCategoryButton(
                                                   'Grup-19',
                                                   AppTheme.warningColor,
                                                   user,
                                                   'Grup-19',
                                                 ),
                                               ),
                                               const SizedBox(width: 8),
                                               Expanded(
                                                 child: _buildQuickCategoryButton(
                                                   'Takipçi',
                                                   AppTheme.infoColor,
                                                   user,
                                                   'Takipçi',
                                                 ),
                                               ),
                                               const SizedBox(width: 8),
                                               Expanded(
                                                 child: _buildQuickCategoryButton(
                                                   'Herkes',
                                                   AppTheme.primaryColor,
                                                   user,
                                                   'Herkes',
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
                            );
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$category kategorisi dolu! Limit: ${_getCategoryLimit(category)}'),
              backgroundColor: AppTheme.errorColor,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isCurrentCategory ? color : AppTheme.calmGreenUltraLight,
          border: Border.all(
            color: isCurrentCategory ? color : AppTheme.dividerColor,
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isCurrentCategory ? Colors.white : AppTheme.textSecondary,
            fontSize: 12,
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
      print('✅ Veritabanına kaydediliyor...');
      print('✅ Kalıcı olarak saklanıyor...');
      print('✅ Uygulama yeniden başlatıldığında korunuyor...');
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
      print('✅ Veritabanından kaldırıldı...');
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
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Gelen Arkadaşlık İstekleri',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
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
                    contentPadding: const EdgeInsets.all(12),
                    leading: _buildProfileImage(request['requesterProfileImage'], request['requesterName']),
                    title: Text(
                      request['requesterName'],
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Text(
                      request['requesterEmail'],
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE8F5E8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.check, color: Color(0xFF4CAF50)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showIncomingRequestDialog(request);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: IconButton(
                            icon: const Icon(Icons.close, color: Color(0xFFF44336)),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _rejectFriendship(request);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Kapat',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  // Bildirimler dialog'u
  void _showNotifications() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Bildirimler',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: _pendingRequests.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Yeni bildirim yok',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
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
                          contentPadding: const EdgeInsets.all(12),
                          leading: _buildProfileImage(
                            request['requesterProfileImage'], 
                            request['requesterName']
                          ),
                          title: Text(
                            '${request['requesterName']} arkadaşlık isteği gönderdi',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            request['requesterEmail'],
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFE3F2FD),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.arrow_forward_ios,
                                color: Color(0xFF1976D2),
                                size: 16,
                              ),
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showIncomingRequestDialog(request);
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Kapat',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ],
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
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.judgeName} başarıyla silindi'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı silinirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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
        
        // Tüm kategorilerden kullanıcıyı kaldır
        _categorizedUsers.forEach((category, users) {
          users.removeWhere((u) => u.id == user.id);
        });
        
        // Bekleyen isteklerden de kaldır
        _pendingRequests.removeWhere((r) => r['requesterId'] == user.id);
      });

      // Loading'i kapat
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.judgeName} başarıyla engellendi'),
          backgroundColor: AppTheme.warningColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          action: SnackBarAction(
            label: 'Engeli Kaldır',
            textColor: Colors.white,
            onPressed: () => _unblockUser(user),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Kullanıcı engellenirken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
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

      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.judgeName} engeli kaldırıldı'),
          backgroundColor: AppTheme.successColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Engel kaldırılırken hata oluştu: $e'),
          backgroundColor: AppTheme.errorColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }
}
