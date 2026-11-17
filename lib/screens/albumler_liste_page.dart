import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../services/hive_database_service.dart';
import '../models/album_model.dart';
import 'album_goruntule_page.dart';
import 'album_olustur_page.dart';

/// ✅ Step-1: Albüm listesi sayfası
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class AlbumlerListePage extends StatefulWidget {
  final String? userEmail;

  /// Test: albüm listesi yüklenemesin.
  final bool forceLoadError;

  const AlbumlerListePage({
    super.key,
    this.userEmail,
    this.forceLoadError = false,
  });

  @override
  State<AlbumlerListePage> createState() => _AlbumlerListePageState();
}

class _AlbumlerListePageState extends State<AlbumlerListePage> {
  final TextEditingController _searchController = TextEditingController();
  List<AlbumModel> _allAlbums = [];
  List<AlbumModel> _filteredAlbums = [];
  bool _isLoading = false;
  bool _needsLogin = false;
  String? _loadError;
  bool _isGridView = true; // Grid görünüm varsayılan
  String _searchQuery = '';
  String _sortBy = 'tarih'; // 'tarih', 'isim', 'resim_sayisi'
  bool _isSelectionMode = false; // ✅ Step-3.5: Toplu işlem modu
  final Set<String> _selectedAlbumIds = {}; // Seçili albüm ID'leri

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// ✅ Step-1.1: Tüm albümleri yükle
  void _loadAlbums() {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) {
      setState(() {
        _isLoading = false;
        _needsLogin = true;
        _loadError = null;
        _allAlbums = [];
        _filteredAlbums = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _needsLogin = false;
      _loadError = null;
    });

    try {
      if (widget.forceLoadError) {
        throw Exception('Albümler yüklenemedi');
      }
      _allAlbums = HiveDatabaseService.getAlbums(email);
      _applyFilters();
    } catch (e) {
      print('❌ Albümler yüklenirken hata: $e');
      if (!mounted) return;
      setState(() {
        _allAlbums = [];
        _filteredAlbums = [];
        _loadError = 'Albümler yüklenemedi';
      });
    } finally {
      if (mounted) {
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

  void _openSavedDavalar() {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) return;
    showSavedDavalarDialog(context, email);
  }

  void _openAlbum(AlbumModel album) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumGoruntulePage(
          userEmail: widget.userEmail,
          albumId: album.id,
        ),
      ),
    ).then((_) => _loadAlbums());
  }

  void _openEditor({String? albumId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AlbumOlusturPage(
          userEmail: widget.userEmail,
          existingAlbumId: albumId,
        ),
      ),
    ).then((_) => _loadAlbums());
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
            const SizedBox(height: SeyirTokens.space4),
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
    newNameController.dispose();
  }

  String _albumInfoText(AlbumModel album) {
    final images = HiveDatabaseService.getAlbumImages(album.id);
    final imageCount = images.length;
    final totalSize = images.fold<int>(
      0,
      (sum, img) => sum + img.fileSize,
    );
    final buffer = StringBuffer()..writeln('Albüm: ${album.name}');
    if (album.description != null && album.description!.isNotEmpty) {
      buffer.writeln('Açıklama: ${album.description}');
    }
    buffer
      ..writeln('Resim Sayısı: $imageCount')
      ..writeln('Toplam Boyut: ${_formatFileSize(totalSize)}')
      ..write('Oluşturulma: ${_formatDate(album.createdAt)}');
    return buffer.toString();
  }

  Future<void> _copyAlbumInfo(AlbumModel album) async {
    final text = _albumInfoText(album);
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Albüm bilgileri kopyalandı'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _shareAlbumSheet(AlbumModel album) async {
    final text = _albumInfoText(album);
    try {
      await Share.share(text, subject: album.name);
    } catch (e) {
      await Clipboard.setData(ClipboardData(text: text));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Paylaşım açılamadı. Albüm bilgileri panoya kopyalandı'),
          backgroundColor: Colors.orange,
        ),
      );
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
    final palette = SeyirPalette.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Albüm Bilgileri', style: palette.headline()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Albüm: ${album.name}', style: palette.body()),
            if (album.description != null && album.description!.isNotEmpty)
              Text('Açıklama: ${album.description}', style: palette.body()),
            const SizedBox(height: SeyirTokens.space2),
            Text('Resim Sayısı: $imageCount', style: palette.body()),
            Text('Toplam Boyut: ${_formatFileSize(totalSize)}',
                style: palette.body()),
            Text('Oluşturulma: ${_formatDate(album.createdAt)}',
                style: palette.body()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
          TextButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _copyAlbumInfo(album);
            },
            icon: const Icon(Icons.copy),
            label: const Text('Bilgileri Kopyala'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              await _shareAlbumSheet(album);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              minimumSize:
                  const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
            icon: const Icon(Icons.share),
            label: const Text('Paylaş'),
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
                _openEditor(albumId: album.id);
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

  Widget _coverPlaceholder(SeyirPalette palette, {double iconSize = 48}) {
    return ColoredBox(
      color: palette.surfaceMuted,
      child: Icon(
        Icons.photo_album,
        size: iconSize,
        color: palette.textMuted,
      ),
    );
  }

  Widget _albumCover(AlbumModel album, SeyirPalette palette,
      {double iconSize = 48}) {
    final provider = _getAlbumCoverImage(album);
    if (provider == null) {
      return _coverPlaceholder(palette, iconSize: iconSize);
    }
    return Image(
      image: provider,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return _coverPlaceholder(palette, iconSize: iconSize);
      },
    );
  }

  Widget _selectionMark(String albumId, {double size = 20}) {
    final palette = SeyirPalette.of(context);
    final selected = _selectedAlbumIds.contains(albumId);
    return Container(
      width: size + SeyirTokens.space1,
      height: size + SeyirTokens.space1,
      decoration: BoxDecoration(
        color: selected ? Colors.blue : palette.card,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child:
          selected ? Icon(Icons.check, color: Colors.white, size: size) : null,
    );
  }

  ShapeBorder _albumShape(SeyirPalette palette) {
    return RoundedRectangleBorder(
      borderRadius: SeyirTokens.radiusMdAll,
      side: BorderSide(color: palette.border),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ROW 1: WhoBoom, Arama Iconu, Chat Iconu
            ZeroWhoboomSearchMessage(userEmail: widget.userEmail),

            // ROW 2: Anasayfa, Arkadaş, Telefon, Bildirim, Menü, Ayarlar Iconu
            Padding(
              padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
              child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
            ),

            // ROW 3: Profil Bölümü
            Padding(
              padding: const EdgeInsets.all(SeyirTokens.space1),
              child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                userEmail: widget.userEmail,
                onShowSavedDavalar: _openSavedDavalar,
              ),
            ),

            // ROW 4: Başlık ve Kontroller
            Padding(
              padding: const EdgeInsets.all(SeyirTokens.space2),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Geri',
                    style:
                        delilIconButtonStyle(foreground: palette.textPrimary),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: SeyirTokens.space2),
                  Expanded(
                    child: Text(
                      'ALBÜMLERİM',
                      style: palette.headline(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ✅ Step-3.6: Toplu işlem modu butonu
                  if (!_isSelectionMode) ...[
                    // Görünüm değiştir butonu
                    IconButton(
                      tooltip: _isGridView ? 'Liste Görünümü' : 'Grid Görünümü',
                      style: delilIconButtonStyle(foreground: Colors.blue),
                      icon: Icon(
                        _isGridView ? Icons.view_list : Icons.grid_view,
                      ),
                      onPressed: () {
                        setState(() {
                          _isGridView = !_isGridView;
                        });
                      },
                    ),
                    // Sıralama butonu
                    IconButton(
                      tooltip: 'Sırala',
                      style: delilIconButtonStyle(foreground: Colors.blue),
                      icon: const Icon(Icons.sort),
                      onPressed: _showSortDialog,
                    ),
                    // Seçim modu butonu
                    IconButton(
                      tooltip: 'Toplu İşlem',
                      style: delilIconButtonStyle(foreground: Colors.blue),
                      icon: const Icon(Icons.checklist),
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                          _selectedAlbumIds.clear();
                        });
                      },
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
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                            SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                        foregroundColor: palette.textPrimary,
                      ),
                      child: const Text('İptal'),
                    ),
                    // Sil butonu
                    if (_selectedAlbumIds.isNotEmpty)
                      IconButton(
                        tooltip: 'Seçili Albümleri Sil',
                        style: delilIconButtonStyle(foreground: Colors.red),
                        icon: const Icon(Icons.delete),
                        onPressed: _showBulkDeleteDialog,
                      ),
                  ],
                ],
              ),
            ),

            // ROW 5: Arama çubuğu
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space4,
                vertical: SeyirTokens.space2,
              ),
              child: TextField(
                controller: _searchController,
                style: palette.body(),
                cursorColor: palette.textPrimary,
                decoration: InputDecoration(
                  hintText: 'Albüm ara...',
                  hintStyle: palette.body(
                    color: palette.textMuted,
                    weight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(Icons.search, color: palette.textSecondary),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          tooltip: 'Aramayı temizle',
                          style: delilIconButtonStyle(
                              foreground: palette.textSecondary),
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _searchQuery = '';
                            _applyFilters();
                          },
                        )
                      : null,
                  border: const OutlineInputBorder(
                    borderRadius: SeyirTokens.radiusMdAll,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: SeyirTokens.radiusMdAll,
                    borderSide: BorderSide(color: palette.border),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: SeyirTokens.radiusMdAll,
                    borderSide: BorderSide(color: Colors.blue, width: 1.5),
                  ),
                  filled: true,
                  fillColor: palette.surfaceMuted,
                ),
                onChanged: (value) {
                  _searchQuery = value;
                  _applyFilters();
                },
              ),
            ),

            // ROW 6: Albüm listesi
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _needsLogin
                      ? const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: SeyirTokens.space4),
                          child: Center(
                            child: DelilSoftEmpty(
                              title: 'Giriş gerekli',
                              message: 'Albümleri görmek için oturum aç.',
                              icon: Icons.lock_outline,
                            ),
                          ),
                        )
                      : _loadError != null
                          ? Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: SeyirTokens.space4,
                              ),
                              child: Center(
                                child: DelilLoadError(
                                  message: _loadError!,
                                  onRetry: _loadAlbums,
                                ),
                              ),
                            )
                          : _filteredAlbums.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: SeyirTokens.space4,
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        DelilSoftEmpty(
                                          title: _searchQuery.isNotEmpty
                                              ? 'Arama sonucu bulunamadı'
                                              : 'Henüz albüm oluşturmadınız',
                                          message: _searchQuery.isNotEmpty
                                              ? '"$_searchQuery" için eşleşme yok'
                                              : 'Yeni bir albüm oluşturarak fotoğraflarınızı toplayabilirsiniz.',
                                          icon: _searchQuery.isNotEmpty
                                              ? Icons.search_off
                                              : Icons.photo_album_outlined,
                                        ),
                                        if (_searchQuery.isEmpty) ...[
                                          const SizedBox(
                                              height: SeyirTokens.space4),
                                          ElevatedButton.icon(
                                            onPressed: () => _openEditor(),
                                            icon: const Icon(Icons.add),
                                            label: const Text(
                                                'Yeni Albüm Oluştur'),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                              minimumSize: const Size(
                                                SeyirTokens.tapTarget,
                                                SeyirTokens.tapTarget,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                )
                              : _isGridView
                                  ? _buildGridView(palette)
                                  : _buildListView(palette),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: 'Yeni Albüm',
        onPressed: () => _openEditor(),
        icon: const Icon(Icons.add),
        label: const Text('Yeni Albüm'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// ✅ Step-1.5: Grid görünümü
  Widget _buildGridView(SeyirPalette palette) {
    return GridView.builder(
      padding: const EdgeInsets.all(SeyirTokens.space4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: SeyirTokens.space4,
        mainAxisSpacing: SeyirTokens.space4,
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
              : () => _openAlbum(album),
          onLongPress: _isSelectionMode
              ? () => _toggleAlbumSelection(album.id)
              : () => _showAlbumOptionsMenu(context, album),
          child: Card(
            elevation: 4,
            color: palette.card,
            surfaceTintColor: Colors.transparent,
            shadowColor: palette.shadow,
            shape: _albumShape(palette),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _albumCover(album, palette),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(SeyirTokens.space3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            style: palette.title(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: SeyirTokens.space1),
                          Row(
                            children: [
                              Icon(Icons.photo,
                                  size: 14, color: palette.textMuted),
                              const SizedBox(width: SeyirTokens.space1),
                              Text(
                                '$imageCount resim',
                                style:
                                    palette.body(color: palette.textSecondary),
                              ),
                              if (imageCount > 0) ...[
                                const SizedBox(width: SeyirTokens.space2),
                                Icon(Icons.storage,
                                    size: 12, color: palette.textMuted),
                                const SizedBox(width: SeyirTokens.space1),
                                Flexible(
                                  child: Text(
                                    _formatFileSize(images.fold<int>(
                                      0,
                                      (sum, img) => sum + img.fileSize,
                                    )),
                                    style: palette.caption(),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: SeyirTokens.space1),
                          Text(
                            _formatDate(album.createdAt),
                            style: palette.caption(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isSelectionMode)
                  Positioned(
                    top: SeyirTokens.space2,
                    right: SeyirTokens.space2,
                    child: _selectionMark(album.id),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// ✅ Step-1.6: List görünümü
  Widget _buildListView(SeyirPalette palette) {
    return ListView.builder(
      padding: const EdgeInsets.all(SeyirTokens.space4),
      itemCount: _filteredAlbums.length,
      itemBuilder: (context, index) {
        final album = _filteredAlbums[index];
        final images = HiveDatabaseService.getAlbumImages(album.id);
        final imageCount = images.length;

        return Card(
          elevation: 2,
          color: palette.card,
          surfaceTintColor: Colors.transparent,
          shadowColor: palette.shadow,
          margin: const EdgeInsets.only(bottom: SeyirTokens.space3),
          shape: _albumShape(palette),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(SeyirTokens.space3),
                leading: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: SeyirTokens.radiusSmAll,
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: _albumCover(album, palette, iconSize: 28),
                      ),
                    ),
                    if (_isSelectionMode)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: _selectionMark(album.id, size: 16),
                      ),
                  ],
                ),
                title: Text(album.name, style: palette.title()),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: SeyirTokens.space1),
                    Row(
                      children: [
                        Icon(Icons.photo, size: 14, color: palette.textMuted),
                        const SizedBox(width: SeyirTokens.space1),
                        Text(
                          '$imageCount resim',
                          style: palette.body(color: palette.textSecondary),
                        ),
                        const SizedBox(width: SeyirTokens.space3),
                        Text(
                          _formatDate(album.createdAt),
                          style: palette.body(color: palette.textSecondary),
                        ),
                        if (imageCount > 0) ...[
                          const SizedBox(width: SeyirTokens.space3),
                          Icon(Icons.storage,
                              size: 12, color: palette.textMuted),
                          const SizedBox(width: SeyirTokens.space1),
                          Flexible(
                            child: Text(
                              _formatFileSize(images.fold<int>(
                                0,
                                (sum, img) => sum + img.fileSize,
                              )),
                              style: palette.caption(),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (album.description != null &&
                        album.description!.isNotEmpty) ...[
                      const SizedBox(height: SeyirTokens.space1),
                      Text(
                        album.description!,
                        style: palette.body(
                          color: palette.textSecondary,
                          weight: FontWeight.w400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
                trailing: _isSelectionMode
                    ? null
                    : Icon(Icons.chevron_right, color: palette.textMuted),
                onTap: _isSelectionMode
                    ? () => _toggleAlbumSelection(album.id)
                    : () => _openAlbum(album),
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
