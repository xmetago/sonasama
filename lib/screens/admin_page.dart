import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import 'package:its19/services/hive_database_service.dart';
import 'package:its19/services/verified_users_service.dart';
import 'package:its19/models/registration_model.dart';
import 'package:its19/models/category_model.dart';
import 'database_debug_page.dart';
import 'reklam_yonetim_page.dart';

/// Admin sayfası - Sadece admin yetkisine sahip kullanıcılar erişebilir
/// Kullanıcı yönetimi, veritabanı istatistikleri ve sistem ayarları içerir
class AdminPage extends StatefulWidget {
  final String adminEmail;

  const AdminPage({super.key, required this.adminEmail});

  @override
  _AdminPageState createState() => _AdminPageState();
}

/// Admin sayfasının durum yönetimi
/// Kullanıcı listesi ve veritabanı istatistiklerini yönetir
class _AdminPageState extends State<AdminPage> {
  List<RegistrationModel> allUsers = [];
  List<RegistrationModel> filteredUsers = [];
  List<CategoryModel> allCategories = [];
  List<CategoryModel> filteredCategories = [];
  List<Map<String, dynamic>> allDavalar = [];
  List<Map<String, dynamic>> filteredDavalar = [];
  Map<String, int> databaseStats = {};
  
  // Arama ve filtreleme kontrolcüleri
  final TextEditingController _userSearchController = TextEditingController();
  final TextEditingController _categorySearchController = TextEditingController();
  final TextEditingController _davaSearchController = TextEditingController();
  String _userFilter = 'all'; // all, admin, active, verified, locked
  String _davaFilter = 'all'; // all, opened, saved
  
  // Toplu seçim
  bool _isSelectionMode = false;
  Set<String> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Arama dinleyicileri ekle
    _userSearchController.addListener(_filterUsers);
    _categorySearchController.addListener(_filterCategories);
    _davaSearchController.addListener(_filterDavalar);
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _categorySearchController.dispose();
    _davaSearchController.dispose();
    super.dispose();
  }

  /// Veritabanından kullanıcı listesi, kategori listesi ve istatistikleri yükler
  void _loadData() {
    setState(() {
      allUsers = HiveDatabaseService.getAllRegistrations();
      allCategories = HiveDatabaseService.getAllCategories();
      databaseStats = HiveDatabaseService.getDatabaseStats();
      
      // Tüm davaları yükle (açılan + kaydedilen)
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      final savedDavalar = HiveDatabaseService.getSavedDavalar();
      
      // Davaları birleştir ve işaretle
      allDavalar = [
        ...openedDavalar.map((d) => {...d, 'davaType': 'opened'}),
        ...savedDavalar.map((d) => {...d, 'davaType': 'saved'}),
      ];
      
      // Filtreleme uygula
      _filterUsers();
      _filterCategories();
      _filterDavalar();
    });
  }

  /// Kullanıcıları arama ve filtre kriterlerine göre filtreler
  void _filterUsers() {
    final query = _userSearchController.text.toLowerCase().trim();
    
    setState(() {
      filteredUsers = allUsers.where((user) {
        // Arama kriteri
        final matchesSearch = query.isEmpty ||
            user.email.toLowerCase().contains(query) ||
            user.judgeName.toLowerCase().contains(query) ||
            user.country.toLowerCase().contains(query);
        
        // Filtre kriteri
        final matchesFilter = _userFilter == 'all' ||
            (_userFilter == 'admin' && user.isAdmin) ||
            (_userFilter == 'active' && user.isActive) ||
            (_userFilter == 'verified' && user.isEmailVerified) ||
            (_userFilter == 'locked' && user.isLocked);
        
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  /// Kategorileri arama kriterine göre filtreler
  void _filterCategories() {
    final query = _categorySearchController.text.toLowerCase().trim();
    
    setState(() {
      filteredCategories = query.isEmpty
          ? List.from(allCategories)
          : allCategories.where((category) {
              return category.name.toLowerCase().contains(query) ||
                  category.subCategories.any((sub) => sub.toLowerCase().contains(query));
            }).toList();
    });
  }

  /// Davaları arama ve filtre kriterlerine göre filtreler
  void _filterDavalar() {
    final query = _davaSearchController.text.toLowerCase().trim();
    
    setState(() {
      filteredDavalar = allDavalar.where((dava) {
        // Arama kriteri - Dava ID veya Dava Adı
        final davaId = (dava['id'] ?? '').toString().toLowerCase();
        final davaAdi = (dava['davaAdi'] ?? dava['adi'] ?? '').toString().toLowerCase();
        final davaci = (dava['davaci'] ?? '').toString().toLowerCase();
        final davali = (dava['davali'] ?? '').toString().toLowerCase();
        
        final matchesSearch = query.isEmpty ||
            davaId.contains(query) ||
            davaAdi.contains(query) ||
            davaci.contains(query) ||
            davali.contains(query);
        
        // Filtre kriteri
        final davaType = dava['davaType'] ?? 'opened';
        final matchesFilter = _davaFilter == 'all' ||
            (_davaFilter == 'opened' && davaType == 'opened') ||
            (_davaFilter == 'saved' && davaType == 'saved');
        
        return matchesSearch && matchesFilter;
      }).toList();
      
      // Tarihe göre sırala (en yeni üstte)
      filteredDavalar.sort((a, b) {
        final aDate = a['openedAt'] ?? '';
        final bDate = b['openedAt'] ?? '';
        return bDate.toString().compareTo(aDate.toString());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Paneli'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Admin Bilgileri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(FeatherIcons.shield, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Admin Bilgileri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('E-posta: ${widget.adminEmail}'),
                      const Text('Yetki: Admin'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Debug Sayfası Butonu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(FeatherIcons.database, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Veritabanı Debug',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const DatabaseDebugPage(),
                              ),
                            );
                          },
                          icon: const Icon(FeatherIcons.eye),
                          label: const Text('Veritabanı Detaylarını Görüntüle'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reklam Yönetimi Butonu
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.campaign, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Reklam Yönetimi',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ReklamYonetimPage(adminEmail: widget.adminEmail),
                              ),
                            );
                          },
                          icon: const Icon(Icons.ads_click),
                          label: const Text('Reklamları Yönet'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF059669),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Veritabanı İstatistikleri
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.bar_chart, color: Color(0xFF059669)),
                          SizedBox(width: 8),
                          Text(
                            'Veritabanı İstatistikleri',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Toplam Kullanıcı', '${databaseStats['kayitlar'] ?? 0}', Icons.people),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Aktif Kullanıcı', '${allUsers.where((u) => u.isActive).length}', Icons.check_circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Doğrulanmış E-posta', '${allUsers.where((u) => u.isEmailVerified).length}', Icons.email),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Admin Sayısı', '${allUsers.where((u) => u.isAdmin).length}', Icons.admin_panel_settings),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Toplam Dava', '${databaseStats['davalar'] ?? 0}', Icons.gavel),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Açılan Davalar', '${databaseStats['acilan_davalar'] ?? 0}', Icons.check_circle_outline),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Kaydedilen', '${databaseStats['kaydedilen_davalar'] ?? 0}', Icons.save_outlined),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Toplam Yorum', '${databaseStats['yorumlar'] ?? 0}', Icons.comment),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kategori Yönetimi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.category, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Kategori Yönetimi (${filteredCategories.length}/${allCategories.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          ElevatedButton.icon(
                            onPressed: _addNewCategory,
                            icon: const Icon(Icons.add),
                            label: const Text('Yeni Kategori'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF059669),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Kategori arama çubuğu
                      TextField(
                        controller: _categorySearchController,
                        decoration: InputDecoration(
                          hintText: 'Kategori ara...',
                          prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFF059669)),
                          suffixIcon: _categorySearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _categorySearchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard('Toplam Kategori', '${allCategories.length}', Icons.category),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard('Aktif Kategori', '${allCategories.where((c) => c.isActive).length}', Icons.check_circle),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 300,
                        child: filteredCategories.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.category_outlined, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Kategori bulunamadı',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredCategories.length,
                                itemBuilder: (context, index) {
                                  final category = filteredCategories[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: category.isActive ? const Color(0xFF059669) : Colors.grey,
                                  child: Text(
                                    '${index + 1}',
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  category.name,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: category.isActive ? Colors.black : Colors.grey,
                                  ),
                                ),
                                subtitle: Text(
                                  '${category.subCategories.length} alt kategori • ${category.totalDavalar} dava',
                                  style: TextStyle(
                                    color: category.isActive ? Colors.grey[600] : Colors.grey,
                                  ),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: Icon(
                                        category.isActive ? Icons.visibility : Icons.visibility_off,
                                        color: category.isActive ? const Color(0xFF059669) : Colors.grey,
                                      ),
                                      onPressed: () => _toggleCategoryVisibility(category),
                                      tooltip: category.isActive ? 'Gizle' : 'Göster',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: Color(0xFF059669)),
                                      onPressed: () => _editCategory(category),
                                      tooltip: 'Düzenle',
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () => _deleteCategory(category),
                                      tooltip: 'Sil',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Dava Arama ve Listesi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.gavel, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Dava Listesi (${filteredDavalar.length}/${allDavalar.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Dava arama çubuğu
                      TextField(
                        controller: _davaSearchController,
                        decoration: InputDecoration(
                          hintText: 'Dava ara (ID, ad, davacı, davalı)...',
                          prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFF059669)),
                          suffixIcon: _davaSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _davaSearchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Filtre chipleri
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildDavaFilterChip('Tümü', 'all'),
                            const SizedBox(width: 8),
                            _buildDavaFilterChip('Açılan', 'opened'),
                            const SizedBox(width: 8),
                            _buildDavaFilterChip('Kaydedilen', 'saved'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Dava istatistikleri
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatCard(
                              'Açılan', 
                              '${allDavalar.where((d) => d['davaType'] == 'opened').length}',
                              Icons.check_circle_outline,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildStatCard(
                              'Kaydedilen', 
                              '${allDavalar.where((d) => d['davaType'] == 'saved').length}',
                              Icons.save_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Dava listesi
                      SizedBox(
                        height: 400,
                        child: filteredDavalar.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.gavel, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Dava bulunamadı',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredDavalar.length,
                                itemBuilder: (context, index) {
                                  final dava = filteredDavalar[index];
                                  final davaType = dava['davaType'] ?? 'opened';
                                  final isOpened = davaType == 'opened';
                                  
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: isOpened 
                                            ? const Color(0xFF059669)
                                            : Colors.orange,
                                        child: Icon(
                                          isOpened ? Icons.check_circle : Icons.save,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ),
                                      title: Text(
                                        dava['davaAdi']?.toString() ?? dava['adi']?.toString() ?? 'İsimsiz Dava',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'ID: ${dava['id'] ?? 'Bilinmiyor'}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[600],
                                              fontFamily: 'monospace',
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              const Icon(Icons.person, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  'Davacı: ${dava['davaci'] ?? 'Bilinmiyor'}',
                                                  style: const TextStyle(fontSize: 12),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (dava['davali'] != null && dava['davali'].toString().isNotEmpty)
                                            Row(
                                              children: [
                                                const Icon(Icons.person_outline, size: 12, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    'Davalı: ${dava['davali']}',
                                                    style: const TextStyle(fontSize: 12),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          const SizedBox(height: 4),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: isOpened 
                                                  ? const Color(0xFF059669).withOpacity(0.1)
                                                  : Colors.orange.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isOpened ? const Color(0xFF059669) : Colors.orange,
                                                width: 1,
                                              ),
                                            ),
                                            child: Text(
                                              isOpened ? 'AÇILDI' : 'KAYDEDİLDİ',
                                              style: TextStyle(
                                                color: isOpened ? const Color(0xFF059669) : Colors.orange,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: PopupMenuButton<String>(
                                        itemBuilder: (context) => <PopupMenuEntry<String>>[
                                          const PopupMenuItem<String>(
                                            value: 'details',
                                            child: Row(
                                              children: [
                                                Icon(Icons.info_outline, color: Colors.blue),
                                                SizedBox(width: 8),
                                                Text('Detaylar'),
                                              ],
                                            ),
                                          ),
                                          const PopupMenuDivider(),
                                          const PopupMenuItem<String>(
                                            value: 'delete',
                                            child: Row(
                                              children: [
                                                Icon(Icons.delete, color: Colors.red),
                                                SizedBox(width: 8),
                                                Text('Sil', style: TextStyle(color: Colors.red)),
                                              ],
                                            ),
                                          ),
                                        ],
                                        onSelected: (value) {
                                          if (value == 'details') {
                                            _showDavaDetails(dava);
                                          } else if (value == 'delete') {
                                            _deleteDava(dava);
                                          }
                                        },
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Kullanıcı Listesi
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(FeatherIcons.users, color: Color(0xFF059669)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _isSelectionMode 
                                  ? 'Seçili: ${_selectedUserIds.length} kullanıcı'
                                  : 'Kullanıcı Listesi (${filteredUsers.length}/${allUsers.length})',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (!_isSelectionMode)
                            IconButton(
                              icon: const Icon(Icons.checklist),
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = true;
                                  _selectedUserIds.clear();
                                });
                              },
                              tooltip: 'Toplu seçim modu',
                            )
                          else ...[
                            IconButton(
                              icon: const Icon(Icons.select_all),
                              onPressed: () {
                                setState(() {
                                  if (_selectedUserIds.length == filteredUsers.length) {
                                    _selectedUserIds.clear();
                                  } else {
                                    _selectedUserIds = filteredUsers.map((u) => u.id).toSet();
                                  }
                                });
                              },
                              tooltip: 'Tümünü seç/kaldır',
                            ),
                            PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              tooltip: 'Toplu işlemler',
                              itemBuilder: (context) => <PopupMenuEntry<String>>[
                                const PopupMenuItem<String>(
                                  value: 'lock',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Seçilenleri Kilitle'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'unlock',
                                  child: Row(
                                    children: [
                                      Icon(Icons.lock_open, color: Colors.orange),
                                      SizedBox(width: 8),
                                      Text('Seçilenleri Aç'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'activate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person, color: Colors.green),
                                      SizedBox(width: 8),
                                      Text('Seçilenleri Aktif Yap'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'deactivate',
                                  child: Row(
                                    children: [
                                      Icon(Icons.person_off, color: Colors.grey),
                                      SizedBox(width: 8),
                                      Text('Seçilenleri Pasif Yap'),
                                    ],
                                  ),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(
                                    children: [
                                      Icon(Icons.delete, color: Colors.red),
                                      SizedBox(width: 8),
                                      Text('Seçilenleri Sil', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (_selectedUserIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Lütfen en az bir kullanıcı seçin'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                  return;
                                }
                                
                                if (value == 'lock') {
                                  _bulkLockUsers(true);
                                } else if (value == 'unlock') {
                                  _bulkLockUsers(false);
                                } else if (value == 'activate') {
                                  _bulkActivateUsers(true);
                                } else if (value == 'deactivate') {
                                  _bulkActivateUsers(false);
                                } else if (value == 'delete') {
                                  _bulkDeleteUsers();
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setState(() {
                                  _isSelectionMode = false;
                                  _selectedUserIds.clear();
                                });
                              },
                              tooltip: 'Seçim modundan çık',
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Arama çubuğu
                      TextField(
                        controller: _userSearchController,
                        decoration: InputDecoration(
                          hintText: 'Kullanıcı ara (email, isim, ülke)...',
                          prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFF059669)),
                          suffixIcon: _userSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _userSearchController.clear();
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Filtre chipleri
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFilterChip('Tümü', 'all'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Adminler', 'admin'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Aktif', 'active'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Doğrulanmış', 'verified'),
                            const SizedBox(width: 8),
                            _buildFilterChip('Kilitli', 'locked'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      SizedBox(
                        height: 400,
                        child: filteredUsers.isEmpty
                            ? const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(FeatherIcons.userX, size: 48, color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Kullanıcı bulunamadı',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: filteredUsers.length,
                                itemBuilder: (context, index) {
                                  final user = filteredUsers[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: _isSelectionMode
                                    ? Checkbox(
                                        value: _selectedUserIds.contains(user.id),
                                        onChanged: (selected) {
                                          setState(() {
                                            if (selected == true) {
                                              _selectedUserIds.add(user.id);
                                            } else {
                                              _selectedUserIds.remove(user.id);
                                            }
                                          });
                                        },
                                        activeColor: const Color(0xFF059669),
                                      )
                                    : CircleAvatar(
                                        backgroundColor: user.isAdmin 
                                            ? Colors.red 
                                            : Colors.green,
                                        child: Icon(
                                          user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                                          color: Colors.white,
                                        ),
                                      ),
                                onTap: _isSelectionMode
                                    ? () {
                                        setState(() {
                                          if (_selectedUserIds.contains(user.id)) {
                                            _selectedUserIds.remove(user.id);
                                          } else {
                                            _selectedUserIds.add(user.id);
                                          }
                                        });
                                      }
                                    : null,
                                title: Text(
                                  user.judgeName,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(user.email),
                                    Row(
                                      children: [
                                        if (user.isAdmin)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'ADMIN',
                                              style: TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                        if (user.isEmailVerified)
                                          Container(
                                            margin: const EdgeInsets.only(left: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.green,
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'DOĞRULANDI',
                                              style: TextStyle(color: Colors.white, fontSize: 10),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  itemBuilder: (context) => <PopupMenuEntry<String>>[
                                    const PopupMenuItem<String>(
                                      value: 'details',
                                      child: Row(
                                        children: [
                                          Icon(Icons.info_outline, color: Colors.blue),
                                          SizedBox(width: 8),
                                          Text('Detaylar'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit, color: Color(0xFF059669)),
                                          SizedBox(width: 8),
                                          Text('Düzenle'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'toggle_lock',
                                      child: Row(
                                        children: [
                                          Icon(
                                            user.isLocked ? Icons.lock_open : Icons.lock,
                                            color: user.isLocked ? Colors.orange : Colors.red,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(user.isLocked ? 'Kilidi Aç' : 'Kilitle'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'toggle_admin',
                                      child: Row(
                                        children: [
                                          Icon(
                                            user.isAdmin ? Icons.remove_moderator : Icons.admin_panel_settings,
                                            color: user.isAdmin ? Colors.grey : Colors.blue,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(user.isAdmin ? 'Admin Kaldır' : 'Admin Yap'),
                                        ],
                                      ),
                                    ),
                                    PopupMenuItem<String>(
                                      value: 'toggle_active',
                                      child: Row(
                                        children: [
                                          Icon(
                                            user.isActive ? Icons.person_off : Icons.person,
                                            color: user.isActive ? Colors.grey : Colors.green,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(user.isActive ? 'Pasif Yap' : 'Aktif Yap'),
                                        ],
                                      ),
                                    ),
                                    const PopupMenuDivider(),
                                    const PopupMenuItem<String>(
                                      value: 'delete',
                                      child: Row(
                                        children: [
                                          Icon(Icons.delete, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Sil', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  onSelected: (value) async {
                                    if (value == 'details') {
                                      _showUserDetails(user);
                                    } else if (value == 'edit') {
                                      _editUser(user);
                                    } else if (value == 'delete') {
                                      _deleteUser(user);
                                    } else if (value == 'toggle_lock') {
                                      await _toggleUserLock(user);
                                    } else if (value == 'toggle_admin') {
                                      await _toggleUserAdmin(user);
                                    } else if (value == 'toggle_active') {
                                      await _toggleUserActive(user);
                                    }
                                  },
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Kullanıcı filtre chip'i oluşturur
  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _userFilter == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _userFilter = filterValue;
          _filterUsers();
        });
      },
      selectedColor: const Color(0xFF059669).withOpacity(0.2),
      checkmarkColor: const Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Dava filtre chip'i oluşturur
  Widget _buildDavaFilterChip(String label, String filterValue) {
    final isSelected = _davaFilter == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _davaFilter = filterValue;
          _filterDavalar();
        });
      },
      selectedColor: const Color(0xFF059669).withOpacity(0.2),
      checkmarkColor: const Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// İstatistik kartı widget'ı oluşturur
  /// Başlık, değer ve icon parametreleri alır
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF059669)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Kullanıcı düzenleme modalını açar
  /// Seçilen kullanıcının bilgilerini gösterir ve düzenleyebilir
  void _editUser(RegistrationModel user) {
    final nameController = TextEditingController(text: user.judgeName);
    final countryController = TextEditingController(text: user.country);
    bool isAdmin = user.isAdmin;
    bool isActive = user.isActive;
    bool isEmailVerified = user.isEmailVerified;
    // Mavi tik durumunu kontrol et (yargıç adı bazlı)
    bool isVerified = VerifiedUsersService.isVerified(user.judgeName);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(FeatherIcons.edit, color: Color(0xFF059669)),
                const SizedBox(width: 8),
                Expanded(child: Text('${user.judgeName} Düzenle')),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // E-posta (salt okunur)
                  TextField(
                    controller: TextEditingController(text: user.email),
                    decoration: const InputDecoration(
                      labelText: 'E-posta',
                      border: OutlineInputBorder(),
                      enabled: false,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Kullanıcı Adı
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Kullanıcı Adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Ülke
                  TextField(
                    controller: countryController,
                    decoration: const InputDecoration(
                      labelText: 'Ülke',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Admin Switch
                  SwitchListTile(
                    title: const Text('Admin Yetkisi'),
                    subtitle: const Text('Kullanıcıya admin yetkisi ver'),
                    value: isAdmin,
                    activeThumbColor: const Color(0xFF059669),
                    onChanged: (value) {
                      setDialogState(() {
                        isAdmin = value;
                      });
                    },
                  ),
                  
                  // Mavi Tik Switch
                  SwitchListTile(
                    title: Row(
                      children: [
                        const Text('Mavi Tik (Ünlü Kişi)'),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.verified,
                          size: 20,
                          color: isVerified ? Colors.blue : Colors.grey,
                        ),
                      ],
                    ),
                    subtitle: const Text('Kullanıcıyı ünlü olarak işaretle. Açtığı ve ona açılan davalar "Davacı Ünlü/Davalı Ünlü" sayfalarında görünür.'),
                    value: isVerified,
                    activeThumbColor: Colors.blue,
                    onChanged: (value) {
                      setDialogState(() {
                        isVerified = value;
                      });
                    },
                  ),
                  
                  // Aktif Switch
                  SwitchListTile(
                    title: const Text('Aktif'),
                    subtitle: const Text('Kullanıcı hesabı aktif'),
                    value: isActive,
                    activeThumbColor: const Color(0xFF059669),
                    onChanged: (value) {
                      setDialogState(() {
                        isActive = value;
                      });
                    },
                  ),
                  
                  // Email Doğrulama Switch
                  SwitchListTile(
                    title: const Text('E-posta Doğrulandı'),
                    subtitle: const Text('E-posta adresi doğrulandı'),
                    value: isEmailVerified,
                    activeThumbColor: const Color(0xFF059669),
                    onChanged: (value) {
                      setDialogState(() {
                        isEmailVerified = value;
                      });
                    },
                  ),
                  
                  // Giriş Denemesi Sıfırlama
                  if (user.loginAttempts > 0)
                    ListTile(
                      leading: const Icon(Icons.lock_reset, color: Colors.orange),
                      title: const Text('Giriş Denemeleri'),
                      subtitle: Text('${user.loginAttempts} başarısız deneme'),
                      trailing: TextButton(
                        onPressed: () async {
                          final resetUser = user.copyWith(loginAttempts: 0);
                          await HiveDatabaseService.updateRegistration(resetUser);
                          setDialogState(() {});
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Giriş denemeleri sıfırlandı'),
                              backgroundColor: Colors.orange,
                            ),
                          );
                        },
                        child: const Text('Sıfırla'),
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  // Güncellenmiş kullanıcı modeli oluştur
                  final updatedUser = user.copyWith(
                    judgeName: nameController.text.trim(),
                    country: countryController.text.trim(),
                    isAdmin: isAdmin,
                    isActive: isActive,
                    isEmailVerified: isEmailVerified,
                  );
                  
                  // Veritabanına kaydet
                  await HiveDatabaseService.updateRegistration(updatedUser);
                  
                  // Mavi tik durumunu güncelle (yargıç adı bazlı)
                  // Eğer yargıç adı değiştiyse, eski adı kaldır ve yeni adı ekle
                  final oldJudgeName = user.judgeName;
                  final newJudgeName = nameController.text.trim();
                  
                  // Eski yargıç adı verified ise kaldır
                  if (oldJudgeName.isNotEmpty && VerifiedUsersService.isVerified(oldJudgeName)) {
                    await VerifiedUsersService.setVerified(oldJudgeName, false);
                  }
                  
                  // Yeni yargıç adına mavi tik ver/iptal et
                  if (newJudgeName.isNotEmpty) {
                    await VerifiedUsersService.setVerified(newJudgeName, isVerified);
                  }
                  
                  // Dialog'u kapat
                  Navigator.pop(context);
                  
                  // Veriyi yenile
                  _loadData();
                  
                  // Başarı mesajı
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${updatedUser.judgeName} başarıyla güncellendi${isVerified ? ' (Mavi tik verildi ✓)' : ''}',
                      ),
                      backgroundColor: const Color(0xFF059669),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Kullanıcı detaylarını gösteren modal
  void _showUserDetails(RegistrationModel user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.person, color: Color(0xFF059669)),
            const SizedBox(width: 8),
            Expanded(
              child: Text('${user.judgeName} - Detaylar'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Temel Bilgiler
                _buildDetailSection(
                  'Temel Bilgiler',
                  Icons.person_outline,
                  [
                    _buildDetailRow('Kullanıcı Adı', user.judgeName),
                    _buildDetailRow('E-posta', user.email),
                    _buildDetailRow('Ülke', user.country),
                    _buildDetailRow('Kullanıcı ID', user.id),
                  ],
                ),
                const Divider(height: 24),
                
                // Hesap Durumu
                _buildDetailSection(
                  'Hesap Durumu',
                  Icons.security,
                  [
                    _buildDetailRow('Yetki', user.isAdmin ? 'Admin' : 'Kullanıcı', 
                      valueColor: user.isAdmin ? Colors.red : null),
                    _buildDetailRow('Durum', user.isActive ? 'Aktif' : 'Pasif',
                      valueColor: user.isActive ? Colors.green : Colors.grey),
                    _buildDetailRow('E-posta Doğrulama', user.isEmailVerified ? 'Doğrulandı' : 'Bekliyor',
                      valueColor: user.isEmailVerified ? Colors.blue : Colors.orange),
                    _buildDetailRow('Giriş İzni', user.canLogin ? 'Var' : 'Yok',
                      valueColor: user.canLogin ? Colors.green : Colors.red),
                    _buildDetailRow('Hesap Durumu', user.isLocked ? 'Kilitli (5+ hatalı giriş)' : 'Açık',
                      valueColor: user.isLocked ? Colors.red : Colors.green),
                  ],
                ),
                const Divider(height: 24),
                
                // Tarih Bilgileri
                _buildDetailSection(
                  'Tarih Bilgileri',
                  Icons.calendar_today,
                  [
                    _buildDetailRow('Kayıt Tarihi', _formatDateTime(user.createdAt)),
                    _buildDetailRow('Son Giriş', _formatDateTime(user.lastLoginAt)),
                    if (user.lastDavaAcTime case final lastDavaAc?)
                      _buildDetailRow('Son Dava Açma', _formatDateTime(lastDavaAc)),
                    if (user.lastHaykirTime case final lastHaykir?)
                      _buildDetailRow('Son Haykırma', _formatDateTime(lastHaykir)),
                  ],
                ),
                const Divider(height: 24),
                
                // Güvenlik Bilgileri
                _buildDetailSection(
                  'Güvenlik Bilgileri',
                  Icons.lock_outline,
                  [
                    _buildDetailRow('Şifre Uzunluğu', '${user.password.length} karakter'),
                    _buildDetailRow('Giriş Denemesi', '${user.loginAttempts}',
                      valueColor: user.loginAttempts > 0 ? Colors.orange : null),
                    if (user.lastLoginAttemptAt case final lastAttempt?)
                      _buildDetailRow('Son Giriş Denemesi', _formatDateTime(lastAttempt)),
                  ],
                ),
                
                // Veritabanı istatistikleri ekleyebiliriz (opsiyonel)
                const Divider(height: 24),
                _buildDetailSection(
                  'Aktivite Özeti',
                  Icons.analytics_outlined,
                  [
                    _buildDetailRow('Açılan Davalar', 'Yükleniyor...'),
                    _buildDetailRow('Katılınan Davalar', 'Yükleniyor...'),
                    _buildDetailRow('Yapılan Yorumlar', 'Yükleniyor...'),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _editUser(user);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Düzenle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Detay bölümü widget'ı
  Widget _buildDetailSection(String title, IconData icon, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF059669)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF059669),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }

  /// Detay satırı widget'ı
  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: valueColor ?? Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarih formatla
  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  /// Kullanıcı kilitleme durumunu değiştirir
  Future<void> _toggleUserLock(RegistrationModel user) async {
    // Admin kendi hesabını kilitleyemez
    final lock = !user.isLocked;
    if (lock && user.email == widget.adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı kilitleyemezsiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Kilitle: 5+ giriş denemesi yap, Aç: 0'a sıfırla
    final updated = user.copyWith(loginAttempts: lock ? 5 : 0);
    await HiveDatabaseService.updateRegistration(updated);
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          lock 
              ? '${user.judgeName} kilitlendi' 
              : '${user.judgeName} kilidi açıldı',
        ),
        backgroundColor: lock ? Colors.red : Colors.orange,
      ),
    );
  }

  /// Kullanıcı admin durumunu değiştirir
  Future<void> _toggleUserAdmin(RegistrationModel user) async {
    // Admin kendi yetkisini kaldıramaz
    if (user.isAdmin && user.email == widget.adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi admin yetkinizi kaldıramazsınız!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final updated = user.copyWith(isAdmin: !user.isAdmin);
    await HiveDatabaseService.updateRegistration(updated);
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isAdmin 
              ? '${user.judgeName} admin yetkisi verildi' 
              : '${user.judgeName} admin yetkisi kaldırıldı',
        ),
        backgroundColor: const Color(0xFF059669),
      ),
    );
  }

  /// Kullanıcı aktif durumunu değiştirir
  Future<void> _toggleUserActive(RegistrationModel user) async {
    // Admin kendini pasif yapamaz
    if (user.isActive && user.email == widget.adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı pasif yapamazsınız!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final updated = user.copyWith(isActive: !user.isActive);
    await HiveDatabaseService.updateRegistration(updated);
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          updated.isActive 
              ? '${user.judgeName} aktif hale getirildi' 
              : '${user.judgeName} pasif hale getirildi',
        ),
        backgroundColor: updated.isActive ? Colors.green : Colors.grey,
      ),
    );
  }

  /// Kullanıcı silme onay modalını açar
  /// Silme işlemi için kullanıcıdan onay alır
  void _deleteUser(RegistrationModel user) {
    // Admin kendi hesabını silemez
    if (user.email == widget.adminEmail) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı silemezsiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kullanıcı Sil'),
        content: Text('${user.judgeName} kullanıcısını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveDatabaseService.deleteRegistration(user.id);
              Navigator.pop(context);
              _loadData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${user.judgeName} silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ========== DAVA YÖNETİMİ METODLARI ==========

  /// Dava detaylarını gösteren modal
  void _showDavaDetails(Map<String, dynamic> dava) {
    final isOpened = dava['davaType'] == 'opened';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isOpened ? Icons.check_circle : Icons.save,
              color: isOpened ? const Color(0xFF059669) : Colors.orange,
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('Dava Detayları'),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: SizedBox(
            width: double.maxFinite,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Dava ID', dava['id']?.toString() ?? 'Bilinmiyor'),
                _buildDetailRow('Dava Adı', dava['davaAdi']?.toString() ?? dava['adi']?.toString() ?? 'İsimsiz'),
                _buildDetailRow('Durum', isOpened ? 'Açıldı' : 'Kaydedildi',
                  valueColor: isOpened ? const Color(0xFF059669) : Colors.orange),
                const Divider(height: 24),
                
                _buildDetailRow('Davacı', dava['davaci']?.toString() ?? 'Bilinmiyor'),
                if (dava['davali'] != null && dava['davali'].toString().isNotEmpty)
                  _buildDetailRow('Davalı', dava['davali'].toString()),
                const Divider(height: 24),
                
                if (dava['davaKonusu'] != null && dava['davaKonusu'].toString().isNotEmpty)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dava Konusu:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF059669),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: Text(
                          dava['davaKonusu'].toString(),
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                      const Divider(height: 24),
                    ],
                  ),
                
                if (dava['kategori'] != null)
                  _buildDetailRow('Kategori', dava['kategori'].toString()),
                if (dava['mevkii'] != null)
                  _buildDetailRow('Mevki', dava['mevkii'].toString()),
                if (dava['kalanSure'] != null)
                  _buildDetailRow('Tarih', dava['kalanSure'].toString()),
                if (dava['openedAt'] != null)
                  _buildDetailRow('Açılma Zamanı', _formatDateTime(DateTime.parse(dava['openedAt'].toString()))),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _deleteDava(dava);
            },
            icon: const Icon(Icons.delete),
            label: const Text('Sil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  /// Dava silme onay modalı
  void _deleteDava(Map<String, dynamic> dava) {
    final isOpened = dava['davaType'] == 'opened';
    final davaAdi = dava['davaAdi']?.toString() ?? dava['adi']?.toString() ?? 'İsimsiz Dava';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Dava Sil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$davaAdi isimli davayı silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning, color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu işlem geri alınamaz!',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              // Dava tipine göre sil
              if (isOpened) {
                HiveDatabaseService.deleteOpenedDava(dava['id'].toString());
              } else {
                HiveDatabaseService.deleteSavedDava(dava['id'].toString());
              }
              
              Navigator.pop(context);
              _loadData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$davaAdi silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  // ========== KATEGORİ YÖNETİMİ METODLARI ==========

  /// Yeni kategori ekleme modalını açar
  void _addNewCategory() {
    final nameController = TextEditingController();
    final subCategoriesController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yeni Kategori Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subCategoriesController,
              decoration: const InputDecoration(
                labelText: 'Alt Kategoriler (virgülle ayırın)',
                border: OutlineInputBorder(),
                hintText: 'Örnek: Alt kategori 1, Alt kategori 2, Alt kategori 3',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final subCategories = subCategoriesController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                
                final newCategory = CategoryModel(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  name: nameController.text.trim(),
                  subCategories: subCategories,
                  orderIndex: allCategories.length + 1,
                  createdAt: DateTime.now(),
                );
                
                await HiveDatabaseService.addCategory(newCategory);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
  }

  /// Kategori görünürlüğünü değiştirir
  void _toggleCategoryVisibility(CategoryModel category) async {
    final updatedCategory = category.copyWith(isActive: !category.isActive);
    await HiveDatabaseService.updateCategory(updatedCategory);
    _loadData();
  }

  /// Kategori düzenleme modalını açar
  void _editCategory(CategoryModel category) {
    final nameController = TextEditingController(text: category.name);
    final subCategoriesController = TextEditingController(
      text: category.subCategories.join(', '),
    );
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${category.name} Düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Kategori Adı',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: subCategoriesController,
              decoration: const InputDecoration(
                labelText: 'Alt Kategoriler (virgülle ayırın)',
                border: OutlineInputBorder(),
                hintText: 'Örnek: Alt kategori 1, Alt kategori 2, Alt kategori 3',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final subCategories = subCategoriesController.text
                    .split(',')
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                
                final updatedCategory = category.copyWith(
                  name: nameController.text.trim(),
                  subCategories: subCategories,
                );
                
                await HiveDatabaseService.updateCategory(updatedCategory);
                Navigator.pop(context);
                _loadData();
              }
            },
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
  }

  // ========== TOPLU İŞLEMLER ==========

  /// Seçili kullanıcıları kilitle/aç
  Future<void> _bulkLockUsers(bool lock) async {
    final selectedUsers = allUsers.where((u) => _selectedUserIds.contains(u.id)).toList();
    
    // Admin'in kendini kilitlemesini engelle
    if (lock && selectedUsers.any((u) => u.email == widget.adminEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı kilitleyemezsiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Onay diyalogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lock ? 'Hesapları Kilitle' : 'Hesap Kilidini Aç'),
        content: Text(
          '${selectedUsers.length} kullanıcıyı ${lock ? "kilitlemek" : "kilidini açmak"} istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: lock ? Colors.red : Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    for (final user in selectedUsers) {
      // Kilitle: 5+ giriş denemesi yap, Aç: 0'a sıfırla
      final updated = user.copyWith(loginAttempts: lock ? 5 : 0);
      await HiveDatabaseService.updateRegistration(updated);
    }
    
    setState(() {
      _isSelectionMode = false;
      _selectedUserIds.clear();
    });
    
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedUsers.length} kullanıcı ${lock ? "kilitlendi" : "kilidi açıldı"}',
        ),
        backgroundColor: lock ? Colors.red : Colors.orange,
      ),
    );
  }

  /// Seçili kullanıcıları aktif/pasif yap
  Future<void> _bulkActivateUsers(bool activate) async {
    final selectedUsers = allUsers.where((u) => _selectedUserIds.contains(u.id)).toList();
    
    // Admin'in kendini pasif yapmasını engelle
    if (!activate && selectedUsers.any((u) => u.email == widget.adminEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı pasif yapamazsınız!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Onay diyalogu göster
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(activate ? 'Hesapları Aktif Yap' : 'Hesapları Pasif Yap'),
        content: Text(
          '${selectedUsers.length} kullanıcıyı ${activate ? "aktif" : "pasif"} yapmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: activate ? Colors.green : Colors.grey,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;
    
    for (final user in selectedUsers) {
      final updated = user.copyWith(isActive: activate);
      await HiveDatabaseService.updateRegistration(updated);
    }
    
    setState(() {
      _isSelectionMode = false;
      _selectedUserIds.clear();
    });
    
    _loadData();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${selectedUsers.length} kullanıcı ${activate ? "aktif" : "pasif"} yapıldı',
        ),
        backgroundColor: activate ? Colors.green : Colors.grey,
      ),
    );
  }

  /// Seçili kullanıcıları sil
  void _bulkDeleteUsers() {
    final selectedUsers = allUsers.where((u) => _selectedUserIds.contains(u.id)).toList();
    
    // Admin'in kendini silmesini engelle
    if (selectedUsers.any((u) => u.email == widget.adminEmail)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kendi hesabınızı silemezsiniz!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Toplu Silme Onayı'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${selectedUsers.length} kullanıcıyı silmek istediğinizden emin misiniz?'),
            const SizedBox(height: 16),
            const Text(
              'Bu işlem geri alınamaz!',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Silinecek kullanıcılar:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  ...selectedUsers.take(5).map((user) => Text('• ${user.judgeName} (${user.email})')),
                  if (selectedUsers.length > 5)
                    Text('... ve ${selectedUsers.length - 5} kullanıcı daha'),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              for (final user in selectedUsers) {
                await HiveDatabaseService.deleteRegistration(user.id);
              }
              
              Navigator.pop(context);
              
              setState(() {
                _isSelectionMode = false;
                _selectedUserIds.clear();
              });
              
              _loadData();
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${selectedUsers.length} kullanıcı silindi'),
                  backgroundColor: Colors.red,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ========== KATEGORİ YÖNETİMİ METODLARI ==========

  /// Kategori silme onay modalını açar
  void _deleteCategory(CategoryModel category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kategori Sil'),
        content: Text('${category.name} kategorisini silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              await HiveDatabaseService.deleteCategory(category.id);
              Navigator.pop(context);
              _loadData();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }
} 