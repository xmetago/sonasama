import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/shared/app_expandable_icon_menu.dart';
import '../services/hive_database_service.dart';
import '../services/itibar_endeksi_service.dart';
import '../utils/dialog_utils.dart';
import '../data/direm_data.dart';
import '../providers/dava_provider.dart';
import '../theme/seyir_tokens.dart';
import '../utils/haykir_duration.dart';

import '../widgets/haykir_case_card.dart';
import '../widgets/shared/app_snack.dart';
export '../widgets/haykir_case_card.dart' show Haykir, FiveCardCaseInformation, publishHaykirToHomeFeed;




class HaykirPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final bool initialShowForm; // Sayfa açıldığında formu otomatik aç
  final String? initialSlogan;
  final String? initialDetay;

  const HaykirPage({
    super.key, 
    this.userEmail,
    this.initialShowForm = false,
    this.initialSlogan,
    this.initialDetay,
  });

  @override
  State<HaykirPage> createState() => _HaykirPageState();
}

class _HaykirPageState extends State<HaykirPage> {
  int? expandedCardIndex;
  
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
    final slogan = widget.initialSlogan;
    final detay = widget.initialDetay;
    if (slogan != null && slogan.isNotEmpty) {
      _sloganController.text = slogan;
    }
    if (detay != null && detay.isNotEmpty) {
      _detayController.text = detay;
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
    return HaykirDuration.formatRemaining(createdAt);
  }
  
  // Formdan ön hazırlık kartı oluştur (henüz yayınlanmaz)
  Future<void> _createHaykirDraft(Map<String, dynamic> haykirData) async {
    try {
      if (widget.userEmail != null) {
        haykirData['userEmail'] = widget.userEmail;
      }

      final author = widget.userEmail == null
          ? null
          : HiveDatabaseService.getRegistrationByEmail(widget.userEmail!);
      final ozelDiremText = _ozelDiremController.text.trim();
      if (ozelDiremText.isNotEmpty) {
        haykirData['direme'] = ozelDiremText;
        haykirData['isOzelDirem'] = 'true';
        await HiveDatabaseService.addOzelDirem(ozelDiremText);
        if (author != null) {
          await ItibarEndeksiService.registerDirenAuthor(
            text: ozelDiremText,
            authorUserId: author.id,
          );
        }
      } else if (author != null && _selectedDireme != null) {
        await ItibarEndeksiService.creditDirenReuse(
          text: _selectedDireme!,
          usedByUserId: author.id,
        );
      }

      haykirData['isActive'] = 'true';
      haykirData['isPublishedOnCard'] = 'false';

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

      final haykirId =
          cleanHaykirData['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString();
      cleanHaykirData['id'] = haykirId;

      await HiveDatabaseService.addHaykir(cleanHaykirData);

      _adiController.clear();
      _sloganController.clear();
      _detayController.clear();
      _ozelDiremController.clear();
      _selectedDireme = null;

      setState(() {
        showCreateForm = false;
      });

      if (mounted) {
        showAppSnack(context, '✅ Ön hazırlık kartı oluşturuldu. Yayınlamak için karttaki HAYKIR\'a basın.', backgroundColor: Colors.orange, duration: Duration(seconds: 3));
      }

      setState(() {});
    } catch (e) {
      if (mounted) {
        showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
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
    final palette = SeyirPalette.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // Dinamik kategorileri yükle
    final allCategories = _getAllCategories();

    // Veritabanından haykırışları çek (taslaklar yalnızca sahibine görünür)
    final haykirDataList = HiveDatabaseService.getAllActiveHaykirislar()
        .where((data) {
          final publishedFlag = data['isPublishedOnCard'];
          final isPublished = publishedFlag is bool
              ? publishedFlag
              : publishedFlag?.toString().toLowerCase() == 'true';
          // Eski kayıtlar: flag yoksa zaten yayınlanmış kabul et
          final isLegacyPublished =
              publishedFlag == null || publishedFlag.toString().isEmpty;
          final isOwner = widget.userEmail != null &&
              data['userEmail']?.toString() == widget.userEmail;
          return isPublished || isLegacyPublished || isOwner;
        })
        .toList();
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
      backgroundColor: palette.surface,
      body: SafeArea(
        child: AppExpandableIconMenu(
          expandBody: true,
          inset: const EdgeInsets.all(16),
          openGap: 16,
          keepGapWhenClosed: !isSmallScreen,
          items: [
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: IconButton(
                tooltip: 'Ekle',
                style: IconButton.styleFrom(
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  fixedSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  padding: EdgeInsets.zero,
                ),
                icon: Icon(Icons.campaign, size: 24, color: palette.textSecondary),
                onPressed: () {
                  setState(() {
                    showCreateForm = !showCreateForm;
                  });
                },
              ),
            ),
            AppExpandableIconMenuItem(
              onTap: () {},
              customChild: const Column(
                children: [
                  SizedBox(height: 76),
                  Image(
                    image: AssetImage('lib/icons/06_left_row_ahizelitelefon_icon.png'),
                    width: 24,
                    height: 24,
                  ),
                ],
              ),
            ),
          ],
          headerBuilder: (BuildContext context, Widget menuButton, VoidCallback toggle, bool isOpen) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
            // Header Section
            Container(
              color: palette.surface,
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
              color: palette.surface,
              padding: const EdgeInsets.symmetric(horizontal: 53.0, vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      decoration: BoxDecoration(
                        color: Colors.orangeAccent,
                        borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                      ),
                      child: const Text(
                        'HAYKIR',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: SeyirTokens.typeTitle,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

              ],
            );
          },
          body: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Yeni Haykırış Oluşturma Formu
                            if (showCreateForm)
                              Card(
                                elevation: 4,
                                color: palette.card,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(SeyirTokens.radiusLg),
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
                                          Text(
                                            'Yeni Haykırış Oluştur',
                                            style: palette.headline(),
                                          ),
                                          const Spacer(),
                                          IconButton(
                                            tooltip: 'Kapat',
                                            style: IconButton.styleFrom(
                                              minimumSize: const Size(
                                                SeyirTokens.tapTarget,
                                                SeyirTokens.tapTarget,
                                              ),
                                              fixedSize: const Size(
                                                SeyirTokens.tapTarget,
                                                SeyirTokens.tapTarget,
                                              ),
                                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              padding: EdgeInsets.zero,
                                            ),
                                            icon: Icon(Icons.close, color: palette.textSecondary),
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
                                          color: palette.tint(Colors.orange.shade700),
                                          borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                                          border: Border.all(
                                            color: palette.tintBorder(Colors.orange.shade700),
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
                                                  borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                                                ),
                                                filled: true,
                                                fillColor: palette.card,
                                              ),
                                              style: palette.title(weight: FontWeight.w500),
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
                                                  borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                                                ),
                                                filled: true,
                                                fillColor: palette.card,
                                              ),
                                              style: palette.body(),
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
                                                      style: palette.caption(
                                                        weight: FontWeight.w800,
                                                        color: palette.foreground(Colors.orange.shade700),
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
                                                            style: palette.body(
                                                              color: (_selectedDireme != null || _ozelDiremController.text.trim().isNotEmpty)
                                                                  ? palette.textPrimary
                                                                  : palette.textMuted,
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
                                          color: palette.tint(Colors.green.shade700),
                                          borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                                          border: Border.all(
                                            color: palette.tintBorder(Colors.green.shade700),
                                            style: BorderStyle.solid,
                                            width: 2,
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'DİREN',
                                              style: palette.headline(),
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
                                                  color: palette.border,
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
                                                          style: palette.caption(
                                                            weight: isSelected ? FontWeight.w800 : FontWeight.w500,
                                                            color: palette.textPrimary,
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
                                                    selectedColor: category.color.withValues(alpha: 0.3),
                                                    checkmarkColor: category.color,
                                                    backgroundColor: palette.card,
                                                    side: BorderSide(
                                                      color: isSelected ? category.color : palette.border,
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
                                                      selectedColor: category.color.withValues(alpha: 0.3),
                                                      checkmarkColor: category.color,
                                                      backgroundColor: palette.card,
                                                      labelStyle: palette.body(),
                                                      side: BorderSide(
                                                        color: isSelected ? category.color : palette.border,
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
                                                color: palette.card,
                                                borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
                                                border: Border.all(
                                                  color: palette.tintBorder(Colors.green.shade700),
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
                                                        counterStyle: palette.caption(
                                                          color: _ozelDiremController.text.length > 19
                                                            ? SeyirTokens.reject
                                                            : palette.textMuted,
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
                                                            showAppSnack(context, '❌ Direm maksimum 19 karakter olmalıdır!', backgroundColor: Colors.red);
                                                          }
                                                          return;
                                                        }

                                                        try {
                                                          await HiveDatabaseService.addUyelerdenDirem(diremText);
                                                          final author = widget.userEmail == null
                                                              ? null
                                                              : HiveDatabaseService.getRegistrationByEmail(
                                                                  widget.userEmail!,
                                                                );
                                                          if (author != null) {
                                                            await ItibarEndeksiService.registerDirenAuthor(
                                                              text: diremText,
                                                              authorUserId: author.id,
                                                            );
                                                          }

                                                          setState(() {
                                                            _selectedDireme = null;
                                                          });

                                                          if (mounted) {
                                                            showAppSnack(context, '✅ "$diremText" Üyelerden kategorisine eklendi!', backgroundColor: Colors.green);
                                                          }
                                                        } catch (e) {
                                                          if (mounted) {
                                                            showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
                                                          }
                                                        }
                                                      }
                                                    },
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: Colors.green.shade700,
                                                      foregroundColor: Colors.white,
                                                      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
                                                      ),
                                                    ),
                                                    child: Text('Ekle', style: palette.body(weight: FontWeight.w800, color: Colors.white)),
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
                                            borderRadius: BorderRadius.circular(SeyirTokens.radiusMd),
                                          ),
                                          filled: true,
                                          fillColor: palette.card,
                                          helperText: '${_detayController.text.length}/361 karakter',
                                          errorText: _detayController.text.trim().isNotEmpty && 
                                                     (_detayController.text.trim().length < 19 || 
                                                      _detayController.text.trim().length > 361)
                                              ? (_detayController.text.trim().length < 19 
                                                  ? 'Detay en az 19 karakter olmalıdır' 
                                                  : 'Detay en fazla 361 karakter olabilir')
                                              : null,
                                        ),
                                        style: palette.body(),
                                        maxLines: 6,
                                        maxLength: 361, // ✅ En fazla 361 karakter
                                        buildCounter: (context, {required currentLength, required isFocused, maxLength}) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              '$currentLength/$maxLength karakter',
                                              style: palette.caption(
                                                color: currentLength < 19 
                                                    ? SeyirTokens.reject 
                                                    : (currentLength > 361 ? SeyirTokens.reject : palette.textMuted),
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
                                                foregroundColor: palette.textPrimary,
                                                minimumSize: const Size(0, SeyirTokens.tapTarget),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
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
                                                      _createHaykirDraft(haykirData);
                                                    }
                                                  : null,
                                              icon: const Icon(Icons.campaign, size: 20),
                                              label: const Text(
                                                'Kartı hazırla',
                                                style: TextStyle(
                                                  fontSize: SeyirTokens.typeTitle,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.orange.shade600,
                                                foregroundColor: Colors.white,
                                                disabledBackgroundColor: palette.surfaceMuted,
                                                disabledForegroundColor: palette.textSecondary,
                                                minimumSize: const Size(0, SeyirTokens.tapTarget),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(SeyirTokens.radiusSm),
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
                                          haykirData['userEmail']?.toString() == widget.userEmail &&
                                          haykirData['isPublishedOnCard']?.toString().toLowerCase() == 'false'
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
                                              showAppSnack(context, '✅ Haykırış silindi ve seyir defterinden kaldırıldı.', backgroundColor: Colors.green);
                                            }
                                          } catch (e) {
                                            if (mounted) {
                                              showAppSnack(context, '❌ Hata: $e', backgroundColor: Colors.red);
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
      ),
    );
  }
}

