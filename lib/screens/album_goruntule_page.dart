import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/album_model.dart';
import '../models/album_image_model.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/delil_surface.dart';
import 'package:its19/utils/app_logger.dart';

/// ✅ Step-3: Albüm görüntüleme sayfası (galeri modu, tam ekran)
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class AlbumGoruntulePage extends StatefulWidget {
  final String? userEmail;
  final String albumId;
  final int initialIndex;

  /// Test: albüm yüklenemesin.
  final bool forceLoadError;

  const AlbumGoruntulePage({
    super.key,
    this.userEmail,
    required this.albumId,
    this.initialIndex = 0,
    this.forceLoadError = false,
  });

  @override
  State<AlbumGoruntulePage> createState() => _AlbumGoruntulePageState();
}

class _AlbumGoruntulePageState extends State<AlbumGoruntulePage> {
  late PageController _pageController;
  late int _currentIndex;
  List<AlbumImageModel> _images = [];
  AlbumModel? _album;
  bool _isLoading = true;
  bool _needsLogin = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    _loadAlbumData();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// ✅ Step-3.1: Albüm verilerini yükle
  void _loadAlbumData() {
    var needsLogin = false;
    String? loadError;
    AlbumModel? album;
    var images = <AlbumImageModel>[];

    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) {
      needsLogin = true;
    } else {
      try {
        if (widget.forceLoadError) {
          throw Exception('Albüm yüklenemedi');
        }
        final albums = HiveDatabaseService.getAlbums(email);
        album = albums.firstWhere(
          (a) => a.id == widget.albumId,
          orElse: () => throw Exception('Albüm bulunamadı'),
        );
        images = HiveDatabaseService.getAlbumImages(widget.albumId);
      } catch (e) {
        appLog('❌ Albüm yüklenirken hata: $e');
        loadError = 'Albüm yüklenemedi';
      }
    }

    if (!mounted) return;
    setState(() {
      _needsLogin = needsLogin;
      _loadError = loadError;
      _album = album;
      _images = images;
      _isLoading = false;
      if (images.isNotEmpty && _currentIndex >= images.length) {
        _currentIndex = images.length - 1;
      }
    });
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

  Widget _statusScaffold({required String title, required Widget body}) {
    final palette = SeyirPalette.of(context);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        backgroundColor: palette.surface,
        foregroundColor: palette.textPrimary,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Geri',
          style: delilIconButtonStyle(foreground: palette.textPrimary),
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: palette.headline()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        child: Center(child: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final title = _album?.name ?? 'Albüm';

    if (_isLoading) {
      return Scaffold(
        backgroundColor: palette.surface,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsLogin) {
      return _statusScaffold(
        title: 'Albüm',
        body: const DelilSoftEmpty(
          title: 'Giriş gerekli',
          message: 'Albümü görmek için oturum aç.',
          icon: Icons.lock_outline,
        ),
      );
    }

    if (_loadError != null) {
      return _statusScaffold(
        title: title,
        body: DelilLoadError(
          message: _loadError!,
          onRetry: () {
            setState(() => _isLoading = true);
            _loadAlbumData();
          },
        ),
      );
    }

    if (_images.isEmpty) {
      return _statusScaffold(
        title: title,
        body: const DelilSoftEmpty(
          title: 'Albümde resim bulunmuyor',
          message: 'Bu albüme henüz fotoğraf eklenmedi.',
          icon: Icons.photo_outlined,
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ✅ Step-3.2: PageView ile tam ekran görüntüleme
          PageView.builder(
            controller: _pageController,
            itemCount: _images.length,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final image = _images[index];
              final imageProvider = _getImageProvider(image.imageUrl);

              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: imageProvider != null
                      ? Image(
                          image: imageProvider,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.white,
                                size: 64,
                              ),
                            );
                          },
                        )
                      : const Center(
                          child: Icon(
                            Icons.image,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                ),
              );
            },
          ),

          // Üst bar (başlık ve geri butonu)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Geri',
                    style: delilIconButtonStyle(foreground: Colors.white),
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: SeyirTokens.typeHeadline,
                        fontWeight: FontWeight.w800,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: SeyirTokens.tapTarget),
                ],
              ),
            ),
          ),

          // Alt bar (resim sayısı ve bilgiler)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(SeyirTokens.space4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_currentIndex + 1} / ${_images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: SeyirTokens.typeTitle,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_images[_currentIndex].title != null &&
                        _images[_currentIndex].title!.isNotEmpty) ...[
                      const SizedBox(width: SeyirTokens.space4),
                      Expanded(
                        child: Text(
                          _images[_currentIndex].title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: SeyirTokens.typeBody,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
