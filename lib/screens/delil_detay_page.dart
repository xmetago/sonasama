import 'package:flutter/material.dart';
import 'dart:io';
import 'package:url_launcher/url_launcher.dart';
import '../models/evidence_model.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/video_player_widget.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/evidence_comment_widget.dart';
import '../services/hive_database_service.dart';

class DelilDetayPage extends StatefulWidget {
  final String? userEmail;
  final EvidenceModel evidence;
  final String? userRole; // Kullanıcının rolü (opsiyonel)

  const DelilDetayPage({
    super.key,
    this.userEmail,
    required this.evidence,
    this.userRole,
  });

  @override
  State<DelilDetayPage> createState() => _DelilDetayPageState();
}

class _DelilDetayPageState extends State<DelilDetayPage> {
  String? _currentUserRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  /// Kullanıcının rolünü yükle
  Future<void> _loadUserRole() async {
    if (widget.userEmail == null) return;
    
    try {
      // Accepted davalar içinden kullanıcının rolünü bul
      final acceptedDavalar = await HiveDatabaseService.getAcceptedDavalar(
        widget.userEmail!,
      );
      
      // Bu delilin davaId'sine sahip dava bul
      final dava = acceptedDavalar.firstWhere(
        (d) {
          final davaId = (d['davaId'] as String?) ?? (d['id'] as String?);
          return davaId?.trim().toLowerCase() == 
                 widget.evidence.davaId.trim().toLowerCase();
        },
        orElse: () => {},
      );
      
      if (dava.isNotEmpty) {
        setState(() {
          _currentUserRole = (dava['userRole'] as String?) ?? 
                           (dava['mevkii'] as String?);
        });
      }
    } catch (e) {
      print('❌ Kullanıcı rolü yüklenirken hata: $e');
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

            // ROW 4: Başlık
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
                      "DELİL DETAYI",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(width: 48), // Dengeleme için
                ],
              ),
            ),

            // ROW 5: İçerik
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Delil Bilgileri Kartı
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Başlık ve Tip
                            Row(
                              children: [
                                _getEvidenceIcon(widget.evidence.type),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.evidence.title,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        _getEvidenceTypeText(widget.evidence.type),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Açıklama
                            const Text(
                              'Açıklama:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.evidence.description,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 16),

                            // Detay Bilgileri
                            _buildDetailInfo('Delil ID', widget.evidence.id),
                            _buildDetailInfo('Dava ID', widget.evidence.davaId),
                            _buildDetailInfo('Ekleyen', widget.evidence.userId),
                            _buildDetailInfo('Eklenme Tarihi', _formatDate(widget.evidence.createdAt)),
                            if (widget.evidence.fileSize > 0)
                              _buildDetailInfo('Dosya Boyutu', _formatFileSize(widget.evidence.fileSize)),
                            _buildDetailInfo('Doğrulandı', widget.evidence.isVerified ? 'Evet' : 'Hayır'),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Delil İçeriği
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                _getEvidenceIcon(widget.evidence.type),
                                const SizedBox(width: 8),
                                const Text(
                                  'Delil İçeriği',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildEvidenceContent(),
                          ],
                        ),
                      ),
                    ),
                    
                    // Rol Yorumları Bölümü
                    EvidenceCommentWidget(
                      evidenceId: widget.evidence.id,
                      davaId: widget.evidence.davaId,
                      userEmail: widget.userEmail,
                      currentUserRole: widget.userRole ?? _currentUserRole,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfo(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceContent() {
    switch (widget.evidence.type) {
      case 'image':
        return _buildImageContent();
      case 'video':
        return _buildVideoContent();
      case 'text':
        return _buildPdfContent();
      case 'link':
        return _buildLinkContent();
      default:
        return const Text('Bilinmeyen delil türü');
    }
  }

  Widget _buildImageContent() {
    if (widget.evidence.filePath.isEmpty) {
      return const Text('Resim dosyası bulunamadı');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 300,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(widget.evidence.filePath),
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('Resim yüklenemedi'),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _openImageFullScreen(),
          icon: const Icon(Icons.fullscreen),
          label: const Text('Tam Ekran Görüntüle'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildVideoContent() {
    if (widget.evidence.filePath.isEmpty) {
      return const Text('Video dosyası bulunamadı');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.black,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Video thumbnail veya placeholder
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[900],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.video_library, size: 48, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Video Önizlemesi',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Play butonu overlay
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () => _openVideoPlayer(),
                  icon: const Icon(
                    Icons.play_arrow,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openVideoPlayer(),
                icon: const Icon(Icons.play_arrow),
                label: const Text('Videoyu Oynat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showVideoInfo(),
              icon: const Icon(Icons.info),
              label: const Text('Bilgi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPdfContent() {
    if (widget.evidence.filePath.isEmpty) {
      return const Text('PDF dosyası bulunamadı');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[100],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // PDF thumbnail veya placeholder
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[50],
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.picture_as_pdf, size: 48, color: Colors.red),
                      SizedBox(height: 8),
                      Text(
                        'PDF Dosyası',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
              
              // PDF açma butonu overlay
              Positioned(
                bottom: 16,
                right: 16,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    onPressed: () => _openPdfViewer(),
                    icon: const Icon(
                      Icons.open_in_new,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _openPdfViewer(),
                icon: const Icon(Icons.open_in_new),
                label: const Text('PDF\'i Aç'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              onPressed: () => _showPdfInfo(),
              icon: const Icon(Icons.info),
              label: const Text('Bilgi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLinkContent() {
    if (widget.evidence.url.isEmpty) {
      return const Text('Link bulunamadı');
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
            color: Colors.grey[50],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Link:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                widget.evidence.url,
                style: const TextStyle(
                  color: Colors.blue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => _openLink(),
          icon: const Icon(Icons.open_in_new),
          label: const Text('Linki Aç'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _getEvidenceIcon(String type) {
    switch (type) {
      case 'image':
        return const Icon(Icons.image, color: Colors.blue, size: 32);
      case 'video':
        return const Icon(Icons.video_library, color: Colors.red, size: 32);
      case 'text':
        return const Icon(Icons.description, color: Colors.orange, size: 32);
      case 'link':
        return const Icon(Icons.link, color: Colors.green, size: 32);
      default:
        return const Icon(Icons.attachment, size: 32);
    }
  }

  String _getEvidenceTypeText(String type) {
    switch (type) {
      case 'image':
        return 'Resim';
      case 'video':
        return 'Video';
      case 'text':
        return 'PDF';
      case 'link':
        return 'Link';
      default:
        return 'Bilinmeyen';
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  void _openImageFullScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text(widget.evidence.title),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),
          body: Container(
            color: Colors.black,
            child: Center(
              child: InteractiveViewer(
                child: Image.file(File(widget.evidence.filePath)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openVideoPlayer() {
    try {
      print('🎥 Video player açılıyor: ${widget.evidence.filePath}');
      
      if (widget.evidence.filePath.isEmpty) {
        print('❌ Video dosyası bulunamadı');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Video dosyası bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Video dosyasının var olup olmadığını kontrol et
      final videoFile = File(widget.evidence.filePath);
      if (!videoFile.existsSync()) {
        print('❌ Video dosyası mevcut değil: ${widget.evidence.filePath}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Video dosyası bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomVideoPlayer(
            videoPath: widget.evidence.filePath,
            title: widget.evidence.title,
          ),
        ),
      );
      
      print('✅ Video player açıldı');
    } catch (e) {
      print('❌ Video player açılırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Video açılırken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showVideoInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Video Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Dosya Yolu:', widget.evidence.filePath),
            _buildInfoRow('Dosya Boyutu:', _formatFileSize(widget.evidence.fileSize)),
            _buildInfoRow('Eklenme Tarihi:', _formatDate(widget.evidence.createdAt)),
            _buildInfoRow('Ekleyen:', widget.evidence.userId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(value),
        ],
      ),
    );
  }

  void _openPdfViewer() {
    try {
      print('📄 PDF viewer açılıyor: ${widget.evidence.filePath}');
      
      if (widget.evidence.filePath.isEmpty) {
        print('❌ PDF dosyası bulunamadı');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ PDF dosyası bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // PDF dosyasının var olup olmadığını kontrol et
      final pdfFile = File(widget.evidence.filePath);
      if (!pdfFile.existsSync()) {
        print('❌ PDF dosyası mevcut değil: ${widget.evidence.filePath}');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ PDF dosyası bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CustomPdfViewer(
            pdfPath: widget.evidence.filePath,
            title: widget.evidence.title,
          ),
        ),
      );
      
      print('✅ PDF viewer açıldı');
    } catch (e) {
      print('❌ PDF viewer açılırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ PDF açılırken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showPdfInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Bilgileri'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Dosya Yolu:', widget.evidence.filePath),
            _buildInfoRow('Dosya Boyutu:', _formatFileSize(widget.evidence.fileSize)),
            _buildInfoRow('Eklenme Tarihi:', _formatDate(widget.evidence.createdAt)),
            _buildInfoRow('Ekleyen:', widget.evidence.userId),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  void _openLink() async {
    try {
      print('🔗 Link açma işlemi başlatılıyor: ${widget.evidence.url}');
      
      // URL'nin boş olup olmadığını kontrol et
      if (widget.evidence.url.isEmpty) {
        print('❌ URL boş');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Link bulunamadı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // URL formatını kontrol et
      String urlString = widget.evidence.url;
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
        print('🔗 URL formatı düzeltildi: $urlString');
      }

      final Uri url = Uri.parse(urlString);
      print('🔗 URL parse edildi: $url');

      // URL'nin geçerli olup olmadığını kontrol et
      if (!url.hasScheme || !url.hasAuthority) {
        print('❌ Geçersiz URL formatı');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Geçersiz link formatı'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // URL'yi açabilir miyiz kontrol et
      if (await canLaunchUrl(url)) {
        print('✅ URL açılabilir, açılıyor...');
        final result = await launchUrl(
          url,
          mode: LaunchMode.externalApplication,
        );
        
        if (result) {
          print('✅ Link başarıyla açıldı');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Link açıldı'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          print('❌ Link açılamadı');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('❌ Link açılamadı'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        print('❌ URL açılamaz');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Bu link açılamaz: ${widget.evidence.url}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('❌ Link açılırken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Link açılırken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
