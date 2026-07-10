import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/common_header_widgets.dart';
import '../models/evidence_model.dart';
import '../services/evidence_service.dart';
import '../services/hive_database_service.dart';
import 'delil_detay_page.dart';

class DelilEklePage extends StatefulWidget {
  final String? userEmail;
  final String davaId; // Hangi davaya delil ekleneceği
  final String davaAdi; // Dava adı

  const DelilEklePage({
    super.key,
    this.userEmail,
    required this.davaId,
    required this.davaAdi,
  });

  @override
  State<DelilEklePage> createState() => _DelilEklePageState();
}

class _DelilEklePageState extends State<DelilEklePage> {
  final EvidenceService _evidenceService = EvidenceService();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _linkController = TextEditingController();

  List<EvidenceModel> _evidences = [];
  Map<String, int> _evidenceCounts = {'image': 0, 'video': 0, 'text': 0, 'link': 0};

  bool _isLoading = false;
  bool _isDavaOpened = false; // Dava açılıp açılmadığını kontrol etmek için

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Sayfa her açıldığında dava durumunu kontrol et
    _checkDavaStatus();
  }

  Future<void> _initializeData() async {
    setState(() => _isLoading = true);
    try {
      await _evidenceService.initialize();
      _loadEvidenceData();
      _checkDavaStatus(); // Dava durumunu kontrol et
    } catch (e) {
      print('❌ Veri başlatılırken hata: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _loadEvidenceData() {
    _evidences = _evidenceService.getEvidenceByDavaId(widget.davaId);
    _evidenceCounts = _evidenceService.getEvidenceCountsByDavaId(widget.davaId);
    setState(() {});
  }

  // Dava durumunu kontrol et (açılıp açılmadığını)
  void _checkDavaStatus() async {
    try {
      // Veritabanından dava durumunu kontrol et
      final davaModel = HiveDatabaseService.getDava(widget.davaId);
      if (davaModel != null) {
        setState(() {
          _isDavaOpened = davaModel.isOpened;
        });
      } else {
        // Dava bulunamazsa açılmamış kabul et
        setState(() {
          _isDavaOpened = false;
        });
      }
    } catch (e) {
      print('❌ Dava durumu kontrol edilirken hata: $e');
      // Hata durumunda açılmamış kabul et
      setState(() {
        _isDavaOpened = false;
      });
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
                  const SizedBox(width: 1),
                  Expanded(
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "DELİL EKLE ", // Parametre varsa onu kullan, yoksa varsayılan
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(width:1 ),
                  Tooltip(
                    message: 'Delil Ekle',
                    child: IconButton(
                      onPressed: !_isDavaOpened ? () => _openEvidenceAddSheet('image') : null,
                      icon: Icon(
                        Icons.add_circle_outline_outlined,
                        size: 28,
                        color: !_isDavaOpened ? Colors.blue[700] : Colors.grey[400],
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: !_isDavaOpened ? Colors.blue.withOpacity(0.1) : null,
                        padding: const EdgeInsets.all(6),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ROW 5: İçerik
            Expanded(
              child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dava açıldıysa uyarı mesajı
                        if (_isDavaOpened)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              border: Border.all(color: Colors.red, width: 2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.block, color: Colors.red, size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'DAVA AÇILDI!',
                                        style: TextStyle(
                                          color: Colors.red, 
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Dava açıldığı için delil eklenemez veya silinemez. Sadece mevcut delilleri görüntüleyebilirsiniz.',
                                        style: TextStyle(
                                          color: Colors.red[700], 
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),

                        // Delil Türleri
                        _buildEvidenceTypes(),
                        
                        // Dava açıldıysa ek uyarı
                        if (_isDavaOpened) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, color: Colors.grey[600], size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Tüm delil ekleme butonları devre dışı bırakıldı',
                                    style: TextStyle(
                                      color: Colors.grey[600], 
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        
                        const SizedBox(height: 24),

                        // Mevcut Deliller
                        if (_evidences.isNotEmpty) _buildExistingEvidence(),
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          enabled: enabled,
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[400]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEvidenceTypes() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: "Dava Delilleri ||  ",
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black, // Ana metin rengi
            ),
            children: [
              TextSpan(
                text: widget.davaAdi ?? 'Bilinmeyen Dava',
                style: const TextStyle(
                  color: Colors.blue, // Vurgulanacak mavi tonu
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Resim Ekleme
        _buildEvidenceTypeCard(
          icon: Icons.image,
          title: 'Resim Ekle',
          subtitle: 'JPG, PNG, GIF formatları (Max: 5MB)',
          count: _evidenceCounts['image'] ?? 0,
          maxCount: EvidenceLimits.maxImages,
          onTap: _isDavaOpened ? null : () => _openEvidenceAddSheet('image'),
          color: Colors.blue,
        ),

        const SizedBox(height: 12),

        // Video Ekleme
        _buildEvidenceTypeCard(
          icon: Icons.video_library,
          title: 'Video Ekle',
          subtitle: 'MP4, AVI, MOV formatları (Max: 40MB)',
          count: _evidenceCounts['video'] ?? 0,
          maxCount: EvidenceLimits.maxVideos,
          onTap: _isDavaOpened ? null : () => _openEvidenceAddSheet('video'),
          color: Colors.red,
        ),

        const SizedBox(height: 12),

        // PDF Ekleme
        _buildEvidenceTypeCard(
          icon: Icons.description,
          title: 'PDF Ekle',
          subtitle: 'PDF formatı (Max: 10MB)',
          count: _evidenceCounts['text'] ?? 0,
          maxCount: EvidenceLimits.maxPdfs,
          onTap: _isDavaOpened ? null : () => _openEvidenceAddSheet('text'),
          color: Colors.orange,
        ),

        const SizedBox(height: 12),

        // Link Ekleme
        _buildEvidenceTypeCard(
          icon: Icons.link,
          title: 'Link Ekle',
          subtitle: 'Güvenli web linkleri',
          count: _evidenceCounts['link'] ?? 0,
          maxCount: EvidenceLimits.maxLinks,
          onTap: _isDavaOpened ? null : () => _openEvidenceAddSheet('link'),
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildEvidenceTypeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required int count,
    required int maxCount,
    required VoidCallback? onTap,
    required Color color,
  }) {
    final isMaxReached = count >= maxCount;
    final isDisabled = _isDavaOpened || isMaxReached;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isDisabled ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(isDisabled ? 0.3 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: isDisabled ? Colors.grey : color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDisabled ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count / $maxCount',
                      style: TextStyle(
                        fontSize: 12,
                        color: isMaxReached ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: isDisabled ? null : 'Delil ekle',
                onPressed: isDisabled ? null : onTap,
                icon: Icon(
                  isDisabled ? Icons.block : Icons.add_circle_outline,
                  color: isDisabled ? Colors.grey : color,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEvidenceAddSheet(String type) {
    if (_isDavaOpened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Dava açıldığı için delil eklenemez')),
      );
      return;
    }

    // Sheet her açıldığında temiz başlasın
    _titleController.clear();
    _descriptionController.clear();
    _linkController.clear();

    bool validateTitleDesc() {
      if (_titleController.text.trim().isEmpty || _descriptionController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen başlık ve açıklama alanlarını doldurun')),
        );
        return false;
      }
      if (_descriptionController.text.trim().length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Açıklama en az 6 karakter olmalı')),
        );
        return false;
      }
      return true;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 16 + bottomInset),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Icon(
                    _getSheetTypeIcon(type),
                    size: 32,
                    color: _getSheetTypeColor(type),
                  ),
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _titleController,
                  label: 'Delil Başlığı',
                  hint: 'Delil için açıklayıcı başlık girin (min 1 karakter)',
                  maxLines: 1,
                  enabled: true,
                ),
                const SizedBox(height: 10),
                _buildInputField(
                  controller: _descriptionController,
                  label: 'Delil Açıklaması',
                  hint: 'Delil hakkında detaylı açıklama yazın (min 6 karakter)',
                  maxLines: 3,
                  enabled: true,
                ),
                const SizedBox(height: 12),
                if (type == 'link') ...[
                  TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      labelText: 'URL',
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                ],
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('İptal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          if (!validateTitleDesc()) return;

                          Navigator.pop(context);
                          if (type == 'image') {
                            _showImageUploadDialog();
                          } else if (type == 'video') {
                            _showVideoUploadDialog();
                          } else if (type == 'text') {
                            _showPdfUploadDialog();
                          } else if (type == 'link') {
                            _addLink();
                          }
                        },
                        child: Text(type == 'link' ? 'Ekle' : 'Devam'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExistingEvidence() {
    print('🔍 _buildExistingEvidence çağrıldı, delil sayısı: ${_evidences.length}');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Mevcut Deliller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_evidences.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _evidences.length,
          itemBuilder: (context, index) {
            final evidence = _evidences[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _getEvidenceIcon(evidence.type),
                title: Text(evidence.title),
                subtitle: Text(evidence.description),
                onTap: () => _openEvidenceDetail(evidence),
                trailing: _isDavaOpened
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteEvidence(evidence.id),
                    ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getEvidenceIcon(String type) {
    switch (type) {
      case 'image':
        return const Icon(Icons.image, color: Colors.blue);
      case 'video':
        return const Icon(Icons.video_library, color: Colors.red);
      case 'text':
        return const Icon(Icons.description, color: Colors.orange);
      case 'link':
        return const Icon(Icons.link, color: Colors.green);
      default:
        return const Icon(Icons.attachment);
    }
  }

  IconData _getSheetTypeIcon(String type) {
    switch (type) {
      case 'image':
        return Icons.image_search_outlined;
      case 'video':
        return Icons.video_library_outlined;
      case 'text':
        return Icons.picture_as_pdf_outlined;
      case 'link':
        return Icons.link_outlined;
      default:
        return Icons.add_circle_outline;
    }
  }

  Color _getSheetTypeColor(String type) {
    switch (type) {
      case 'image':
        return Colors.blue;
      case 'video':
        return Colors.red;
      case 'text':
        return Colors.orange;
      case 'link':
        return Colors.green;
      default:
        return Colors.black54;
    }
  }

  // Resim yükleme dialog'u
  void _showImageUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        const Color accentColor = Color(0xFF27D6CE);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.35), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RESIM YUKLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey[800],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Resmi nereden eklemek istiyorsun?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.camera);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor.withOpacity(0.85)),
                              foregroundColor: accentColor.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'KAMERA',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickImage(ImageSource.gallery);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text(
                              'GALERI',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.image_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Video yükleme dialog'u
  void _showVideoUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        const Color accentColor = Color(0xFFE53935);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.35), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'VIDEO YUKLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey[800],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Videoyu nereden eklemek istiyorsun?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickVideo(ImageSource.camera);
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor.withOpacity(0.85)),
                              foregroundColor: accentColor.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'KAMERA',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _pickVideo(ImageSource.gallery);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text(
                              'GALERI',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.videocam_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // PDF yükleme dialog'u
  void _showPdfUploadDialog() {
    showDialog(
      context: context,
      builder: (context) {
        const Color accentColor = Color(0xFFFF9800);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.35), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'PDF YUKLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey[800],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'PDF dosyasini cihazindan secip ekleyebilirsin.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _pickPdf();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                        ),
                        child: const Text(
                          'DOSYA SEC',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.picture_as_pdf_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Link ekleme dialog'u
  void _showLinkDialog() {
    showDialog(
      context: context,
      builder: (context) {
        const Color accentColor = Color(0xFF2E7D32);
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withOpacity(0.35), width: 1.4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 18,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'LINK EKLE',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: Colors.grey[800],
                          ),
                        ),
                        InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(4.0),
                            child: Icon(Icons.close, size: 18, color: Colors.black54),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _linkController,
                      decoration: InputDecoration(
                        labelText: 'URL',
                        hintText: 'https://example.com',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: accentColor, width: 1.6),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: accentColor.withOpacity(0.85)),
                              foregroundColor: accentColor.withOpacity(0.95),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'IPTAL',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _addLink();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: accentColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              elevation: 0,
                            ),
                            child: const Text(
                              'EKLE',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: -32,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: accentColor.withOpacity(0.35),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            accentColor,
                            accentColor.withOpacity(0.85),
                          ],
                        ),
                      ),
                      child: const Icon(
                        Icons.link_outlined,
                        size: 30,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Resim seçme (gerçek implementasyon)
  void _pickImage(ImageSource source) async {
    try {
      print('📸 Resim seçme başlatılıyor... Source: $source');
      
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        print('📸 Resim seçildi: ${image.path}');
        
        final file = File(image.path);
        
        // Dosyanın var olup olmadığını kontrol et
        if (!await file.exists()) {
          print('❌ Dosya bulunamadı: ${image.path}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Seçilen dosya bulunamadı')),
          );
          return;
        }
        
        final fileSize = await file.length();
        print('📸 Dosya boyutu: $fileSize bytes (${(fileSize / (1024 * 1024)).toStringAsFixed(2)} MB)');

        // Dosya boyutu kontrolü
        if (fileSize > EvidenceLimits.maxImageSize) {
          print('❌ Dosya boyutu çok büyük: $fileSize > ${EvidenceLimits.maxImageSize}');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Resim dosyası ${EvidenceLimits.maxImageSize ~/ (1024 * 1024)}MB\'dan büyük olamaz')),
          );
          return;
        }

        // Dosya uzantısını kontrol et
        final extension = image.path.split('.').last.toLowerCase();
        if (!EvidenceLimits.allowedImageExtensions.contains(extension)) {
          print('❌ Geçersiz dosya uzantısı: $extension');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Geçersiz dosya formatı. İzin verilen formatlar: ${EvidenceLimits.allowedImageExtensions.join(', ')}')),
          );
          return;
        }

        print('✅ Resim doğrulandı, delil ekleniyor...');
        await _addEvidence('image', image.path, fileSize);
      } else {
        print('📸 Resim seçimi iptal edildi');
      }
    } catch (e) {
      print('❌ Resim seçilirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Resim seçilirken hata: $e')),
      );
    }
  }

  // Video seçme (gerçek implementasyon)
  void _pickVideo(ImageSource source) async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? video = await picker.pickVideo(
        source: source,
        maxDuration: const Duration(minutes: 10), // 10 dakika limit
      );

      if (video != null) {
        final file = File(video.path);
        final fileSize = await file.length();

        // Dosya boyutu kontrolü
        if (fileSize > EvidenceLimits.maxVideoSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ Video dosyası ${EvidenceLimits.maxVideoSize ~/ (1024 * 1024)}MB\'dan büyük olamaz')),
          );
          return;
        }

        await _addEvidence('video', video.path, fileSize);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Video seçilirken hata: $e')),
      );
    }
  }

  // PDF seçme (gerçek implementasyon)
  void _pickPdf() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        final file = File(result.files.single.path!);
        final fileSize = await file.length();

        // Dosya boyutu kontrolü
        if (fileSize > EvidenceLimits.maxPdfSize) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('❌ PDF dosyası ${EvidenceLimits.maxPdfSize ~/ (1024 * 1024)}MB\'dan büyük olamaz')),
          );
          return;
        }

        await _addEvidence('text', result.files.single.path!, fileSize);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ PDF seçilirken hata: $e')),
      );
    }
  }

  // Link ekleme
  void _addLink() async {
    if (_linkController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen geçerli bir URL girin')),
      );
      return;
    }

    // Basit URL doğrulama
    if (!_linkController.text.startsWith('http://') &&
        !_linkController.text.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir URL girin (http:// veya https:// ile başlamalı)')),
      );
      return;
    }

    await _addEvidence('link', _linkController.text, 0);
    _linkController.clear();
  }

  // Delil ekleme (geliştirilmiş doğrulama ile)
  Future<void> _addEvidence(String type, String content, int fileSize) async {
    print('🔍 Delil ekleme başlatılıyor...');
    print('📋 Tip: $type, İçerik: $content, Boyut: $fileSize');
    
    if (_titleController.text.isEmpty || _descriptionController.text.isEmpty) {
      print('❌ Başlık veya açıklama boş');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen başlık ve açıklama alanlarını doldurun')),
      );
      return;
    }

    try {
      print('🔍 EvidenceModel oluşturuluyor...');
      final evidence = EvidenceModel(
        id: '', // ID otomatik oluşturulacak
        davaId: widget.davaId,
        type: type,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        filePath: type != 'link' ? content : '',
        url: type == 'link' ? content : '',
        fileSize: fileSize,
        createdAt: DateTime.now(),
        isVerified: type == 'link' ? _verifyLink(content) : true,
        userId: widget.userEmail ?? 'unknown',
      );

      print('🔍 EvidenceService.addEvidence çağrılıyor...');
      final result = await _evidenceService.addEvidence(evidence);

      print('🔍 Sonuç: $result');

      if (result['isValid']) {
        print('✅ Delil başarıyla eklendi');
        
        // Form temizleme
        _titleController.clear();
        _descriptionController.clear();

        // Verileri yenileme
        _loadEvidenceData();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${result['evidence'].title} başarıyla eklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      } else {
        print('❌ Delil eklenemedi: ${result['error']}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['error']}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ Delil eklenirken hata: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Delil eklenirken hata: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Link doğrulama (geliştirilmiş)
  bool _verifyLink(String url) {
    // Daha kapsamlı güvenlik kontrolü
    final lowerUrl = url.toLowerCase();

    // Zararlı kelime kontrolü
    final maliciousKeywords = [
      'malicious', 'suspicious', 'phishing', 'scam', 'fake',
      'virus', 'malware', 'spam', 'fraud', 'hack'
    ];

    for (final keyword in maliciousKeywords) {
      if (lowerUrl.contains(keyword)) {
        return false;
      }
    }

    // HTTPS kontrolü (daha güvenli)
    if (!url.startsWith('https://')) {
      return false;
    }

    return true;
  }

  // Delil detay sayfasını aç
  void _openEvidenceDetail(EvidenceModel evidence) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DelilDetayPage(
          userEmail: widget.userEmail,
          evidence: evidence,
        ),
      ),
    );
  }

  // Delil silme
  Future<void> _deleteEvidence(String evidenceId) async {
    if (_isDavaOpened) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Dava açıldığı için delil silinemez')),
      );
      return;
    }

    try {
      await _evidenceService.deleteEvidence(evidenceId);
      _loadEvidenceData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Delil silindi')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Delil silinirken hata: $e')),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _linkController.dispose();
    super.dispose();
  }
}
