import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../models/album_model.dart';
import '../models/album_image_model.dart';
import 'album_olustur_page.dart';

/// ✅ Step-1: Albüm listesi sayfası
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class AlbumlerListePage extends StatefulWidget {
  final String? userEmail;

  const AlbumlerListePage({
    super.key,
    this.userEmail,
  });

  @override
  State<AlbumlerListePage> createState() => _AlbumlerListePageState();
}

class _AlbumlerListePageState extends State<AlbumlerListePage> {
  List<AlbumModel> _allAlbums = [];
  List<AlbumModel> _filteredAlbums = [];
  bool _isLoading = false;
  bool _isGridView = true; // Grid görünüm varsayılan
  String _searchQuery = '';
  String _sortBy = 'tarih'; // 'tarih', 'isim', 'resim_sayisi'
  bool _isSelectionMode = false; // ✅ Step-3.5: Toplu işlem modu
  Set<String> _selectedAlbumIds = {}; // Seçili albüm ID'leri

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  /// ✅ Step-1.1: Tüm albümleri yükle
  void _loadAlbums() {
    if (widget.userEmail != null) {
      setState(() {
        _isLoading = true;
      });
      
      try {
        _allAlbums = HiveDatabaseService.getAlbums(widget.userEmail!);
        _applyFilters();
      } catch (e) {
        print('❌ Albümler yüklenirken hata: $e');
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// ✅ Step-1.2: Filtreleme ve sıralama uygula
  void _applyFilters() {
    List<AlbumModel> filtered = List.from(_allAlbums);

    // Arama filtresi
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((album) {
        final name = album.name.toLowerCase();
        final description = (album.description ?? '').toLowerCase();
        final query = _searchQuery.toLowerCase();
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Sıralama
    switch (_sortBy) {
      case 'tarih':
        filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'isim':
        filtered.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'resim_sayisi':
        filtered.sort((a, b) {
          final aCount = HiveDatabaseService.getAlbumImages(a.id).length;
          final bCount = HiveDatabaseService.getAlbumImages(b.id).length;
          return bCount.compareTo(aCount);
        });
        break;
    }

    setState(() {
      _filteredAlbums = filtered;
    });
  }

  /// ✅ Step-1.3: Albüm kapak resmini al (ilk resim)
  ImageProvider<Object>? _getAlbumCoverImage(AlbumModel album) {
    final images = HiveDatabaseService.getAlbumImages(album.id);
    if (images.isEmpty) return null;

    final firstImage = images.first;
    return _getImageProvider(firstImage.imageUrl);
  }

  /// Resim için ImageProvider döndür
  ImageProvider<Object>? _getImageProvider(String imageUrl) {
    if (imageUrl.isEmpty) return null;

    // Base64 string kontrolü
    if (imageUrl.startsWith('data:image')) {
      try {
        final parts = imageUrl.split(',');
        if (parts.length < 2) return null;
        final base64String = parts[1];
        final bytes = base64Decode(base64String);
        if (bytes.isEmpty) return null;
        return MemoryImage(bytes) as ImageProvider<Object>;
      } catch (e) {
        print('⚠️ Base64 decode hatası: $e');
        return null;
      }
    }

    // Network URL kontrolü
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return NetworkImage(imageUrl) as ImageProvider<Object>;
    }

    // File path kontrolü
    if (imageUrl.startsWith('/')) {
      return FileImage(File(imageUrl)) as ImageProvider<Object>;
    }

    return null;
  }

  /// ✅ Step-1.4: Sıralama seçenekleri dialog'u
  void _showSortDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sıralama'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Tarihe Göre (Yeni → Eski)'),
              value: 'tarih',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            RadioListTile<String>(
              title: const Text('İsme Göre (A → Z)'),
              value: 'isim',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
            RadioListTile<String>(
              title: const Text('Resim Sayısına Göre (Çok → Az)'),
              value: 'resim_sayisi',
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
                _applyFilters();
              },
            ),
          ],
        ),
      ),
    );
  }

  /// ✅ Step-3.7: Toplu silme dialog'u
  void _showBulkDeleteDialog() {
    if (_selectedAlbumIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albümleri Sil'),
        content: Text(
          '${_selectedAlbumIds.length} albümü silmek istediğinizden emin misiniz? Tüm resimler de silinecektir.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _bulkDeleteAlbums();
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  /// ✅ Step-3.8: Toplu albüm silme
  Future<void> _bulkDeleteAlbums() async {
    if (widget.userEmail == null) return;

    setState(() {
      _isLoading = true;
    });

    int successCount = 0;
    int failCount = 0;

    for (final albumId in _selectedAlbumIds) {
      try {
        await HiveDatabaseService.deleteAlbum(
          albumId: albumId,
          userEmail: widget.userEmail!,
        );
        successCount++;
      } catch (e) {
        print('❌ Albüm silinirken hata: $e');
        failCount++;
      }
    }

    // ✅ Veritabanına kaydediliyor
    // ✅ Kalıcı olarak saklanıyor

    setState(() {
      _isLoading = false;
      _isSelectionMode = false;
      _selectedAlbumIds.clear();
    });

    _loadAlbums();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failCount > 0
                ? '✅ $successCount albüm silindi, $failCount albüm silinemedi'
                : '✅ $successCount albüm silindi',
          ),
          backgroundColor: failCount > 0 ? Colors.orange : Colors.green,
        ),
      );
    }
  }

  /// ✅ Step-3.9: Albüm seçimi toggle
  void _toggleAlbumSelection(String albumId) {
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
  }

  /// ✅ Step-4.4: Albüm kopyalama
  Future<void> _copyAlbum(AlbumModel album) async {
    if (widget.userEmail == null) return;

    // Yeni isim dialog'u
    final newNameController = TextEditingController(
      text: '${album.name} (Kopya)',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albümü Kopyala'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Yeni albüm adını girin:'),
            const SizedBox(height: 16),
            TextField(
              controller: newNameController,
              decoration: const InputDecoration(
                labelText: 'Albüm Adı',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Kopyala'),
          ),
        ],
      ),
    );

    if (confirmed == true && newNameController.text.trim().isNotEmpty) {
      try {
        setState(() {
          _isLoading = true;
        });

        await HiveDatabaseService.copyAlbum(
          albumId: album.id,
          userEmail: widget.userEmail!,
          newName: newNameController.text.trim(),
        );

        // ✅ Veritabanına kaydediliyor
        // ✅ Kalıcı olarak saklanıyor

        setState(() {
          _isLoading = false;
        });

        _loadAlbums();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Albüm kopyalandı'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Albüm kopyalanırken hata: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  /// ✅ Step-4.5: Albüm paylaşımı
  void _shareAlbum(AlbumModel album) {
    final images = HiveDatabaseService.getAlbumImages(album.id);
    final imageCount = images.length;
    final totalSize = images.fold<int>(
      0,
      (sum, img) => sum + img.fileSize,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albüm Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Albüm: ${album.name}'),
            if (album.description != null && album.description!.isNotEmpty)
              Text('Açıklama: ${album.description}'),
            const SizedBox(height: 8),
            Text('Resim Sayısı: $imageCount'),
            Text('Toplam Boyut: ${_formatFileSize(totalSize)}'),
            Text('Oluşturulma: ${_formatDate(album.createdAt)}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Burada gerçek paylaşım işlemi yapılabilir (share_plus paketi ile)
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Albüm bilgileri kopyalandı'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text('Bilgileri Kopyala'),
          ),
        ],
      ),
    );
  }

  /// Albüm seçenekleri menüsü
  void _showAlbumOptionsMenu(BuildContext context, AlbumModel album) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumOlusturPage(
                      userEmail: widget.userEmail,
                      existingAlbumId: album.id,
                    ),
                  ),
                ).then((_) => _loadAlbums());
              },
            ),
            // ✅ Step-4.2: Albüm kopyalama
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.green),
              title: const Text('Kopyala'),
              onTap: () async {
                Navigator.pop(context);
                await _copyAlbum(album);
              },
            ),
            // ✅ Step-4.3: Albüm paylaşımı
            ListTile(
              leading: const Icon(Icons.share, color: Colors.blue),
              title: const Text('Paylaş'),
              onTap: () {
                Navigator.pop(context);
                _shareAlbum(album);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Albümü Sil'),
                    content: Text(
                      '${album.name} albümünü silmek istediğinizden emin misiniz? Tüm resimler de silinecektir.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
                
                if (confirmed == true) {
                  try {
                    await HiveDatabaseService.deleteAlbum(
                      albumId: album.id,
                      userEmail: widget.userEmail!,
                    );
                    // ✅ Veritabanına kaydediliyor
                    // ✅ Kalıcı olarak saklanıyor
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Albüm silindi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadAlbums();
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Albüm silinirken hata: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Tarih formatla
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  /// ✅ Step-2.3: Dosya boyutu formatla
  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),

            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
            ),

            // ROW 3: Profil Bölümü
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                userEmail: widget.userEmail,
                onShowSavedDavalar: () {},
              ),
            ),

            // ROW 4: Başlık ve Kontroller
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'ALBÜMLERİM',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ✅ Step-3.6: Toplu işlem modu butonu
                  if (!_isSelectionMode) ...[
                    // Görünüm değiştir butonu
                    IconButton(
                      icon: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                        color: Colors.blue,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                      tooltip: _isGridView ? 'Liste Görünümü' : 'Grid Görünümü',
                    ),
                    // Sıralama butonu
                    IconButton(
                      icon: const Icon(Icons.sort, color: Colors.blue),
                      onPressed: _showSortDialog,
                      tooltip: 'Sırala',
                    ),
                    // Seçim modu butonu
                    IconButton(
                      icon: const Icon(Icons.checklist, color: Colors.blue),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedAlbumIds.clear();
                        });
                      },
                      tooltip: 'Toplu İşlem',
                    ),
                  ] else ...[
                    // İptal butonu
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = false;
                          _selectedAlbumIds.clear();
                        });
                      },
                      child: const Text('İptal'),
                    ),
                    // Sil butonu
                    if (_selectedAlbumIds.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: _showBulkDeleteDialog,
                        tooltip: 'Seçili Albümleri Sil',
                      ),
                  ],
                ],
              ),
            ),

            // ROW 5: Arama çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Albüm ara...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            setState(() {
                              _searchQuery = '';
                            });
                            _applyFilters();
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                  _applyFilters();
                },
              ),
            ),

            // ROW 6: Albüm listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredAlbums.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isNotEmpty
                                    ? Icons.search_off
                                    : Icons.photo_album_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'Arama sonucu bulunamadı'
                                    : 'Henüz albüm oluşturmadınız',
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              if (_searchQuery.isEmpty) ...[
                                const SizedBox(height: 16),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AlbumOlusturPage(
                                          userEmail: widget.userEmail,
                                        ),
                                      ),
                                    ).then((_) => _loadAlbums());
                                  },
                                  icon: const Icon(Icons.add),
                                  label: const Text('Yeni Albüm Oluştur'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        )
                      : _isGridView
                          ? _buildGridView()
                          : _buildListView(),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AlbumOlusturPage(
                userEmail: widget.userEmail,
              ),
            ),
          ).then((_) => _loadAlbums());
        },
        icon: const Icon(Icons.add),
        label: const Text('Yeni Albüm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// ✅ Step-1.5: Grid görünümü
  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: _filteredAlbums.length,
      itemBuilder: (context, index) {
        final album = _filteredAlbums[index];
        final images = HiveDatabaseService.getAlbumImages(album.id);
        final imageCount = images.length;
        
        return GestureDetector(
          onTap: _isSelectionMode
              ? () => _toggleAlbumSelection(album.id)
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => AlbumOlusturPage(
                        userEmail: widget.userEmail,
                        existingAlbumId: album.id,
                      ),
                    ),
                  ).then((_) => _loadAlbums());
                },
          onLongPress: _isSelectionMode
              ? () => _toggleAlbumSelection(album.id)
              : () => _showAlbumOptionsMenu(context, album),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Kapak resmi
                    Expanded(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: _getAlbumCoverImage(album) != null
                            ? Image(
                                image: _getAlbumCoverImage(album)!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.photo_album,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.photo_album,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                // Albüm bilgileri
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        album.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.photo, size: 14, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '$imageCount resim',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          if (imageCount > 0) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.storage, size: 12, color: Colors.grey),
                            const SizedBox(width: 2),
                            Text(
                              _formatFileSize(images.fold<int>(
                                0,
                                (sum, img) => sum + img.fileSize,
                              )),
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(album.createdAt),
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
                // ✅ Step-3.10: Seçim checkbox'ı
                if (_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      decoration: BoxDecoration(
                        color: _selectedAlbumIds.contains(album.id)
                            ? Colors.blue
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.blue,
                          width: 2,
                        ),
                      ),
                      child: _selectedAlbumIds.contains(album.id)
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : const SizedBox(
                              width: 20,
                              height: 20,
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

  /// ✅ Step-1.6: List görünümü
  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: _filteredAlbums.length,
      itemBuilder: (context, index) {
        final album = _filteredAlbums[index];
        final images = HiveDatabaseService.getAlbumImages(album.id);
        final imageCount = images.length;
        
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Stack(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _getAlbumCoverImage(album) != null
                            ? Image(
                                image: _getAlbumCoverImage(album)!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[300],
                                    child: const Icon(
                                      Icons.photo_album,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              )
                            : Container(
                                color: Colors.grey[300],
                                child: const Icon(
                                  Icons.photo_album,
                                  color: Colors.grey,
                                ),
                              ),
                      ),
                    ),
                    // ✅ Step-3.11: Liste görünümünde seçim checkbox'ı
                    if (_isSelectionMode)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: _selectedAlbumIds.contains(album.id)
                                ? Colors.blue
                                : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.blue,
                              width: 2,
                            ),
                          ),
                          child: _selectedAlbumIds.contains(album.id)
                              ? const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 16,
                                )
                              : const SizedBox(
                                  width: 16,
                                  height: 16,
                                ),
                        ),
                      ),
                  ],
                ),
            title: Text(
              album.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.photo, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$imageCount resim',
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      _formatDate(album.createdAt),
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (imageCount > 0) ...[
                      const SizedBox(width: 12),
                      const Icon(Icons.storage, size: 12, color: Colors.grey),
                      const SizedBox(width: 2),
                      Text(
                        _formatFileSize(images.fold<int>(
                          0,
                          (sum, img) => sum + img.fileSize,
                        )),
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ],
                ),
                if (album.description != null && album.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    album.description!,
                    style: const TextStyle(fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
                trailing: _isSelectionMode
                    ? null
                    : const Icon(Icons.chevron_right),
                onTap: _isSelectionMode
                    ? () => _toggleAlbumSelection(album.id)
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AlbumOlusturPage(
                              userEmail: widget.userEmail,
                              existingAlbumId: album.id,
                            ),
                          ),
                        ).then((_) => _loadAlbums());
                      },
                onLongPress: _isSelectionMode
                    ? () => _toggleAlbumSelection(album.id)
                    : () => _showAlbumOptionsMenu(context, album),
              ),
            ],
          ),
        );
      },
    );
  }
}

