import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../theme/seyir_tokens.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/delil_surface.dart';
import '../services/hive_database_service.dart';
import '../models/album_model.dart';
import '../models/album_image_model.dart';
import 'album_goruntule_page.dart';
import 'package:its19/utils/app_logger.dart';

/// ✅ Step-4: Albüm oluşturma ve yönetim sayfası
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class AlbumOlusturPage extends StatefulWidget {
  final String? userEmail;
  final String? existingAlbumId; // Mevcut albümü düzenlemek için (opsiyonel)

  /// Test: mevcut albüm yüklenemesin.
  final bool forceLoadError;

  const AlbumOlusturPage({
    super.key,
    this.userEmail,
    this.existingAlbumId,
    this.forceLoadError = false,
  });

  @override
  State<AlbumOlusturPage> createState() => _AlbumOlusturPageState();
}

class _AlbumOlusturPageState extends State<AlbumOlusturPage> {
  final TextEditingController _albumNameController = TextEditingController();
  final TextEditingController _albumDescriptionController =
      TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  List<AlbumImageModel> _images = [];
  bool _isLoading = false;
  bool _needsLogin = false;
  String? _loadError;
  String? _currentAlbumId;
  List<AlbumModel> _allAlbums = [];

  @override
  void initState() {
    super.initState();
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) {
      _needsLogin = true;
      return;
    }
    if (widget.forceLoadError) {
      _loadError = 'Albüm yüklenemedi';
    } else if (widget.existingAlbumId != null) {
      _loadExistingAlbum();
    }
    _loadAllAlbums();
  }

  /// ✅ Step-5: Tüm albümleri yükle
  void _loadAllAlbums() {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) return;
    try {
      final albums = HiveDatabaseService.getAlbums(email);
      if (!mounted) return;
      setState(() {
        _allAlbums = albums;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _allAlbums = [];
      });
    }
  }

  void _openSavedDavalar() {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) return;
    showSavedDavalarDialog(context, email);
  }

  void _retryLoad() {
    if (widget.forceLoadError) {
      setState(() => _loadError = 'Albüm yüklenemedi');
      return;
    }
    setState(() => _loadError = null);
    if (widget.existingAlbumId != null) {
      _loadExistingAlbum();
    }
    _loadAllAlbums();
  }

  @override
  void dispose() {
    _albumNameController.dispose();
    _albumDescriptionController.dispose();
    super.dispose();
  }

  /// Mevcut albümü yükle
  Future<void> _loadExistingAlbum() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      if (widget.forceLoadError) {
        throw Exception('Albüm yüklenemedi');
      }
      final albums = HiveDatabaseService.getAlbums(widget.userEmail!);
      final album = albums.firstWhere(
        (a) => a.id == widget.existingAlbumId,
        orElse: () => throw Exception('Albüm bulunamadı'),
      );

      _currentAlbumId = album.id;
      _albumNameController.text = album.name;
      _albumDescriptionController.text = album.description ?? '';
      _images = HiveDatabaseService.getAlbumImages(album.id);
    } catch (e) {
      appLog('❌ Albüm yüklenirken hata: $e');
      if (mounted) {
        setState(() => _loadError = 'Albüm yüklenemedi');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDecoration(
    SeyirPalette palette, {
    required String label,
    required String hint,
    required IconData icon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: alignLabelWithHint,
      labelStyle: palette.body(color: palette.textSecondary),
      hintStyle: palette.body(
        color: palette.textMuted,
        weight: FontWeight.w400,
      ),
      prefixIcon: Icon(icon, color: palette.textSecondary),
      filled: true,
      fillColor: palette.surfaceMuted,
      border: const OutlineInputBorder(borderRadius: SeyirTokens.radiusMdAll),
      enabledBorder: OutlineInputBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        borderSide: BorderSide(color: palette.border),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        borderSide: BorderSide(color: Colors.blue, width: 1.5),
      ),
    );
  }

  /// Resim seçme dialog'u göster
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resim Ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kameradan Çek'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeriden Seç'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Resim seç
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _addImageToAlbum(image);
      }
    } catch (e) {
      appLog('❌ Resim seçilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Resim seçilirken hata: $e')),
      );
    }
  }

  /// Resmi albüme ekle
  Future<void> _addImageToAlbum(XFile imageFile) async {
    try {
      setState(() => _isLoading = true);

      // Resmi base64'e çevir
      final bytes = await imageFile.readAsBytes();
      final base64String = base64Encode(bytes);
      final imageUrl = 'data:image/jpeg;base64,$base64String';

      // Albüm ID'si yoksa önce albüm oluştur
      if (_currentAlbumId == null) {
        if (_albumNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lütfen önce albüm adı girin'),
              backgroundColor: Colors.orange,
            ),
          );
          setState(() => _isLoading = false);
          return;
        }

        _currentAlbumId = await HiveDatabaseService.createAlbum(
          name: _albumNameController.text.trim(),
          userEmail: widget.userEmail!,
          description: _albumDescriptionController.text.trim().isEmpty
              ? null
              : _albumDescriptionController.text.trim(),
        );
      }

      // Resmi albüme ekle
      final imageId = await HiveDatabaseService.addImageToAlbum(
        albumId: _currentAlbumId!,
        imageUrl: imageUrl,
        imagePath: imageFile.path,
        fileSize: bytes.length,
      );

      // ✅ Veritabanına kaydediliyor
      // ✅ Kalıcı olarak saklanıyor
      appLog('✅ Resim albüme eklendi: $imageId');

      // Resimleri yeniden yükle
      _images = HiveDatabaseService.getAlbumImages(_currentAlbumId!);

      // ✅ Resim eklendiğinde albümü otomatik kaydet
      if (_albumNameController.text.trim().isNotEmpty) {
        await HiveDatabaseService.updateAlbum(
          albumId: _currentAlbumId!,
          userEmail: widget.userEmail!,
          name: _albumNameController.text.trim(),
          description: _albumDescriptionController.text.trim().isEmpty
              ? null
              : _albumDescriptionController.text.trim(),
        );
        _loadAllAlbums();
      }

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Resim albüme eklendi ve albüm kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      appLog('❌ Resim eklenirken hata: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim eklenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Resmi sil
  Future<void> _deleteImage(AlbumImageModel image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resmi Sil'),
        content: const Text('Bu resmi silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true && _currentAlbumId != null) {
      try {
        setState(() => _isLoading = true);
        await HiveDatabaseService.deleteAlbumImage(
          imageId: image.id,
          albumId: _currentAlbumId!,
        );
        _images = HiveDatabaseService.getAlbumImages(_currentAlbumId!);
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resim silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        appLog('❌ Resim silinirken hata: $e');
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Resim silinirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Albümü kaydet/güncelle
  Future<void> _saveAlbum() async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_albumNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen albüm adı girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      if (_currentAlbumId == null) {
        // Yeni albüm oluştur
        _currentAlbumId = await HiveDatabaseService.createAlbum(
          name: _albumNameController.text.trim(),
          userEmail: widget.userEmail!,
          description: _albumDescriptionController.text.trim().isEmpty
              ? null
              : _albumDescriptionController.text.trim(),
        );
      } else {
        // Mevcut albümü güncelle
        await HiveDatabaseService.updateAlbum(
          albumId: _currentAlbumId!,
          userEmail: widget.userEmail!,
          name: _albumNameController.text.trim(),
          description: _albumDescriptionController.text.trim().isEmpty
              ? null
              : _albumDescriptionController.text.trim(),
        );
      }

      // ✅ Veritabanına kaydediliyor
      // ✅ Kalıcı olarak saklanıyor

      // Yeni albüm oluşturulduysa resimleri yükle
      if (_currentAlbumId != null) {
        _images = HiveDatabaseService.getAlbumImages(_currentAlbumId!);
      }

      // Albüm listesini güncelle
      _loadAllAlbums();

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Albüm kaydedildi'),
          backgroundColor: Colors.green,
        ),
      );

      // Sayfada kal - kullanıcı albümü düzenlemeye devam edebilir
    } catch (e) {
      appLog('❌ Albüm kaydedilirken hata: $e');
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Albüm kaydedilirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// ✅ Step-6: Albüm listesi dialog'unu siyah noktalar ile göster
  void _showAlbumsListDialog() {
    _loadAllAlbums(); // Güncel listeyi yükle
    final palette = SeyirPalette.of(context);

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.8,
          padding: const EdgeInsets.all(SeyirTokens.space4),
          child: Column(
            children: [
              // Başlık
              Row(
                children: [
                  const Icon(Icons.photo_album, color: Colors.blue),
                  const SizedBox(width: SeyirTokens.space2),
                  Text(
                    'Albümlerim',
                    style: palette.headline(),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space3,
                      vertical: SeyirTokens.space2,
                    ),
                    decoration: BoxDecoration(
                      color: palette.tint(Colors.blue),
                      borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
                      border:
                          Border.all(color: palette.tintBorder(Colors.blue)),
                    ),
                    child: Text(
                      '${_allAlbums.length}',
                      style: palette.title(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(width: SeyirTokens.space2),
                  IconButton(
                    tooltip: 'Kapat',
                    style:
                        delilIconButtonStyle(foreground: palette.textPrimary),
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: SeyirTokens.space4),

              // Siyah noktalar grid
              Expanded(
                child: _allAlbums.isEmpty
                    ? const Center(
                        child: DelilSoftEmpty(
                          title: 'Henüz albüm oluşturmadınız',
                          message:
                              'Yeni bir albüm oluşturarak fotoğraflarınızı toplayabilirsiniz.',
                          icon: Icons.photo_album_outlined,
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(8.0),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 6, // Her satırda 6 nokta
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: 1.0,
                        ),
                        itemCount: _allAlbums.length,
                        itemBuilder: (context, index) {
                          final album = _allAlbums[index];
                          final albumNumber =
                              index + 1; // 1'den başlayan sıra numarası

                          // Yeşil-turuncu karışımı renk (her nokta için farklı ton)
                          final colorRatio = index /
                              _allAlbums.length; // 0.0 (yeşil) -> 1.0 (turuncu)
                          final mixedColor = Color.lerp(
                                Colors.green,
                                Colors.orange,
                                colorRatio,
                              ) ??
                              Colors.green;

                          return GestureDetector(
                            onTap: () {
                              Navigator.pop(context); // Dialog'u kapat
                              Navigator.pop(context); // Mevcut sayfayı kapat
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AlbumOlusturPage(
                                    userEmail: widget.userEmail,
                                    existingAlbumId: album.id,
                                  ),
                                ),
                              );
                            },
                            onLongPress: () {
                              _showAlbumOptionsMenu(context, album);
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: mixedColor,
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '$albumNumber',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: SeyirTokens.typeBody,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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
    );
  }

  /// Albüm seçenekleri menüsü (uzun basınca)
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
                Navigator.pop(context); // Bottom sheet'i kapat
                Navigator.pop(context); // Dialog'u kapat
                Navigator.pop(context); // Mevcut sayfayı kapat
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlbumOlusturPage(
                      userEmail: widget.userEmail,
                      existingAlbumId: album.id,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Sil', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context); // Bottom sheet'i kapat

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
                      Navigator.pop(context); // Dialog'u kapat
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('✅ Albüm silindi'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadAllAlbums();
                      setState(() {}); // Dialog'u güncelle
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
        appLog('⚠️ Base64 decode hatası: $e');
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

            // ROW 4: Başlık ve Albümlerim Butonu
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
                      widget.existingAlbumId != null
                          ? 'ALBÜM DÜZENLE'
                          : 'ALBÜM OLUŞTUR',
                      style: palette.headline(),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // ✅ Albümü Kaydet icon butonu
                  IconButton(
                    tooltip: 'Albümü Kaydet',
                    style: delilIconButtonStyle(foreground: Colors.blue),
                    icon: const Icon(Icons.save),
                    onPressed: _saveAlbum,
                  ),
                  // ✅ Step-5: Albümlerim butonu
                  IconButton(
                    tooltip: 'Albümlerim',
                    style: delilIconButtonStyle(foreground: Colors.blue),
                    onPressed: _showAlbumsListDialog,
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.photo_album),
                        if (_allAlbums.isNotEmpty)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: const EdgeInsets.all(SeyirTokens.space1),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: SeyirTokens.space4,
                                minHeight: SeyirTokens.space4,
                              ),
                              child: Text(
                                '${_allAlbums.length}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: SeyirTokens.typeCaption,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ROW 5: İçerik
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _needsLogin
                      ? const Padding(
                          padding: EdgeInsets.all(SeyirTokens.space4),
                          child: Center(
                            child: DelilSoftEmpty(
                              title: 'Giriş gerekli',
                              message: 'Albüm oluşturmak için oturum aç.',
                              icon: Icons.lock_outline,
                            ),
                          ),
                        )
                      : _loadError != null
                          ? Padding(
                              padding: const EdgeInsets.all(SeyirTokens.space4),
                              child: Center(
                                child: DelilLoadError(
                                  message: _loadError!,
                                  onRetry: _retryLoad,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.all(SeyirTokens.space4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Albüm Adı
                                  TextField(
                                    controller: _albumNameController,
                                    style: palette.body(),
                                    cursorColor: palette.textPrimary,
                                    decoration: _fieldDecoration(
                                      palette,
                                      label: 'Albüm Adı *',
                                      hint: 'Örn: Tatil Fotoğrafları',
                                      icon: Icons.photo_album,
                                    ),
                                  ),
                                  const SizedBox(height: SeyirTokens.space4),
                                  TextField(
                                    controller: _albumDescriptionController,
                                    style: palette.body(),
                                    cursorColor: palette.textPrimary,
                                    minLines: 2,
                                    maxLines: 4,
                                    textInputAction: TextInputAction.newline,
                                    decoration: _fieldDecoration(
                                      palette,
                                      label: 'Açıklama',
                                      hint: 'Albüm hakkında kısa bir not',
                                      icon: Icons.notes_outlined,
                                      alignLabelWithHint: true,
                                    ),
                                  ),
                                  const SizedBox(height: SeyirTokens.space4),

                                  // Resim Ekle Butonu
                                  ElevatedButton.icon(
                                    onPressed: _showImageSourceDialog,
                                    icon: const Icon(Icons.add_photo_alternate),
                                    label: const Text('Resim Ekle'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: SeyirTokens.space4,
                                      ),
                                      minimumSize: const Size(
                                        SeyirTokens.tapTarget,
                                        SeyirTokens.tapTarget,
                                      ),
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: SeyirTokens.radiusMdAll,
                                      ),
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: SeyirTokens.space6),

                                  // Resimler Listesi
                                  if (_images.isNotEmpty) ...[
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Resimler (${_images.length})',
                                          style: palette.headline(),
                                        ),
                                        // ✅ Step-3.3: Galeri görünümü butonu
                                        TextButton.icon(
                                          onPressed: _currentAlbumId != null
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AlbumGoruntulePage(
                                                        userEmail:
                                                            widget.userEmail,
                                                        albumId:
                                                            _currentAlbumId!,
                                                        initialIndex: 0,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          icon: const Icon(Icons.slideshow),
                                          label: const Text('Galeri Görünümü'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.blue,
                                            minimumSize: const Size(
                                              SeyirTokens.tapTarget,
                                              SeyirTokens.tapTarget,
                                            ),
                                            tapTargetSize:
                                                MaterialTapTargetSize.padded,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: SeyirTokens.space3),
                                    GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 3,
                                        crossAxisSpacing: 8,
                                        mainAxisSpacing: 8,
                                        childAspectRatio: 1,
                                      ),
                                      itemCount: _images.length,
                                      itemBuilder: (context, index) {
                                        final image = _images[index];
                                        return GestureDetector(
                                          onTap: _currentAlbumId != null
                                              ? () {
                                                  Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          AlbumGoruntulePage(
                                                        userEmail:
                                                            widget.userEmail,
                                                        albumId:
                                                            _currentAlbumId!,
                                                        initialIndex: index,
                                                      ),
                                                    ),
                                                  );
                                                }
                                              : null,
                                          child: Stack(
                                            fit: StackFit.expand,
                                            children: [
                                              ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: _getImageProvider(
                                                            image.imageUrl) !=
                                                        null
                                                    ? Image(
                                                        image:
                                                            _getImageProvider(
                                                                image
                                                                    .imageUrl)!,
                                                        fit: BoxFit.cover,
                                                        errorBuilder: (context,
                                                            error, stackTrace) {
                                                          return ColoredBox(
                                                            color: palette
                                                                .surfaceMuted,
                                                            child: Icon(
                                                              Icons
                                                                  .broken_image,
                                                              color: palette
                                                                  .textMuted,
                                                            ),
                                                          );
                                                        },
                                                      )
                                                    : ColoredBox(
                                                        color: palette
                                                            .surfaceMuted,
                                                        child: Icon(
                                                          Icons.image,
                                                          color:
                                                              palette.textMuted,
                                                        ),
                                                      ),
                                              ),
                                              Positioned(
                                                top: 4,
                                                right: 4,
                                                child: GestureDetector(
                                                  onTap: () =>
                                                      _deleteImage(image),
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(4),
                                                    decoration:
                                                        const BoxDecoration(
                                                      color: Colors.red,
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.close,
                                                      color: Colors.white,
                                                      size: 16,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              // ✅ Step-3.4: Resim sıra numarası
                                              Positioned(
                                                bottom: 4,
                                                left: 4,
                                                child: Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                    horizontal:
                                                        SeyirTokens.space2,
                                                    vertical:
                                                        SeyirTokens.space1,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: Colors.black
                                                        .withValues(alpha: 0.6),
                                                    borderRadius:
                                                        SeyirTokens.radiusSmAll,
                                                  ),
                                                  child: Text(
                                                    '${index + 1}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: SeyirTokens
                                                          .typeCaption,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: SeyirTokens.space6),
                                  ],
                                ],
                              ),
                            ),
            ),
          ],
        ),
      ),
    );
  }
}
