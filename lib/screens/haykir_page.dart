import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../data/direm_data.dart';
import '../providers/dava_provider.dart';
import 'saved_widgets_page.dart';
import '../widgets/expandable_comment_text.dart';

// Model class for Haykir
class Haykir {
  final String adi;
  final String slogan;
  final String direme;
  final String kalanSure;
  final String profilResmi;

  Haykir({
    required this.adi,
    required this.slogan,
    required this.direme,
    required this.kalanSure,
    required this.profilResmi,
  });
}



class HaykirPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final bool initialShowForm; // Sayfa açıldığında formu otomatik aç

  const HaykirPage({
    super.key, 
    this.userEmail,
    this.initialShowForm = false,
  });

  @override
  State<HaykirPage> createState() => _HaykirPageState();
}

class _HaykirPageState extends State<HaykirPage> {
  int? expandedCardIndex;
  bool showLeftIcons = false; // Sol ikonları gösterme durumu
  
  // Yeni haykırış oluşturma formu için state değişkenleri
  bool showCreateForm = false;
  final TextEditingController _adiController = TextEditingController();
  final TextEditingController _sloganController = TextEditingController();
  final TextEditingController _detayController = TextEditingController();
  final TextEditingController _ozelDiremController = TextEditingController();
  String? _selectedDireme;
  
  // Direm kategorisi seçimi
  int _selectedCategoryIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Eğer initialShowForm true ise formu otomatik aç
    if (widget.initialShowForm) {
      showCreateForm = true;
    }
  }
  
  @override
  void dispose() {
    _adiController.dispose();
    _sloganController.dispose();
    _detayController.dispose();
    _ozelDiremController.dispose();
    super.dispose();
  }
  
  // Haykırış oluşturma için validasyon
  bool get _canHaykir {
    final detayText = _detayController.text.trim();
    return _adiController.text.trim().isNotEmpty &&
           _sloganController.text.trim().isNotEmpty &&
           (_selectedDireme != null || _ozelDiremController.text.trim().isNotEmpty) &&
           detayText.isNotEmpty &&
           detayText.length >= 19 && // ✅ En az 19 karakter
           detayText.length <= 361; // ✅ En fazla 361 karakter
  }
  
  // Kalan süreyi hesapla
  String _calculateRemainingTime(String? createdAt) {
    if (createdAt == null) return '76 saat 0 dakika';
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      final totalMinutes = (76 * 60) - difference.inMinutes;
      
      if (totalMinutes <= 0) {
        return 'Süre doldu';
      }
      
      final remainingHours = totalMinutes ~/ 60;
      final remainingMinutes = totalMinutes % 60;
      
      return '$remainingHours saat $remainingMinutes dakika';
    } catch (e) {
      return '76 saat 0 dakika';
    }
  }
  
  // Haykırışı yayınla
  Future<void> _publishHaykir(Map<String, dynamic> haykirData) async {
    try {
      // Kullanıcı email'i ekle
      if (widget.userEmail != null) {
        haykirData['userEmail'] = widget.userEmail;
      }
      
      // Özel diren varsa ekle
      if (_ozelDiremController.text.trim().isNotEmpty) {
        final ozelDiremText = _ozelDiremController.text.trim();
        haykirData['direme'] = ozelDiremText;
        // ✅ Boolean değeri String'e dönüştür
        haykirData['isOzelDirem'] = 'true';
        
        // ✅ Özel direni "Başka bir diren" kategorisine ekle
        await HiveDatabaseService.addOzelDirem(ozelDiremText);
      }
      
      // Aktif durumu ekle - ✅ Boolean değeri String'e dönüştür
      haykirData['isActive'] = 'true';
      
      // ✅ Tüm değerleri String formatına dönüştür (güvenlik için)
      final cleanHaykirData = <String, dynamic>{};
      haykirData.forEach((key, value) {
        if (value == null) {
          cleanHaykirData[key] = '';
        } else if (value is bool) {
          cleanHaykirData[key] = value.toString();
        } else {
          cleanHaykirData[key] = value.toString();
        }
      });
      
      // ✅ Haykır ID'sini önceden oluştur (seyir defterine eklemek için gerekli)
      final haykirId = cleanHaykirData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      cleanHaykirData['id'] = haykirId;
      
      // ✅ Veritabanına kaydet
      await HiveDatabaseService.addHaykir(cleanHaykirData);
      
      // ✅ Adım 1: Haykır yayınlandığında seyir defterine ekle
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        try {
          print('🔵 Haykır seyir defterine ekleniyor... userEmail: ${widget.userEmail}, haykirId: $haykirId');
          
          final davaProvider = Provider.of<DavaProvider>(context, listen: false);
          final postId = 'haykir_$haykirId';
          final nowIso = DateTime.now().toIso8601String();
          
          // Etkileşim istatistikleri için başlangıç değerleri
          final haykirPostData = {
            'id': postId,
            'type': 'haykir',
            'createdAt': nowIso,
            'authorEmail': widget.userEmail,
            'payload': {
              'haykirId': haykirId,
              'adi': cleanHaykirData['adi'] ?? '',
              'slogan': cleanHaykirData['slogan'] ?? '',
              'direme': cleanHaykirData['direme'] ?? '',
              'detaylar': cleanHaykirData['detaylar'] ?? '',
              'createdAt': cleanHaykirData['createdAt'] ?? nowIso,
              // Etkileşim istatistikleri
              'commentCount': 0,
              'retweetCount': 0,
              'likeCount': 0,
              'kinaCount': 0,
              'isSaved': false,
              'isLiked': false,
            },
          };
          
          print('🔵 Haykır post data hazırlandı: $postId');
          final result = await davaProvider.addHomeFeedPost(haykirPostData);
          
          if (result) {
            print('✅ Haykırış seyir defterine başarıyla eklendi: $postId');
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Haykırış seyir defterine eklendi!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          } else {
            print('⚠️ Haykırış seyir defterine eklenemedi (result: false)');
            // Direkt HiveDatabaseService'e eklemeyi dene
            try {
              HiveDatabaseService.addHomeFeedPost(haykirPostData, userEmail: widget.userEmail);
              print('✅ Haykırış direkt HiveDatabaseService ile seyir defterine eklendi');
            } catch (e2) {
              print('❌ Direkt ekleme de başarısız: $e2');
            }
          }
        } catch (e, stackTrace) {
          print('❌ Haykırış seyir defterine eklenirken hata: $e');
          print('Stack trace: $stackTrace');
          
          // Hata durumunda direkt HiveDatabaseService'e eklemeyi dene
          try {
            final postId = 'haykir_$haykirId';
            final nowIso = DateTime.now().toIso8601String();
            final haykirPostData = {
              'id': postId,
              'type': 'haykir',
              'createdAt': nowIso,
              'authorEmail': widget.userEmail,
              'payload': {
                'haykirId': haykirId,
                'adi': cleanHaykirData['adi'] ?? '',
                'slogan': cleanHaykirData['slogan'] ?? '',
                'direme': cleanHaykirData['direme'] ?? '',
                'detaylar': cleanHaykirData['detaylar'] ?? '',
                'createdAt': cleanHaykirData['createdAt'] ?? nowIso,
                'shareCount': 0,
                'commentCount': 0,
                'retweetCount': 0,
                'likeCount': 0,
                'kinaCount': 0,
                'isSaved': false,
                'isLiked': false,
              },
            };
            HiveDatabaseService.addHomeFeedPost(haykirPostData, userEmail: widget.userEmail);
            print('✅ Haykırış direkt HiveDatabaseService ile seyir defterine eklendi (fallback)');
          } catch (e2) {
            print('❌ Fallback ekleme de başarısız: $e2');
          }
        }
      } else {
        print('⚠️ userEmail boş, seyir defterine eklenemedi');
      }
      
      // Formu temizle
      _adiController.clear();
      _sloganController.clear();
      _detayController.clear();
      _ozelDiremController.clear();
      _selectedDireme = null;
      
      setState(() {
        showCreateForm = false;
      });
      
      // Başarı mesajı göster
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Haykırış başarıyla oluşturuldu!'),
            backgroundColor: Colors.green,
          ),
        );
      }
      
      // Listeyi yenile
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Dinamik kategorileri getir (özel direnler ve üyelerden direnleri dahil)
  List<DiremCategory> _getAllCategories() {
    final categories = List<DiremCategory>.from(DiremData.categories);
    
    // Üyelerden kategorisindeki direnleri yükle
    final uyelerdenDiremler = HiveDatabaseService.getUyelerdenDiremler();
    final uyelerdenIndex = categories.indexWhere((cat) => cat.name == 'Üyelerden');
    if (uyelerdenIndex != -1) {
      // Mevcut Üyelerden kategorisini güncelle
      final existingDiremler = categories[uyelerdenIndex].diremler;
      final allUyelerdenDiremler = <String>[...existingDiremler, ...uyelerdenDiremler];
      // Tekrarları kaldır
      final uniqueDiremler = allUyelerdenDiremler.toSet().toList();
      categories[uyelerdenIndex] = DiremCategory(
        name: 'Üyelerden',
        icon: '👥',
        color: Color(0xFF10B981), // Yeşil
        diremler: uniqueDiremler,
      );
    }
    
    // Özel direnleri "Başka bir diren" kategorisine ekle
    final ozelDiremler = HiveDatabaseService.getOzelDiremler();
    if (ozelDiremler.isNotEmpty) {
      // "Başka bir diren" kategorisini bul veya oluştur
      final baskaBirDiremIndex = categories.indexWhere((cat) => cat.name == 'Başka bir diren');
      if (baskaBirDiremIndex != -1) {
        // Mevcut kategoriyi güncelle
        categories[baskaBirDiremIndex] = DiremCategory(
          name: 'Başka bir diren',
          icon: '✨',
          color: Color(0xFF9B59B6), // Mor
          diremler: ozelDiremler,
        );
      } else {
        // Yeni kategori ekle
        categories.add(DiremCategory(
          name: 'Başka bir diren',
          icon: '✨',
          color: Color(0xFF9B59B6), // Mor
          diremler: ozelDiremler,
        ));
      }
    }
    
    return categories;
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Dinamik kategorileri yükle
    final allCategories = _getAllCategories();

    // Veritabanından haykırışları çek
    final haykirDataList = HiveDatabaseService.getAllActiveHaykirislar();
    final List<Haykir> haykirList = haykirDataList.map((data) {
      return Haykir(
        adi: data['adi']?.toString() ?? 'Haykırış',
        slogan: data['slogan']?.toString() ?? 'Slogan',
        direme: data['direme']?.toString() ?? 'Direme',
        kalanSure: _calculateRemainingTime(data['createdAt']?.toString()),
        profilResmi: "lib/icons/03_davala_ana_icon.png",
      );
    }).toList();
    
    // Haykırış detaylarını saklamak için bir map (boolean değerleri String'e dönüştür)
    final Map<int, Map<String, dynamic>> haykirDetailsMap = {};
    for (int i = 0; i < haykirDataList.length; i++) {
      final originalData = haykirDataList[i];
      final cleanData = <String, dynamic>{};
      
      // Tüm değerleri güvenli şekilde kopyala ve boolean değerleri String'e dönüştür
      originalData.forEach((key, value) {
        if (value is bool) {
          cleanData[key] = value.toString();
        } else {
          cleanData[key] = value;
        }
      });
      
      haykirDetailsMap[i] = cleanData;
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                  OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                  SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                    userEmail: widget.userEmail,
                    onShowSavedDavalar: () {
                      // Global utility fonksiyonunu kullan
                      if (widget.userEmail != null) {
                        showSavedDavalarDialog(context, widget.userEmail!);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Tab Section
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 53.0, vertical: 8.0),
              child: Row(
                children: [
                  // Menü ikonu - tıklanabilir
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'HAYKIR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content Section
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Icons (Gösterilme durumu kontrol ediliyor)
                    if (showLeftIcons || !isSmallScreen) ...[
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: showLeftIcons ? 60 : 0,
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              IconButton(
                                icon: Icon(Icons.campaign, size: 24, color: Colors.black54),
                                onPressed: () {
                                  setState(() {
                                    showCreateForm = !showCreateForm;
                                  });
                                },
                              ),
                              const SizedBox(height: 76),
                              Image.asset('lib/icons/06_left_row_ahizelitelefon_icon.png', width: 24, height: 24),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],

                    // Cards Section
                    Expanded(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Yeni Haykırış Oluşturma Formu
                            if (showCreateForm)
                              Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Form Başlığı
                                      Row(
                                        children: [
                                          Icon(Icons.add_circle, color: Colors.orange.shade700, size: 28),
                                          const SizedBox(width: 12),
                                          const Text(
                                            'Yeni Haykırış Oluştur',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close),
                                            onPressed: () {
                                              setState(() => showCreateForm = false);
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Haykırış Adı + Slogan + Seçilen Diren — tek bütün
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.orange.shade200,
                                            width: 1.5,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            TextField(
                                              controller: _adiController,
                                              decoration: InputDecoration(
                                                labelText: 'Haykırış Adı',
                                                hintText: 'Haykırışınızın adını girin',
                                                prefixIcon: const Icon(Icons.campaign),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              onChanged: (_) => setState(() {}),
                                            ),
                                            const SizedBox(height: 19),
                                            TextField(
                                              controller: _sloganController,
                                              decoration: InputDecoration(
                                                labelText: 'Slogan',
                                                hintText: 'Sloganınızı girin',
                                                prefixIcon: const Icon(Icons.format_quote),
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(12),
                                                ),
                                                filled: true,
                                                fillColor: Colors.white,
                                              ),
                                              maxLines: 2,
                                              onChanged: (_) => setState(() {}),
                                            ),
                                            Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    const Expanded(child: Divider(height: 24, thickness: 1)),Text(
                                                      'Seçilen Diren:',
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.orange.shade700,
                                                      ),
                                                    ),
                                                    Padding(
                                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                                      child: Transform.rotate(
                                                        angle: 120 * (3.141592653589793 / 180), // 45 derecenin radyan karşılığı
                                                        child: Icon(
                                                          Icons.flashlight_on_outlined,
                                                          color: Colors.orangeAccent,
                                                          size: 19,
                                                        ),
                                                      ),
                                                    ),
                                                    const Expanded(child: Divider(height: 24, thickness: 1)),
                                                  ],
                                                ),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.local_fire_department,
                                                      color: Colors.orangeAccent,
                                                      size: 40,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            _selectedDireme ?? (_ozelDiremController.text.trim().isNotEmpty
                                                                ? _ozelDiremController.text.trim()
                                                                : 'Henüz direm seçilmedi'),
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w500,
                                                              color: (_selectedDireme != null || _ozelDiremController.text.trim().isNotEmpty)
                                                                  ? Colors.black87
                                                                  : Colors.grey,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 16),
                                      // DİREN Bölümü
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Colors.green.shade200,
                                            style: BorderStyle.solid,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'DİREN',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black87,
                                              ),
                                            ),
                                            const SizedBox(height: 12),

                                            // Kategori Sekmeleri
                                            SizedBox(
                                              height: 50,
                                              child: ListView.separated(
                                                scrollDirection: Axis.horizontal,
                                                itemCount: allCategories.length,
                                                separatorBuilder: (context, index) => VerticalDivider(
                                                  width: 16,
                                                  thickness: 1,
                                                  color: Colors.grey.shade400,
                                                ),
                                                itemBuilder: (context, index) {
                                                  final category = allCategories[index];
                                                  final isSelected = _selectedCategoryIndex == index;
                                                  return FilterChip(
                                                    label: Row(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Text(category.icon),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          category.name,
                                                          style: TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    selected: isSelected,
                                                    onSelected: (selected) {
                                                      setState(() {
                                                        if (selected) {
                                                          _selectedCategoryIndex = index;
                                                          _selectedDireme = null;
                                                        }
                                                      });
                                                    },
                                                    selectedColor: category.color.withOpacity(0.3),
                                                    checkmarkColor: category.color,
                                                    backgroundColor: Colors.white,
                                                    side: BorderSide(
                                                      color: isSelected ? category.color : Colors.grey.shade300,
                                                      width: isSelected ? 2 : 1,
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),

                                            const Divider(height: 24),

                                            // Seçili Kategorinin Diremleri
                                            Container(
                                              constraints: const BoxConstraints(maxHeight: 200),
                                              child: SingleChildScrollView(
                                                child: Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: allCategories[_selectedCategoryIndex].diremler.map((option) {
                                                    final isSelected = _selectedDireme == option;
                                                    final category = allCategories[_selectedCategoryIndex];
                                                    return FilterChip(
                                                      label: Text(option),
                                                      selected: isSelected,
                                                      onSelected: (selected) {
                                                        setState(() {
                                                          if (selected) {
                                                            _selectedDireme = option;
                                                            _ozelDiremController.clear();
                                                          } else {
                                                            _selectedDireme = null;
                                                          }
                                                        });
                                                      },
                                                      selectedColor: category.color.withOpacity(0.3),
                                                      checkmarkColor: category.color,
                                                      backgroundColor: Colors.white,
                                                      side: BorderSide(
                                                        color: isSelected ? category.color : Colors.grey.shade300,
                                                        width: isSelected ? 2 : 1,
                                                      ),
                                                    );
                                                  }).toList(),
                                                ),
                                              ),
                                            ),

                                            const Divider(height: 24),

                                            // Özel Direm Oluşturma Alanı
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(8),
                                                border: Border.all(
                                                  color: Colors.green.shade300,
                                                  style: BorderStyle.solid,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: Row(
                                                children: [
                                                  Expanded(
                                                    child: TextField(
                                                      controller: _ozelDiremController,
                                                      maxLength: 19,
                                                      decoration: InputDecoration(
                                                        hintText: 'Başka Bir Direniş Yaz ',
                                                        border: InputBorder.none,
                                                        isDense: true,
                                                        counterText: '${_ozelDiremController.text.length}/19',
                                                        counterStyle: TextStyle(
                                                          fontSize: 10,
                                                          color: _ozelDiremController.text.length > 19
                                                            ? Colors.red
                                                            : Colors.grey,
                                                        ),
                                                      ),
                                                      onChanged: (value) {
                                                        setState(() {
                                                          if (value.trim().isNotEmpty) {
                                                            _selectedDireme = null;
                                                          }
                                                        });
                                                      },
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  ElevatedButton(
                                                    onPressed: () async {
                                                      final diremText = _ozelDiremController.text.trim();
                                                      if (diremText.isNotEmpty) {
                                                        if (diremText.length > 19) {
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              const SnackBar(
                                                                content: Text('❌ Direm maksimum 19 karakter olmalıdır!'),
                                                                backgroundColor: Colors.red,
                                                              ),
                                                            );
                                                          }
                                                          return;
                                                        }

                                                        try {
                                                          await HiveDatabaseService.addUyelerdenDirem(diremText);

                                                          setState(() {
                                                            _selectedDireme = null;
                                                          });

                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('✅ "$diremText" Üyelerden kategorisine eklendi!'),
                                                                backgroundColor: Colors.green,
                                                              ),
                                                            );
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text('❌ Hata: $e'),
                                                                backgroundColor: Colors.red,
                                                              ),
                                                            );
                                                          }
                                                        }
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green.shade700,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(0, 40),
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(8),
                                                      ),
                                                    ),
                                                    child: const Text('OK'),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      
                                      const SizedBox(height: 16),

                                      // Detaylar: En az 19, en fazla 361 karakter
                                      TextField(
                                        controller: _detayController,
                                        decoration: InputDecoration(
                                          labelText: 'Haykır Detayı (Zorunlu)',
                                          hintText: 'En az 19, en fazla 361 karakter',
                                          prefixIcon: const Icon(Icons.description),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          filled: true,
                                          fillColor: Colors.white,
                                          helperText: '${_detayController.text.length}/361 karakter',
                                          errorText: _detayController.text.trim().isNotEmpty && 
                                                     (_detayController.text.trim().length < 19 || 
                                                      _detayController.text.trim().length > 361)
                                              ? (_detayController.text.trim().length < 19 
                                                  ? 'Detay en az 19 karakter olmalıdır' 
                                                  : 'Detay en fazla 361 karakter olabilir')
                                              : null,
                                        ),
                                        maxLines: 6,
                                        maxLength: 361, // ✅ En fazla 361 karakter
                                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '$currentLength/$maxLength karakter',
                                              style: TextStyle(
                                                color: currentLength < 19 
                                                    ? Colors.red 
                                                    : (currentLength > 361 ? Colors.red : Colors.grey),
                                                fontSize: 12,
                                              ),
                                            ),
                                          );
                                        },
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 20),
                                      
                                      // Butonlar
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () {
                                                setState(() => showCreateForm = false);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text('İPTAL'),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            flex: 2,
                                            child: ElevatedButton.icon(
                                              onPressed: _canHaykir
                                                  ? () {
                                                      // ✅ Tüm değerleri String olarak garanti et
                                                      final haykirData = {
                                                        'adi': _adiController.text.trim(),
                                                        'slogan': _sloganController.text.trim(),
                                                        'direme': (_selectedDireme ?? _ozelDiremController.text.trim()).toString(),
                                                        'detaylar': _detayController.text.trim(),
                                                      };
                                                      _publishHaykir(haykirData);
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.campaign, size: 20),
                                              label: const Text('HAYKIR'),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange.shade600,
                                                foregroundColor: Colors.white,
                                                minimumSize: const Size(0, 48),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            
                            // Mevcut Haykırışlar Listesi
                            ...haykirList.asMap().entries.map((entry) {
                              final index = entry.key;
                              final haykir = entry.value;
                              final haykirData = haykirDetailsMap[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: FiveCardCaseInformation(
                                  haykir: haykir,
                                  haykirData: haykirData,
                                  isExpanded: expandedCardIndex == index,
                                  userEmail: widget.userEmail,
                                  onTap: () {
                                    setState(() {
                                      if (expandedCardIndex == index) {
                                        expandedCardIndex = null;
                                      } else {
                                        expandedCardIndex = index;
                                      }
                                    });
                                  },
                                  onClose: haykirData != null &&
                                          haykirData['id'] != null &&
                                          widget.userEmail != null &&
                                          haykirData['userEmail']?.toString() == widget.userEmail
                                      ? () async {
                                          final haykirId = haykirData['id'].toString();
                                          try {
                                            await HiveDatabaseService.deleteHaykir(haykirId);

                                            if (widget.userEmail != null) {
                                              final davaProvider = Provider.of<DavaProvider>(
                                                context,
                                                listen: false,
                                              );
                                              await davaProvider.refreshAll();
                                            }

                                            if (mounted) {
                                              setState(() {});
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    '✅ Haykırış silindi ve seyir defterinden kaldırıldı.',
                                                  ),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('❌ Hata: $e'),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        }
                                      : null,
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
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
}

class FiveCardCaseInformation extends StatefulWidget {
  final Haykir haykir;
  final Map<String, dynamic>? haykirData;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onClose;
  final String? userEmail; // ✅ Kullanıcı email'i

  const FiveCardCaseInformation({
    super.key,
    required this.haykir,
    this.haykirData,
    required this.isExpanded,
    this.onTap,
    this.onClose,
    this.userEmail,
  });

  @override
  State<FiveCardCaseInformation> createState() => _FiveCardCaseInformationState();
}

class _FiveCardCaseInformationState extends State<FiveCardCaseInformation> with TickerProviderStateMixin {
  // Sosyal medya etkileşim sayacları
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int kinaCount = 0;
  bool isSaved = false;
  bool isLiked = false;
  bool isKina = false; // ✅ Kına durumu
  bool isRetweeted = false; // ✅ Retweet durumu
  bool showComments = false; // ✅ Yorumları göster/gizle
  final TextEditingController _commentController = TextEditingController(); // ✅ Yorum yazma controller
  List<Map<String, dynamic>> _comments = []; // ✅ Yorumlar listesi
  bool showSocialIcons = false; // ✅ Sosyal ikonlar başlangıçta gizli
  bool isHaykirPressed = false; // ✅ HAYKIR butonuna basıldı mı?
  bool showSuccessAnimation = false; // ✅ Başarı animasyonu göster
  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Animation<double>? _fadeAnimation;
  
  // ✅ Kına shake animasyonu için
  AnimationController? _shakeController;
  Animation<double>? _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.elasticOut),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeIn),
    );
    
    // ✅ Kına shake animasyonu (tokat efekti için)
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    // ✅ Daha gerçekçi shake efekti için TweenSequence kullan
    _shakeAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.15, end: -0.12), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.12, end: 0.08), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: 0.08, end: -0.05), weight: 1),
      TweenSequenceItem(tween: Tween<double>(begin: -0.05, end: 0.0), weight: 1),
    ]).animate(
      CurvedAnimation(
        parent: _shakeController!,
        curve: Curves.easeInOut,
      ),
    );
    
    // ✅ Adım 4: Etkileşim istatistiklerini veritabanından yükle
    _initPublishedState();
    _loadInteractionStats();
  }

  void _initPublishedState() {
    final publishedFlag = widget.haykirData?['isPublishedOnCard'];
    final isPublished = publishedFlag is bool
        ? publishedFlag
        : publishedFlag?.toString().toLowerCase() == 'true';
    if (isPublished) {
      isHaykirPressed = true;
      showSocialIcons = true;
      showSuccessAnimation = true;
      _animationController?.value = 1.0;
    }
  }
  
  // ✅ Etkileşim istatistiklerini veritabanından yükle
  void _loadInteractionStats() {
    if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
    
    final haykirId = widget.haykirData!['id'].toString();
    final stats = HiveDatabaseService.getHaykirInteractionStats(
      haykirId,
      userEmail: widget.userEmail,
    );
    
    setState(() {
      commentCount = stats['commentCount'] as int? ?? 0;
      retweetCount = stats['retweetCount'] as int? ?? 0;
      likeCount = stats['likeCount'] as int? ?? 0;
      kinaCount = stats['kinaCount'] as int? ?? 0;
      isLiked = stats['isLiked'] as bool? ?? false;
      isSaved = stats['isSaved'] as bool? ?? false;
      isKina = stats['isKina'] as bool? ?? false; // ✅ Kına durumu
      isRetweeted = stats['isRetweeted'] as bool? ?? false; // ✅ Retweet durumu
    });
    
    // ✅ Yorumları yükle
    if (widget.haykirData != null && widget.haykirData!['id'] != null) {
      final haykirId = widget.haykirData!['id'].toString();
      _comments = HiveDatabaseService.getHaykirComments(haykirId);
      setState(() {});
    }
  }
  
  // ✅ Retweet'in devre dışı olup olmadığını kontrol et
  bool _isRetweetDisabled() {
    if (widget.haykirData == null || widget.haykirData!['id'] == null) return false;
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return false;
    
    final haykirId = widget.haykirData!['id'].toString();
    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    if (haykirData == null) return false;
    
    final retweetDisabledUsers = List<String>.from(haykirData['retweetDisabledUsers'] ?? []);
    return retweetDisabledUsers.contains(widget.userEmail!);
  }
  
  // ✅ Retweet'in kalıcı olup olmadığını kontrol et (Grup-19 ile yapılmışsa geri alınamaz)
  bool _isRetweetPermanent() {
    if (widget.haykirData == null || widget.haykirData!['id'] == null) return false;
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return false;
    
    final haykirId = widget.haykirData!['id'].toString();
    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    if (haykirData == null) return false;
    
    final grup19Retweets = List<String>.from(haykirData['grup19Retweets'] ?? []);
    return grup19Retweets.contains(widget.userEmail!);
  }
  
  @override
  void dispose() {
    _animationController?.dispose();
    _shakeController?.dispose();
    _commentController.dispose(); // ✅ Yorum controller'ı dispose et
    super.dispose();
  }

  /// Haykır başlangıç tarihini formatla (DD/MM/YYYY)
  String _formatHaykirBaslangicTarihi() {
    if (widget.haykirData == null) return 'Haykır açıldığı tarih';
    
    try {
      final createdAt = widget.haykirData!['createdAt']?.toString();
      if (createdAt == null || createdAt.isEmpty) return 'Haykır açıldığı tarih';
      
      final date = DateTime.tryParse(createdAt);
      if (date == null) return 'Haykır açıldığı tarih';
      
      // DD/MM/YYYY formatına çevir
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      
      return '$day/$month/$year';
    } catch (e) {
      return 'Haykır açıldığı tarih';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ✅ Close butonu ve HAYKIR butonu
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Close butonu — yalnızca henüz yayınlanmamış haykırlarda
                  if (widget.onClose != null && !isHaykirPressed)
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.red),
                      onPressed: widget.onClose,
                      tooltip: 'Haykırışı sil',
                    )
                  else
                    const SizedBox.shrink(),
                  const Spacer(),
                  // HAYKIR butonu
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    child: ElevatedButton.icon(
                      onPressed: isHaykirPressed
                          ? null // ✅ Basıldıktan sonra inaktif
                          : () async {
                              setState(() {
                                showSocialIcons = true;
                                isHaykirPressed = true;
                                showSuccessAnimation = true;
                              });
                              _animationController?.forward();

                              if (widget.haykirData?['id'] != null) {
                                try {
                                  await HiveDatabaseService.updateHaykir(
                                    widget.haykirData!['id'].toString(),
                                    {'isPublishedOnCard': 'true'},
                                  );
                                } catch (e) {
                                  print('⚠️ Haykır yayın durumu kaydedilemedi: $e');
                                }
                              }

                              // Başarı mesajı göster
                              Future.delayed(const Duration(milliseconds: 500), () {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.celebration, color: Colors.white),
                                          const SizedBox(width: 8),
                                          const Text('🎉 Haykırışınız yayınlandı!'),
                                        ],
                                      ),
                                      duration: const Duration(seconds: 2),
                                      backgroundColor: Colors.green,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                }
                              });
                            },
                      icon: Icon(
                        isHaykirPressed ? Icons.check_circle : Icons.campaign,
                        size: 19,
                      ),
                      label: Text(
                        isHaykirPressed ? 'YAYINLANDI' : 'HAYKIR',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isHaykirPressed ? Colors.green.shade700 : Colors.orange.shade600,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 40),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: isHaykirPressed ? 2 : 4,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // ✅ Haykırış Bilgileri
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.campaign, size: 30, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.haykir.adi,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(MdiIcons.formatQuoteOpen, size: 30, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.haykir.slogan,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black,
                              fontStyle: FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(MdiIcons.flag, size: 30, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.haykir.direme,
                            style: const TextStyle(
                              fontSize: 19,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(MdiIcons.timerAlertOutline, size: 25, color: Colors.orange),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'KalanSure: ${widget.haykir.kalanSure}, ::: ${_formatHaykirBaslangicTarihi()}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // ✅ Başarı Animasyonu ve Partikül Efektleri
              if (showSuccessAnimation && _fadeAnimation != null && _scaleAnimation != null)
                FadeTransition(
                  opacity: _fadeAnimation!,
                  child: ScaleTransition(
                    scale: _scaleAnimation!,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.orange.shade100, Colors.yellow.shade100],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.shade300, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.orange.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.celebration, color: Colors.orange, size: 28),
                          const SizedBox(width: 8),
                          const Text(
                            ' Haykırışınız Aktif! ',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(Icons.celebration, color: Colors.orange, size: 28),
                        ],
                      ),
                    ),
                  ),
                ),
              
              // ✅ Sosyal Medya İkonları (sadece showSocialIcons true ise göster)
              if (showSocialIcons && _fadeAnimation != null && _scaleAnimation != null)
                FadeTransition(
                  opacity: _fadeAnimation!,
                  child: ScaleTransition(
                    scale: _scaleAnimation!,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.purple.shade50, Colors.blue.shade50],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.shade200, width: 2),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.purple.withOpacity(0.2),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Başlık
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(MdiIcons.chartLine, color: Colors.purple.shade700, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'ETKİLEŞİM İSTATİSTİKLERİ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade700,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // İkonlar
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              // Yorum - ✅ Yorum yazma dialogu aç
                              _buildSocialIconButton(
                                icon: MdiIcons.commentOutline,
                                label: 'Yorum',
                                count: commentCount,
                                color: Colors.green,
                                isActive: showComments,
                                onTap: () {
                                  setState(() {
                                    showComments = !showComments;
                                  });
                                  if (showComments && widget.haykirData != null && widget.haykirData!['id'] != null) {
                                    final haykirId = widget.haykirData!['id'].toString();
                                    _comments = HiveDatabaseService.getHaykirComments(haykirId);
                                  }
                                },
                              ),
                              
                              // Retweet - ✅ İlk retweet'te dialog aç, sonra sadece geri al/tekrar yap (Grup-19 ile yapılmışsa geri alınamaz)
                              _buildSocialIconButton(
                                icon: MdiIcons.repeat,
                                label: 'Retweet',
                                count: retweetCount,
                                color: Colors.orange,
                                isActive: isRetweeted,
                                isDisabled: _isRetweetDisabled() || _isRetweetPermanent(),
                                onTap: (_isRetweetDisabled() || _isRetweetPermanent())
                                    ? null 
                                    : () {
                                        // Eğer daha önce retweet yapılmışsa
                                        if (isRetweeted) {
                                          // Grup-19 ile yapılmışsa geri alınamaz
                                          if (_isRetweetPermanent()) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('⚠️ Grup-19 ile yapılan retweet geri alınamaz!'),
                                                duration: Duration(seconds: 3),
                                                backgroundColor: Colors.orange,
                                              ),
                                            );
                                            return;
                                          }
                                          // Sadece ben ile yapılmışsa geri al
                                          _undoRetweet();
                                        } else {
                                          // İlk retweet: Dialog aç
                                          _showHaykirGroupSelectionDialog();
                                        }
                                      },
                              ),
                              
                              // Beğen
                              _buildSocialIconButton(
                                icon: isLiked ? MdiIcons.heart : MdiIcons.heartOutline,
                                label: 'Beğen',
                                count: likeCount,
                                color: Colors.red,
                                isActive: isLiked,
                                onTap: () async {
                                  if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
                                  final haykirId = widget.haykirData!['id'].toString();
                                  final newIsLiked = !isLiked;
                                  
                                  // ✅ Kına yapılmışsa kaldır
                                  if (newIsLiked && isKina) {
                                    await HiveDatabaseService.updateHaykirInteractionStats(
                                      haykirId: haykirId,
                                      userEmail: widget.userEmail ?? '',
                                      action: 'kina', // Kına'yı kaldır
                                    );
                                  }
                                  
                                  await HiveDatabaseService.updateHaykirInteractionStats(
                                    haykirId: haykirId,
                                    userEmail: widget.userEmail ?? '',
                                    isLiked: newIsLiked,
                                  );
                                  
                                  setState(() {
                                    isLiked = newIsLiked;
                                    if (newIsLiked) {
                                      likeCount++;
                                      isKina = false; // ✅ Kına'yı kaldır
                                    } else {
                                      likeCount = likeCount > 0 ? likeCount - 1 : 0;
                                    }
                                  });
                                },
                              ),
                              
                              // Kına - ✅ Beğen gibi stil, gri arka plan, beyaz icon
                              _buildSocialIconButton(
                                icon: MdiIcons.handWaveOutline,
                                label: 'Kına',
                                count: kinaCount,
                                color: Colors.grey, // ✅ Gri renk
                                isActive: isKina, // ✅ Aktif durumu
                                shakeAnimation: _shakeAnimation,
                                onTap: () async {
                                  if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
                                  final haykirId = widget.haykirData!['id'].toString();
                                  final newIsKina = !isKina;
                                  
                                  // ✅ Beğen yapılmışsa kaldır
                                  if (newIsKina && isLiked) {
                                    await HiveDatabaseService.updateHaykirInteractionStats(
                                      haykirId: haykirId,
                                      userEmail: widget.userEmail ?? '',
                                      isLiked: false, // Beğen'i kaldır
                                    );
                                  }
                                  
                                  await HiveDatabaseService.updateHaykirInteractionStats(
                                    haykirId: haykirId,
                                    userEmail: widget.userEmail ?? '',
                                    action: 'kina',
                                  );
                                  
                                  setState(() {
                                    isKina = newIsKina;
                                    if (newIsKina) {
                                      kinaCount++;
                                      isLiked = false; // ✅ Beğen'i kaldır
                                      likeCount = likeCount > 0 ? likeCount - 1 : 0;
                                    } else {
                                      kinaCount = kinaCount > 0 ? kinaCount - 1 : 0;
                                    }
                                  });
                                  
                                  // ✅ Shake animasyonunu başlat (tokat efekti)
                                  if (newIsKina) {
                                    _shakeController?.reset();
                                    _shakeController?.forward();
                                  }
                                  
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(newIsKina ? '👋 Kına gönderildi!' : '❌ Kına kaldırıldı!'),
                                        duration: const Duration(seconds: 1),
                                        backgroundColor: Colors.grey,
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                          
                          // ✅ Yorumlar bölümü
                          if (showComments) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.green.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Yorum yazma alanı
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _commentController,
                                          decoration: InputDecoration(
                                            hintText: 'Yorumunuzu yazın...',
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            filled: true,
                                            fillColor: Colors.grey[50],
                                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          ),
                                          maxLines: 2,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      IconButton(
                                        icon: const Icon(Icons.send, color: Colors.green),
                                        onPressed: () async {
                                          if (_commentController.text.trim().isEmpty) return;
                                          if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
                                          
                                          final haykirId = widget.haykirData!['id'].toString();
                                          
                                          final result = await HiveDatabaseService.addHaykirComment(
                                            haykirId: haykirId,
                                            userEmail: widget.userEmail ?? '',
                                            commentText: _commentController.text.trim(),
                                          );
                                          
                                          if (mounted) {
                                            if (result['success'] == true) {
                                              _commentController.clear();
                                              _loadInteractionStats(); // Yorumları yeniden yükle
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('✅ Yorum eklendi!'),
                                                  duration: Duration(seconds: 1),
                                                  backgroundColor: Colors.green,
                                                ),
                                              );
                                            } else {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(result['error']?.toString() ?? 'Yorum eklenemedi'),
                                                  duration: const Duration(seconds: 3),
                                                  backgroundColor: Colors.red,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  
                                  const SizedBox(height: 12),
                                  
                                  // Yorumlar listesi
                                  if (_comments.isEmpty)
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Center(
                                        child: Text(
                                          'Henüz yorum yok. İlk yorumu siz yapın!',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                        ),
                                      ),
                                    )
                                  else
                                    ..._comments.map((comment) {
                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: Colors.grey[200]!),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                CircleAvatar(
                                                  radius: 12,
                                                  backgroundColor: Colors.green.shade100,
                                                  child: Text(
                                                    (comment['userName']?.toString() ?? 'U').substring(0, 1).toUpperCase(),
                                                    style: TextStyle(
                                                      color: Colors.green.shade700,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: Text(
                                                    comment['userName']?.toString() ?? 'Bilinmeyen',
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.bold,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  _formatCommentTime(comment['createdAt']?.toString()),
                                                  style: TextStyle(
                                                    fontSize: 9,
                                                    color: Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            ExpandableCommentText(
                                              text: comment['commentText']?.toString() ?? '',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.black87,
                                              ),
                                              maxLines: 4,
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                                ],
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
        ),
      ),
    );
  }
  
  // ✅ Yorum zamanını formatla
  String _formatCommentTime(String? createdAt) {
    if (createdAt == null || createdAt.isEmpty) return '';
    try {
      final created = DateTime.parse(createdAt);
      final now = DateTime.now();
      final difference = now.difference(created);
      
      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return '';
    }
  }

  Widget _buildSocialIconButton({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    VoidCallback? onTap,
    bool isActive = false,
    bool isDisabled = false,
    Animation<double>? shakeAnimation,
  }) {
    // ✅ Kına için özel stil (gri arka plan, beyaz icon)
    final isKinaButton = label == 'Kına';
    final isDisabledOrNull = isDisabled || onTap == null;
    final iconColor = isKinaButton && isActive 
        ? Colors.white // ✅ Kına aktifken beyaz icon
        : (isDisabledOrNull ? Colors.grey[400] : (isActive ? color : Colors.grey[600]));
    final backgroundColor = isKinaButton && isActive
        ? Colors.grey[600] // ✅ Kına aktifken gri arka plan
        : (isDisabledOrNull ? Colors.grey[200] : (isActive ? color.withOpacity(0.2) : Colors.grey[100]));
    
    // ✅ Step-2: Widget ID oluştur (unique identifier)
    final widgetId = 'haykir_page_${label}_${icon.codePoint}';
    
    Widget iconWidget = Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: iconColor,
        size: isActive && isKinaButton ? 26 : 22, // ✅ Kına aktifken büyüt
      ),
    );
    
    // ✅ Shake animasyonu varsa uygula (tokat efekti)
    if (shakeAnimation != null) {
      iconWidget = AnimatedBuilder(
        animation: shakeAnimation,
        builder: (context, child) {
          return Transform.rotate(
            angle: shakeAnimation.value * 0.4, // ✅ Rotasyon açısı (tokat efekti için daha belirgin)
            child: Transform.translate(
              offset: Offset(shakeAnimation.value * 8, shakeAnimation.value.abs() * 2), // ✅ Yatay ve dikey titreşim
              child: child,
            ),
          );
        },
        child: iconWidget,
      );
    }
    
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isDisabledOrNull ? null : onTap,
          onLongPress: () {
            // ✅ Step-2: Uzun basınca widget'ı kaydet
            if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
              final isAlreadySaved = HiveDatabaseService.isWidgetSaved(
                userEmail: widget.userEmail!,
                widgetId: widgetId,
              );
              
              if (isAlreadySaved) {
                // Widget zaten kayıtlıysa sil
                HiveDatabaseService.deleteSavedWidget(
                  userEmail: widget.userEmail!,
                  widgetId: widgetId,
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('❌ "$label" kayıttan kaldırıldı'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.grey[700],
                  ),
                );
              } else {
                // Widget'ı kaydet
                HiveDatabaseService.saveWidget(
                  userEmail: widget.userEmail!,
                  widgetId: widgetId,
                  label: label,
                  iconCodePoint: icon.codePoint.toString(),
                  colorValue: color.value,
                  count: count,
                  isActive: isActive,
                  isDisabled: false,
                  sourcePage: 'haykir_page',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('✅ "$label" kaydedilenler arşivine eklendi'),
                    duration: const Duration(seconds: 2),
                    backgroundColor: Colors.purple,
                    action: SnackBarAction(
                      label: 'Görüntüle',
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SavedWidgetsPage(userEmail: widget.userEmail),
                          ),
                        );
                      },
                    ),
                  ),
                );
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('⚠️ Kaydetmek için giriş yapmalısınız'),
                  duration: Duration(seconds: 2),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: EdgeInsets.symmetric(
              vertical: isActive && isKinaButton ? 14 : 12, // ✅ Kına aktifken büyüt
              horizontal: 4,
            ),
            decoration: BoxDecoration(
              gradient: isActive && isKinaButton
                  ? LinearGradient(
                      colors: [Colors.grey[600]!, Colors.grey[700]!], // ✅ Kına için gri gradient
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : (isActive
                      ? LinearGradient(
                          colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive && isKinaButton 
                    ? Colors.grey[700]! // ✅ Kına aktifken gri border
                    : (isActive ? color : Colors.grey[300]!),
                width: isActive ? 2 : 1,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: isKinaButton 
                            ? Colors.grey.withOpacity(0.4) // ✅ Kına için gri shadow
                            : color.withOpacity(0.3),
                        blurRadius: isActive && isKinaButton ? 12 : 8, // ✅ Kına aktifken daha büyük shadow
                        spreadRadius: isActive && isKinaButton ? 2 : 1,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                iconWidget,
                const SizedBox(height: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: isActive && isKinaButton ? 11 : 10, // ✅ Kına aktifken büyüt
                    color: isActive && isKinaButton 
                        ? Colors.white // ✅ Kına aktifken beyaz text
                        : (isActive ? color : Colors.grey[600]),
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (count > 0) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count.toString(),
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ Haykır grup seçim dialog'unu göster
  void _showHaykirGroupSelectionDialog() {
    String? selectedOption;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.orange.withOpacity(0.1), Colors.red.withOpacity(0.05)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 24, color: Colors.orange[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'HAYKIR PAYLAŞ',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Radio butonlar - Sadece "Grup 19" ve "Sadece ben"
                    Column(
                      children: [
                        _buildRadioOption(
                          dialogContext,
                          'grup19',
                          'Grup 19',
                          'Grup19 olarak kaydettiğiniz 19 kişiye davet gönder',
                          Icons.group,
                          Colors.purple,
                          selectedOption,
                          (value) {
                            setDialogState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRadioOption(
                          dialogContext,
                          'sadece_ben',
                          'Sadece ben',
                          'Sadece kendi seyir defterinize yayınlamak için paylaş',
                          Icons.person,
                          Colors.blue,
                          selectedOption,
                          (value) {
                            setDialogState(() {
                              selectedOption = value;
                            });
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Butonlar
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'İPTAL',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: selectedOption != null 
                                ? () {
                                    Navigator.of(dialogContext).pop();
                                    _processHaykirRetweet(selectedOption!);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedOption != null ? Colors.orange : Colors.grey,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(0, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'DEVAM ET',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
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
      },
    );
  }

  // Radio seçenek widget'ı - Grup19 ve Sadece ben seçenekleri için
  Widget _buildRadioOption(
    BuildContext context,
    String value,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String? selectedOption,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: selectedOption == value ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedOption == value ? color : Colors.grey[300]!,
          width: selectedOption == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedOption,
        onChanged: onChanged,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedOption == value ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        activeColor: color,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  // ✅ Haykır retweet ve davet gönderme işlemini gerçekleştir
  Future<void> _processHaykirRetweet(String selectedOption) async {
    if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;
    
    final haykirId = widget.haykirData!['id'].toString();
    final haykirData = HiveDatabaseService.getHaykir(haykirId);
    if (haykirData == null) return;
    
    try {
      // ✅ Adım 1: Retweet istatistiğini güncelle
      await HiveDatabaseService.updateHaykirInteractionStats(
        haykirId: haykirId,
        userEmail: widget.userEmail!,
        action: 'retweet',
      );
      
      // ✅ Adım 2: Retweet basan kişinin seyir defterine haykır paylaşımı ekle (her zaman)
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final postId = 'haykir_retweet_${haykirId}_${DateTime.now().millisecondsSinceEpoch}';
        final haykirPostData = {
          'id': postId,
          'type': 'haykir',
          'createdAt': DateTime.now().toIso8601String(),
          'authorEmail': widget.userEmail,
          'payload': {
            'haykirId': haykirId,
            'adi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt': haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'isRetweet': true,
            'shareCount': 0,
            'commentCount': 0,
            'retweetCount': 0,
            'likeCount': 0,
            'kinaCount': 0,
            'isSaved': false,
            'isLiked': false,
          },
        };
        await davaProvider.addHomeFeedPost(haykirPostData);
      } catch (e) {
        print('⚠️ Retweet seyir defterine eklenirken hata: $e');
      }
      
      // ✅ Adım 3: Seçeneğe göre işlem yap
      if (selectedOption == 'grup19') {
        // ✅ Grup 19 seçildi: Grup19 olarak kaydedilen kişilere davet gönder (davet gönderen kişi de dahil)
        final invitationRecipients = await HiveDatabaseService.pickInvitationRecipients(
          widget.userEmail!,
          'Grup19',
          excludedEmails: [], // ✅ Davet gönderen kişi de davet alır
        );
        
        // ✅ Kendine de davet gönder (Grup19 listesinde olmasa bile)
        final currentUserInvitation = {
          'id': 'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_${widget.userEmail}',
          'haykirId': haykirId,
          'davaId': haykirId,
          'haykirAdi': haykirData['adi'] ?? '',
          'slogan': haykirData['slogan'] ?? '',
          'direme': haykirData['direme'] ?? '',
          'detaylar': haykirData['detaylar'] ?? '',
          'createdAt': haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
          'groupName': 'Grup19',
          'invitedAt': DateTime.now().toIso8601String(),
          'isRead': false,
          'userEmail': widget.userEmail!,
          'displayName': widget.userEmail!,
          'type': 'haykir',
          'davaAdi': haykirData['adi'] ?? '',
          'davaKategori': 'Haykır',
          'davaKonusu': haykirData['slogan'] ?? '',
          'davaci': widget.userEmail!,
          'davali': '',
          'isOpened': false,
          'yorumSayisi': 0,
          'retweetSayisi': 0,
          'begeniSayisi': 0,
          'begenmemeSayisi': 0,
          'userLiked': false,
          'userDisliked': false,
          'userRetweeted': false,
          'yorumlar': <Map<String, dynamic>>[],
        };
        HiveDatabaseService.addInvitation(widget.userEmail!, currentUserInvitation);
        print('✅ Kendine davet gönderildi: ${widget.userEmail}');

        // ✅ Haykır başlatan kişiyi bul (authorEmail veya userEmail)
        final authorEmail = haykirData['userEmail']?.toString() ?? '';
        
        // ✅ Haykır başlatan kişi varsa ve davet gönderen kişiden farklıysa, ona da davet gönder
        // ✅ NOT: Haykır başlatan kişi Grup19 listesinde olsa bile ona ayrıca davet gönderilir
        bool authorAlreadyInList = false;
        if (authorEmail.isNotEmpty && authorEmail != widget.userEmail) {
          // Haykır başlatan kişi zaten Grup19 listesinde mi kontrol et (sadece bilgi için)
          authorAlreadyInList = invitationRecipients.any((r) => r.email == authorEmail);
          
          // ✅ Haykır başlatan kişiye her zaman davet gönder (Grup19 listesinde olsa bile)
          final authorInvitation = {
            'id': 'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_$authorEmail',
            'haykirId': haykirId,
            'davaId': haykirId, // ✅ addInvitation fonksiyonu için gerekli
            'haykirAdi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt': haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'groupName': 'Grup19',
            'invitedAt': DateTime.now().toIso8601String(),
            'isRead': false,
            'userEmail': authorEmail,
            'displayName': authorEmail,
            // ✅ Davet sayfasında gösterilecek format
            'type': 'haykir',
            'davaAdi': haykirData['adi'] ?? '',
            'davaKategori': 'Haykır',
            'davaKonusu': haykirData['slogan'] ?? '',
            'davaci': widget.userEmail!,
            'davali': '',
            'isOpened': false,
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'userRetweeted': false,
            'yorumlar': <Map<String, dynamic>>[],
          };
          
          // ✅ Haykır başlatan kişiye davet gönder
          HiveDatabaseService.addInvitation(authorEmail, authorInvitation);
          print('✅ Haykır başlatan kişiye davet gönderildi: $authorEmail (Grup19 listesinde: $authorAlreadyInList)');
        }

        // ✅ Haykır davetlerini kaydet (davet gönderen kişi dahil)
        for (final recipient in invitationRecipients) {
          final haykirInvitation = {
            'id': 'haykir_invitation_${DateTime.now().millisecondsSinceEpoch}_${recipient.email}',
            'haykirId': haykirId,
            'davaId': haykirId, // ✅ addInvitation fonksiyonu için gerekli
            'haykirAdi': haykirData['adi'] ?? '',
            'slogan': haykirData['slogan'] ?? '',
            'direme': haykirData['direme'] ?? '',
            'detaylar': haykirData['detaylar'] ?? '',
            'createdAt': haykirData['createdAt'] ?? DateTime.now().toIso8601String(),
            'groupName': 'Grup19',
            'invitedAt': DateTime.now().toIso8601String(),
            'isRead': false,
            'userEmail': recipient.email,
            'displayName': recipient.judgeName.isNotEmpty ? recipient.judgeName : recipient.email,
            // ✅ Davet sayfasında gösterilecek format
            'type': 'haykir',
            'davaAdi': haykirData['adi'] ?? '',
            'davaKategori': 'Haykır',
            'davaKonusu': haykirData['slogan'] ?? '',
            'davaci': widget.userEmail!,
            'davali': '',
            'isOpened': false,
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'userRetweeted': false,
            'yorumlar': <Map<String, dynamic>>[],
          };
          
          // ✅ Haykır davetini kaydet (invitation sistemi kullanarak)
          HiveDatabaseService.addInvitation(recipient.email, haykirInvitation);
        }

        final totalInvitations = invitationRecipients.length + (authorEmail.isNotEmpty && authorEmail != widget.userEmail && !authorAlreadyInList ? 1 : 0);
        print('✅ Haykır retweet: Grup19 için ${invitationRecipients.length} kişiye + haykır başlatan kişiye davet gönderildi (Toplam: $totalInvitations)');

        // ✅ Grup-19 ile retweet yapıldığında kalıcı hale getir (geri alınamaz)
        try {
          final grup19Retweets = List<String>.from(haykirData['grup19Retweets'] ?? []);
          if (!grup19Retweets.contains(widget.userEmail!)) {
            grup19Retweets.add(widget.userEmail!);
            haykirData['grup19Retweets'] = grup19Retweets;
            await HiveDatabaseService.updateHaykir(haykirId, haykirData);
            print('✅ Grup-19 retweet kalıcı olarak işaretlendi: ${widget.userEmail}');
          }
        } catch (e) {
          print('⚠️ Grup-19 retweet kalıcı işaretleme hatası: $e');
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Grup19\'a gönderildi! $totalInvitations kişiye davet gönderildi (Grup19 + haykır başlatan kişi). Bu retweet geri alınamaz.'),
              duration: const Duration(seconds: 4),
              backgroundColor: Colors.orange,
            ),
          );
        }
      } else if (selectedOption == 'sadece_ben') {
        // ✅ Sadece ben seçildi: Sadece kendi seyir defterine kaydet (zaten yukarıda yapıldı)
        // ✅ Bu kullanıcı için retweet'i devre dışı bırak
        try {
          // Haykır verisinde retweetDisabledUsers listesini güncelle
          final retweetDisabledUsers = List<String>.from(haykirData['retweetDisabledUsers'] ?? []);
          if (!retweetDisabledUsers.contains(widget.userEmail!)) {
            retweetDisabledUsers.add(widget.userEmail!);
            haykirData['retweetDisabledUsers'] = retweetDisabledUsers;
            await HiveDatabaseService.updateHaykir(haykirId, haykirData);
            print('✅ Retweet devre dışı bırakıldı: ${widget.userEmail}');
          }
        } catch (e) {
          print('⚠️ Retweet devre dışı bırakma hatası: $e');
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Seyir defterinize eklendi! Artık retweet yapamazsınız.'),
              duration: Duration(seconds: 3),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
      
      // ✅ Adım 4: Retweet sayısını ve durumunu güncelle
      setState(() {
        retweetCount++;
        isRetweeted = true;
      });
    } catch (e) {
      print('❌ Haykır retweet hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ✅ Retweet'i geri al
  Future<void> _undoRetweet() async {
    if (widget.haykirData == null || widget.haykirData!['id'] == null) return;
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return;
    
    final haykirId = widget.haykirData!['id'].toString();
    
    // ✅ Grup-19 ile yapılmışsa geri alınamaz
    if (_isRetweetPermanent()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Grup-19 ile yapılan retweet geri alınamaz!'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    
    try {
      // ✅ Adım 1: Retweet istatistiğini geri al (action: 'retweet' ile toggle yapılır)
      await HiveDatabaseService.updateHaykirInteractionStats(
        haykirId: haykirId,
        userEmail: widget.userEmail!,
        action: 'retweet', // Toggle işlemi
      );
      
      // ✅ Adım 2: Seyir defterindeki retweet post'unu bul ve kaldır
      try {
        final davaProvider = Provider.of<DavaProvider>(context, listen: false);
        final homeFeedPosts = davaProvider.homeFeedPosts;
        
        // Kullanıcının bu haykır için retweet post'unu bul
        final retweetPost = homeFeedPosts.firstWhere(
          (post) => 
            post['type'] == 'haykir' &&
            post['authorEmail'] == widget.userEmail &&
            post['payload']?['haykirId'] == haykirId &&
            post['payload']?['isRetweet'] == true,
          orElse: () => <String, dynamic>{},
        );
        
        if (retweetPost.isNotEmpty && retweetPost['id'] != null) {
          await davaProvider.removeHomeFeedPost(retweetPost['id']);
          print('✅ Retweet post seyir defterinden kaldırıldı: ${retweetPost['id']}');
        }
      } catch (e) {
        print('⚠️ Retweet post kaldırılırken hata: $e');
      }
      
      // ✅ Adım 3: State'i güncelle
      setState(() {
        isRetweeted = false;
        retweetCount = retweetCount > 0 ? retweetCount - 1 : 0;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Retweet geri alındı'),
            duration: Duration(seconds: 2),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      print('❌ Retweet geri alma hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

}