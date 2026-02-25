import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/album_model.dart';
import '../models/album_image_model.dart';
import '../services/hive_database_service.dart';

/// ✅ Step-3: Albüm görüntüleme sayfası (galeri modu, tam ekran)
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class AlbumGoruntulePage extends StatefulWidget {
  final String? userEmail;
  final String albumId;
  final int initialIndex;

  const AlbumGoruntulePage({
    super.key,
    this.userEmail,
    required this.albumId,
    this.initialIndex = 0,
  });

  @override
  State<AlbumGoruntulePage> createState() => _AlbumGoruntulePageState();
}

class _AlbumGoruntulePageState extends State<AlbumGoruntulePage> {
  late PageController _pageController;
  late int _currentIndex;
  List<AlbumImageModel> _images = [];
  AlbumModel? _album;

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
    if (widget.userEmail != null) {
      try {
        final albums = HiveDatabaseService.getAlbums(widget.userEmail!);
        _album = albums.firstWhere(
          (a) => a.id == widget.albumId,
          orElse: () => throw Exception('Albüm bulunamadı'),
        );
        _images = HiveDatabaseService.getAlbumImages(widget.albumId);
        setState(() {});
      } catch (e) {
        print('❌ Albüm yüklenirken hata: $e');
      }
    }
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

  @override
  Widget build(BuildContext context) {
    if (_images.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_album?.name ?? 'Albüm'),
        ),
        body: const Center(
          child: Text('Albümde resim bulunmuyor'),
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
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      _album?.name ?? 'Albüm',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Geri butonu genişliği kadar boşluk
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
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
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
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (_images[_currentIndex].title != null &&
                        _images[_currentIndex].title!.isNotEmpty) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          _images[_currentIndex].title!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
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

