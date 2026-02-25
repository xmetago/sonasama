import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // TextInputFormatter için
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/modern_dava_form_widgets.dart';
import 'actigim_davalar_page.dart';
import 'delilleri_incele_page.dart';
import 'delil_ekle_page.dart';
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../models/dava.dart' as dava_model; // Dava modeli için import eklendi (alias ile)
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../utils/app_theme.dart';

// GroupOption model sınıfı
class GroupOption {
  final String value;
  final String description;
  final IconData icon;
  final Color color;

  GroupOption({
    required this.value,
    required this.description,
    required this.icon,
    required this.color,
  });
}

// Eski Dava modeli
class Dava {
  final String id; // Benzersiz dava ID'si
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu; // Dava konusu alanı eklendi
  final String davaKategorisi; // Dava kategorisi alanı eklendi
  final String davaci; // Davacı bilgisi alanı eklendi
  final bool isOpened;

  Dava({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.davaKonusu = '', // Varsayılan boş değer
    this.davaKategorisi = '', // Varsayılan boş değer
    this.davaci = '', // Varsayılan boş değer
    this.isOpened = false,
  });
}

class DavaAcPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final String? selectedCategory; // Seçilen kategori
  final String? selectedSubCategory; // Seçilen alt kategori
  final dava_model.Dava? editDava; // Düzenlenecek dava (yeni parametre)

  const DavaAcPage({
    super.key, 
    this.userEmail, 
    this.selectedCategory,
    this.selectedSubCategory,
    this.editDava, // Düzenleme modu için parametre eklendi
  });

  @override
  State<DavaAcPage> createState() => _DavaAcPageState();
}

class _DavaAcPageState extends State<DavaAcPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  int? expandedCardIndex;
  bool showLeftIcons = false; // Sol ikonları gösterme durumu
  bool isWhoboomUser = true; // Checkbox için - WHObOOM kullanıcısı mı? (varsayılan seçili)
  final TextEditingController _davaliController = TextEditingController();
  final TextEditingController _davaDetayController = TextEditingController();
  final TextEditingController _davaAdiController = TextEditingController(); // Dava adı için controller
  List<String> _filteredUsers = [];
  bool _showUserSuggestions = false;
  bool _canDavala = false; // DAVALA butonu aktif mi?
  List<Dava> _savedDavalar = []; // Kaydedilen davalar listesi
  
  // Dava listesi - sınıf seviyesinde tanımlandı
  List<Dava> davaList = [
    Dava(
      id: "dava_${DateTime.now().millisecondsSinceEpoch}", // Benzersiz ID oluştur
      adi: "Ad  ver ",
      davali: "Davalı  adını gir ",
      mevkii: "Davalı",
      kalanSure: ".../.../.....",
      profilResmi: "lib/icons/03_davala_ana_icon.png",
      davaKonusu: '', // Dava konusu başlangıç değeri
      davaKategorisi: '', // Dava kategorisi başlangıç değeri
      davaci: '', // Davacı bilgisi başlangıç değeri
    ),
  ];

  // 🎨 Sıcak ve Eğlenceli Renk Teması

  @override
  void initState() {
    super.initState();
    _davaliController.addListener(_onDavaliChanged);
    _davaDetayController.addListener(_onDavaDetayChanged);
    _davaAdiController.addListener(_onDavaAdiChanged);
    _loadSavedDavalarFromDatabase();
    
    // Düzenleme modu kontrolü - editDava varsa form alanlarını doldur
    if (widget.editDava != null) {
      _populateFormForEditing(widget.editDava!);
      return; // Düzenleme modunda kategori kontrolü yapma
    }
    
    // Normal mod - kategori kontrolü yap
    _initializeNormalMode();
  }

  @override
  void dispose() {
    // Sayfa kapatılırken otomatik kaydetme işlemi
    _autoSaveOnExit();
    
    // Controller'ları temizle
    _davaliController.dispose();
    _davaDetayController.dispose();
    _davaAdiController.dispose();
    super.dispose();
  }

  /// Sayfa kapatılırken otomatik kaydetme işlemi
  void _autoSaveOnExit() {
    // Sadece normal modda ve dava henüz açılmamışsa kaydet
    if (widget.editDava == null && !davaList[0].isOpened) {
      // Kullanıcı adını al
      final davaciAdi = widget.userEmail != null 
          ? HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)?.judgeName ?? 'Bilinmeyen Yargıç'
          : 'Bilinmeyen Yargıç';
      
      // Beklemede dava oluştur
      final beklemedeDava = dava_model.Dava(
        id: "beklemede_${DateTime.now().millisecondsSinceEpoch}",
        davaAdi: "Beklemede",
        davaci: davaciAdi,
        davali: "Beklemede",
        mevkii: "Beklemede",
        kalanSure: ".../.../.....",
        profilResmi: "lib/icons/03_davala_ana_icon.png",
        davaKonusu: "Beklemede",
        kategori: davaList[0].davaKategorisi.isNotEmpty ? davaList[0].davaKategorisi : "Genel",
        isOpened: false,
      );
      
      // Veritabanına kaydet
      try {
        HiveDatabaseService.saveDava({
          'id': beklemedeDava.id,
          'davaAdi': beklemedeDava.davaAdi,
          'davaci': beklemedeDava.davaci,
          'davali': beklemedeDava.davali,
          'mevkii': beklemedeDava.mevkii,
          'kalanSure': beklemedeDava.kalanSure,
          'profilResmi': beklemedeDava.profilResmi,
          'davaKonusu': beklemedeDava.davaKonusu,
          'kategori': beklemedeDava.kategori,
          'isOpened': beklemedeDava.isOpened,
          'savedAt': DateTime.now().toIso8601String(),
        });
        
        print('✅ Beklemede dava otomatik kaydedildi: ${beklemedeDava.id}');
      } catch (e) {
        print('❌ Beklemede dava kaydedilirken hata: $e');
      }
    }
  }

  /// Normal mod için başlatma işlemleri
  void _initializeNormalMode() {
    // Kategori kontrolü - kategori seçilmediyse uyarı göster ve geri dön
    if (widget.selectedCategory == null || widget.selectedSubCategory == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCategoryRequiredDialog();
      });
      return;
    }
    
    // Seçilen kategoriyi dava listesine ekle
    final kategoriText = '${widget.selectedCategory} > ${widget.selectedSubCategory}';
    setState(() {
      davaList[0] = Dava(
        id: davaList[0].id,
        adi: davaList[0].adi,
        davali: davaList[0].davali,
        mevkii: davaList[0].mevkii,
        kalanSure: davaList[0].kalanSure,
        profilResmi: davaList[0].profilResmi,
        davaKonusu: davaList[0].davaKonusu,
        davaKategorisi: kategoriText,
        isOpened: davaList[0].isOpened,
      );
    });
  }

  /// Düzenleme modu için form alanlarını doldur
  void _populateFormForEditing(dava_model.Dava editDava) {
    // Debug: Düzenleme modunun başladığını göster
    print('🔄 Düzenleme modu başlatıldı: ${editDava.davaAdi}');
    print('📝 Dava konusu: ${editDava.davaKonusu}');
    
    setState(() {
      // Form controller'larını doldur
      _davaAdiController.text = editDava.davaAdi;
      _davaliController.text = editDava.davali;
      _davaDetayController.text = editDava.davaKonusu; // Dava konusu için doğru alan kullanılıyor
      
      // Dava listesini güncelle (yerel Dava sınıfı kullanılıyor)
      davaList[0] = Dava(
        id: editDava.id, // Mevcut ID'yi koru
        adi: editDava.davaAdi,
        davali: editDava.davali,
        mevkii: editDava.mevkii,
        kalanSure: editDava.kalanSure,
        profilResmi: editDava.profilResmi,
        davaKonusu: editDava.davaKonusu, // Dava konusu için doğru alan kullanılıyor
        davaKategorisi: editDava.kategori,
        davaci: editDava.davaci,
        isOpened: editDava.isOpened,
      );
    });
    
    // DAVALA butonunu kontrol et
    _checkDavalaButton();
  }

  // Davalı değiştiğinde kullanıcı arama ve card'ı güncelle
  void _onDavaliChanged() {
    if (isWhoboomUser && _davaliController.text.length >= 4) {
      _filterUsersByName(_davaliController.text);
    } else {
      setState(() {
        _showUserSuggestions = false;
      });
    }
    
    // Davalı bilgisini card'da güncelle
    setState(() {
      davaList[0] = Dava(
        id: davaList[0].id,
        adi: davaList[0].adi,
        davali: _davaliController.text.isNotEmpty ? _davaliController.text : davaList[0].davali,
        mevkii: davaList[0].mevkii,
        kalanSure: davaList[0].kalanSure,
        profilResmi: davaList[0].profilResmi,
        davaKonusu: davaList[0].davaKonusu,
        davaKategorisi: davaList[0].davaKategorisi,
        davaci: davaList[0].davaci,
        isOpened: davaList[0].isOpened,
      );
    });
    
    // DAVALA butonunu kontrol et
    _checkDavalaButton();
  }

  // Kullanıcıları isme göre filtrele ve "Bana Dava Açılsın" ayarını kontrol et
  Future<void> _filterUsersByName(String searchText) async {
    try {
      final users = HiveDatabaseService.getAllRegistrations();
      final filteredUsers = <String>[];
      
      for (final user in users) {
        // Kullanıcı adı arama kriterine uyuyor mu?
        if (!user.judgeName.toLowerCase().contains(searchText.toLowerCase())) {
          continue;
        }
        
        // Kullanıcının "Bana Dava Açılsın" ayarını kontrol et
        try {
          final userSettings = await HiveDatabaseService.getOrCreateSettings(user.email);
          // Eğer "Bana Dava Açılsın" seçeneği true ise, bu kullanıcıyı listeye dahil et
          if (userSettings.privacySettings['genel_davaacilsin'] ?? true) {
            filteredUsers.add(user.judgeName);
          }
        } catch (e) {
          // Hata durumunda varsayılan olarak dava açılabilir kabul et
          filteredUsers.add(user.judgeName);
        }
        
        // Maksimum 5 kişi göster
        if (filteredUsers.length >= 5) break;
      }
      
      if (mounted) {
        setState(() {
          _filteredUsers = filteredUsers;
          _showUserSuggestions = filteredUsers.isNotEmpty;
        });
      }
    } catch (e) {
      // Hata durumunda boş liste göster
      if (mounted) {
        setState(() {
          _filteredUsers = [];
          _showUserSuggestions = false;
        });
      }
    }
  }

  // Kullanıcı önerisini seç
  void _selectUserSuggestion(String userName) {
    _davaliController.text = userName;
    setState(() {
      _showUserSuggestions = false;
    });
  }

  // Checkbox değiştiğinde bilgilendirme mesajı göster
  void _onCheckboxChanged(bool? value) {
    setState(() {
      isWhoboomUser = value ?? true;
    });

    // Checkbox işaretlendiyse alert dialog göster
    if (value == true) {
      _showInfoDialog();
    }
  }

  // Bilgilendirme dialog'u göster
  void _showInfoDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_add,
                    size: 24,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mesaj
                Text(
                  'İşaretlerseniz,kayıtlı bir üyeye  dava açabilirsiniz!',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.blue[600],
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );

    // 3 saniye sonra dialog'u otomatik kapat
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  // Dava adı değiştiğinde card'ı güncelle ve DAVALA butonunu kontrol et
  void _onDavaAdiChanged() {
    // Dava adını card'da güncelle
    setState(() {
      davaList[0] = Dava(
        id: davaList[0].id,
        adi: _davaAdiController.text.isNotEmpty ? _davaAdiController.text : davaList[0].adi,
        davali: davaList[0].davali,
        mevkii: davaList[0].mevkii,
        kalanSure: davaList[0].kalanSure,
        profilResmi: davaList[0].profilResmi,
        davaKonusu: davaList[0].davaKonusu,
        davaKategorisi: davaList[0].davaKategorisi,
        davaci: davaList[0].davaci,
        isOpened: davaList[0].isOpened,
      );
    });
    
    _checkDavalaButton();
  }

  // Dava detayları değiştiğinde DAVALA butonunu kontrol et ve card'ı güncelle
  void _onDavaDetayChanged() {
    // Dava konusunu card'da güncelle
    setState(() {
      davaList[0] = Dava(
        id: davaList[0].id,
        adi: davaList[0].adi,
        davali: davaList[0].davali,
        mevkii: davaList[0].mevkii,
        kalanSure: davaList[0].kalanSure,
        profilResmi: davaList[0].profilResmi,
        davaKonusu: _davaDetayController.text, // Güncel dava konusunu ekle
        davaKategorisi: davaList[0].davaKategorisi,
        davaci: davaList[0].davaci,
        isOpened: davaList[0].isOpened,
      );
    });
    
    _checkDavalaButton();
  }

  // DAVALA butonunun aktif olup olmadığını kontrol et
  void _checkDavalaButton() {
    final davaAdiUzunluk = _davaAdiController.text.isNotEmpty 
        ? _davaAdiController.text.length 
        : (davaList[0].adi.trim().isEmpty || davaList[0].adi == "Ad  ver " ? 0 : davaList[0].adi.length);
    
    final davaliSecildi = _davaliController.text.isNotEmpty && _davaliController.text != "Davalı  adını gir ";
    final davaKonusuUzunluk = _davaDetayController.text.length;
    
    setState(() {
      _canDavala = davaAdiUzunluk >= 6 && davaliSecildi && davaKonusuUzunluk >= 285;
    });
  }

  // Kategori gerekli dialog'u göster
  void _showCategoryRequiredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // İkon ve başlık
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.category,
                    size: 40,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  'Kategori Seçimi Gerekli! 📋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                
                // Mesaj
                const Text(
                  'Dava açabilmek için önce bir kategori seçmelisiniz.\n\nLütfen kategori sayfasından bir kategori seçin.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 25),
                
                // Buton
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Dialog'u kapat
                      Navigator.of(context).pop(); // Dava aç sayfasından geri dön
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Kategori Seç',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

  // Dava kaydet
  void _saveDava() async {
    // Debug: Kaydetme işleminin başladığını göster
    print('💾 Dava kaydetme işlemi başlatıldı');
    
    // Controller'lardan güncel verileri al
    final guncelDavaAdi = _davaAdiController.text.isNotEmpty 
        ? _davaAdiController.text 
        : (davaList[0].adi.trim().isEmpty || davaList[0].adi == "Ad  ver " 
            ? "@${widget.userEmail != null ? HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)?.judgeName ?? 'Bilinmeyen Yargıç' : 'Bilinmeyen Yargıç'} - Davası"
            : davaList[0].adi);
    
    final guncelDavali = _davaliController.text.isNotEmpty ? _davaliController.text : davaList[0].davali;
    final guncelDavaKonusu = _davaDetayController.text;
    
    // Davacı bilgisini al
    final davaciBilgisi = await _getDisplayName(widget.userEmail);
    
    // Aynı ID'li dava zaten var mı kontrol et
    final existingIndex = _savedDavalar.indexWhere((dava) => dava.id == davaList[0].id);
    
    final savedDava = Dava(
      id: davaList[0].id, // Mevcut ID'yi kullan
      adi: guncelDavaAdi,
      davali: guncelDavali,
      mevkii: davaList[0].mevkii,
      kalanSure: davaList[0].kalanSure,
      profilResmi: davaList[0].profilResmi,
      davaKonusu: guncelDavaKonusu, // Güncel dava konusu
      davaKategorisi: davaList[0].davaKategorisi, // Kategori bilgisini koru
      davaci: davaciBilgisi, // Davacı bilgisini ekle
      isOpened: davaList[0].isOpened,
    );
    
    // Ana dava listesini de güncelle
    setState(() {
      davaList[0] = savedDava;
    });
    
    // Veritabanına kaydet
    HiveDatabaseService.saveDava({
      'id': savedDava.id,
      'adi': savedDava.adi,
      'davali': savedDava.davali,
      'mevkii': savedDava.mevkii,
      'kalanSure': savedDava.kalanSure,
      'profilResmi': savedDava.profilResmi,
      'davaKonusu': savedDava.davaKonusu, // Dava konusu veritabanına kaydet
      'davaKategorisi': savedDava.davaKategorisi, // Kategori bilgisini veritabanına kaydet
      'davaci': savedDava.davaci, // Davacı bilgisini veritabanına kaydet
      'isOpened': savedDava.isOpened,
    });
    
    setState(() {
      if (existingIndex != -1) {
        // Aynı ID'li dava varsa güncelle
        _savedDavalar[existingIndex] = savedDava;
      } else {
        // Yeni dava ise en üste ekle
        _savedDavalar.insert(0, savedDava);
      }
    });

    // Dava kaydetme işlemi
    _showModernAlert(
      context,
      'Başarılı!',
      existingIndex != -1 
          ? 'Dava başarıyla güncellendi.' 
          : 'Dava, daha sonra düzenlenmek üzere kaydedildi.',
      Icons.save,
      Colors.green,
    );
  }

  // Kaydedilen davaları göster - Global utility fonksiyonunu kullan
  void _showSavedDavalarDialog() {
    // Kullanıcı e-posta adresini al
    final userEmail = widget.userEmail ?? '';
    if (userEmail.isEmpty) {
      // E-posta yoksa uyarı göster
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kullanıcı bilgisi bulunamadı'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Global utility fonksiyonunu çağır
    showSavedDavalarDialog(context, userEmail);
  }

  // Kaydedilen davayı düzenle
  void _editSavedDava(int index, [BuildContext? context]) {
    final selectedDava = _savedDavalar[index];
    
    // Controller'ları güncelle
    _davaAdiController.text = selectedDava.adi;
    _davaliController.text = selectedDava.davali;
    _davaDetayController.text = selectedDava.davaKonusu;
    
    // Ana dava listesini güncelle (kategori bilgisini de dahil et)
    setState(() {
      davaList[0] = Dava(
        id: selectedDava.id,
        adi: selectedDava.adi,
        davali: selectedDava.davali,
        mevkii: selectedDava.mevkii,
        kalanSure: selectedDava.kalanSure,
        profilResmi: selectedDava.profilResmi,
        davaKonusu: selectedDava.davaKonusu,
        davaKategorisi: selectedDava.davaKategorisi, // Kategori bilgisini koru
        isOpened: selectedDava.isOpened,
      );
    });
    
    // DAVALA butonunu kontrol et
    _checkDavalaButton();
    
    if (context != null) {
      Navigator.of(context).pop();
    }
  }

  // Veritabanından kaydedilen davaları yükle
  void _loadSavedDavalarFromDatabase() {
    final savedDavalar = HiveDatabaseService.getSavedDavalar();
    setState(() {
      _savedDavalar = savedDavalar.map((davaMap) => Dava(
        id: davaMap['id'] ?? '',
        adi: davaMap['adi'] ?? '',
        davali: davaMap['davali'] ?? '',
        mevkii: davaMap['mevkii'] ?? '',
        kalanSure: davaMap['kalanSure'] ?? '',
        profilResmi: davaMap['profilResmi'] ?? '',
        davaKonusu: davaMap['davaKonusu'] ?? '', // Dava konusu yükleme
        davaKategorisi: davaMap['davaKategorisi'] ?? '', // Kategori bilgisini yükleme
        isOpened: davaMap['isOpened'] ?? false,
      )).toList();
    });
  }

  // Kaydedilen davayı sil
  void _deleteSavedDava(int index, [Function? setDialogState]) {
    final davaToDelete = _savedDavalar[index];
    
    // Veritabanından sil
    HiveDatabaseService.deleteSavedDava(davaToDelete.id);
    
    setState(() {
      _savedDavalar.removeAt(index);
    });
    
    // Dialog state'ini güncelle (eğer verilmişse)
    if (setDialogState != null) {
      setDialogState(() {});
    }
  }

  // Dava aç
  void _openDava() {
    _showGroupSelectionDialog();
  }

  // Grup seçim dialog'u göster
  void _showGroupSelectionDialog() {
    String? selectedGroup;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
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
                    colors: [Colors.blue.withOpacity(0.1), Colors.green.withOpacity(0.05)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Başlık
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.gavel, size: 24, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          const Text(
                            'Dava Gönderilecek Grup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    
                    // Radio butonlar
                    Column(
                      children: [
                        _buildRadioOption(
                          context,
                          'Grup19',
                          'Grup19 üyelerine dava gönder',
                          Icons.group,
                          Colors.purple,
                          selectedGroup,
                          (value) {
                            setDialogState(() {
                              selectedGroup = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRadioOption(
                          context,
                          'Arkadaşlar',
                          'Arkadaşlarınıza dava gönder',
                          Icons.people,
                          Colors.green,
                          selectedGroup,
                          (value) {
                            setDialogState(() {
                              selectedGroup = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRadioOption(
                          context,
                          'Takipçiler',
                          'Takipçilerinize dava gönder',
                          Icons.person_add,
                          Colors.orange,
                          selectedGroup,
                          (value) {
                            setDialogState(() {
                              selectedGroup = value;
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildRadioOption(
                          context,
                          'Tanımadıklarım',
                          'Tanımadığınız kişilere dava gönder',
                          Icons.person_off,
                          Colors.red,
                          selectedGroup,
                          (value) {
                            setDialogState(() {
                              selectedGroup = value;
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
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[300],
                              foregroundColor: Colors.black87,
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
                            onPressed: selectedGroup != null 
                                ? () {
                                    Navigator.of(context).pop();
                                    _processDavaOpening(selectedGroup!);
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: selectedGroup != null ? Colors.blue : Colors.grey,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text(
                              'DAVA ATA',
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

  // Radio seçenek widget'ı
  Widget _buildRadioOption(
    BuildContext context,
    String value,
    String title,
    IconData icon,
    Color color,
    String? selectedGroup,
    Function(String?) onChanged,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: selectedGroup == value ? color.withOpacity(0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selectedGroup == value ? color : Colors.grey[300]!,
          width: selectedGroup == value ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: selectedGroup,
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
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: selectedGroup == value ? color : Colors.black87,
                    ),
                  ),
                  Text(
                    title,
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

  // Dava açıldı başarı dialog'u göster
  void _showDavaOpenedSuccessDialog(String selectedGroup, String formattedDate) {
    // Başarı dialog'u kapandıktan sonra kaydedilen davalar listesini güncelle
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başarı ikonu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 32,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  'Dava Başarıyla Açıldı',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Mesaj
                Text(
                  'Davanız "$selectedGroup" grubuna gönderildi\nTarih: $formattedDate',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Başarı detayları
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                ),
                const SizedBox(height: 20),
                
                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Image.asset(
                          'lib/icons/06_left_row_actigim_davalar_icon.png',
                          width: 20,
                          height: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seyir Defterinizde soldaki ikona basarak \n  davanızı takip edebilirsiniz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Butonlar
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _showDavetGondermeDialog();
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('DAVET ET '),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _loadSavedDavalarFromDatabase();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text('Tamam'),
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

  // Davet gönderildi uyarı dialog'unu göster
  void _showDavetGonderildiDialog(List<String> selectedGroups) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Başarı ikonu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.send,
                    size: 32,
                    color: Colors.blue.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Başlık
                Text(
                  'Davetler Gönderildi!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Mesaj
                Text(
                  'Seçilen ${selectedGroups.length} gruba davet gönderildi:\n${selectedGroups.join(", ")}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Bilgi kutusu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.check_circle,
                          color: Colors.green.shade600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Davetler başarıyla gönderildi ve kaydedildi',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tamam butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    // 3 saniye sonra dialog'u otomatik kapat
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.of(context).pop();
      }
    });
  }

  // Davet gönderme dialog'unu göster
  void _showDavetGondermeDialog() {
    showDialog(
      context: context,
      builder: (context) => GroupSelectionDialog(
        dialogTitle: 'Davet Gönderilsin',
        groupOptions: [
          GroupOption(
            value: 'Grup19',
            description: 'Grup19 üyelerine davet gönder',
            icon: Icons.group,
            color: Colors.purple,
          ),
          GroupOption(
            value: 'Arkadaşlar',
            description: 'Arkadaşlarınıza davet gönder',
            icon: Icons.people,
            color: Colors.green,
          ),
          GroupOption(
            value: 'Takipçiler',
            description: 'Takipçilerinize davet gönder',
            icon: Icons.person_add,
            color: Colors.orange,
          ),
          GroupOption(
            value: 'Tanımadıklarım',
            description: 'Tanımadığınız kişilere davet gönder',
            icon: Icons.person_off,
            color: Colors.red,
          ),
        ],
      ),
    ).then((selectedGroups) {
    if (selectedGroups != null && selectedGroups.isNotEmpty) {
      print('Seçilen gruplar: $selectedGroups');
      _processDavetGonderme(selectedGroups);
      _showDavetGonderildiDialog(selectedGroups);
      _loadSavedDavalarFromDatabase();
    }
  });
  }

  // Davet gönderme işlemini gerçekleştir
  void _processDavetGonderme(List<String> selectedGroups) async {
    if (widget.userEmail == null) return;
    
    try {
      // Son açılan dava bilgilerini al
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      if (openedDavalar.isEmpty) return;
      
      final lastOpenedDava = openedDavalar.first;
      
      // Dava gönderilen kişilerin e-postalarını al (excludedEmails) - sadece davalı hariç tutulur
      final recipientEmails = <String>[];
      final davaliEmail = (lastOpenedDava['davali'] ?? '').toString().trim();
      if (davaliEmail.isNotEmpty) {
        recipientEmails.add(davaliEmail);
      }
      // ✅ Dava açan (davet gönderen) hariç tutulmaz - davet gönderen kişi de davet alır
      
      // Her seçilen grup için davet gönder
      for (final groupName in selectedGroups) {
        final invitationRecipients = await HiveDatabaseService.pickInvitationRecipients(
          widget.userEmail!,
          groupName,
          excludedEmails: recipientEmails, // Sadece davalı hariç tutulur
        );
        
        // Davet verilerini hazırla
        for (final recipient in invitationRecipients) {
          // Kategoriyi doğru al
          final kategoriValue = lastOpenedDava['kategori']?.toString() ?? 
                                lastOpenedDava['davaKategorisi']?.toString() ?? 
                                '';
          
          final invitation = {
            'id': 'invitation_${DateTime.now().millisecondsSinceEpoch}_${recipient.email}',
            'davaId': lastOpenedDava['id'],
            'davaAdi': lastOpenedDava['adi'] ?? lastOpenedDava['davaAdi'] ?? '',
            'davaKonusu': lastOpenedDava['davaKonusu'] ?? '',
            'kategori': kategoriValue,
            'davaKategori': kategoriValue, // Tutarlılık için her iki key'i de ekle
            'davaci': lastOpenedDava['davaci'] ?? '',
            'davali': lastOpenedDava['davali'] ?? '',
            'groupName': groupName,
            'invitedAt': DateTime.now().toIso8601String(),
            'isRead': false,
            // ModernDavaCard formatı için ek alanlar
            'userEmail': recipient.email,
            'displayName': recipient.judgeName ?? recipient.email,
            'isOpened': false,
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'yorumlar': <Map<String, dynamic>>[],
          };
          
          // Daveti kaydet
          HiveDatabaseService.addInvitation(recipient.email, invitation);
        }
        
        print('DEBUG: Grup "$groupName" için ${invitationRecipients.length} kişiye davet gönderildi');
        
        // Debug: Davet gönderilen kişileri listele
        for (final recipient in invitationRecipients) {
          print('  - Davet gönderildi: ${recipient.email} (${recipient.judgeName})');
        }
      }
      
      // Dava açan ve davalıya da davet gönder
      // Kategoriyi doğru al
      final kategoriValueForOpener = lastOpenedDava['kategori']?.toString() ?? 
                                      lastOpenedDava['davaKategorisi']?.toString() ?? 
                                      '';
      
      final invitationForOpenerAndDefendant = {
        'id': 'invitation_${DateTime.now().millisecondsSinceEpoch}_opener_defendant',
        'davaId': lastOpenedDava['id'],
        'davaAdi': lastOpenedDava['adi'] ?? lastOpenedDava['davaAdi'] ?? '',
        'davaKonusu': lastOpenedDava['davaKonusu'] ?? '',
        'kategori': kategoriValueForOpener,
        'davaKategori': kategoriValueForOpener, // Tutarlılık için her iki key'i de ekle
        'davaci': lastOpenedDava['davaci'] ?? '',
        'davali': lastOpenedDava['davali'] ?? '',
        'displayName': lastOpenedDava['davaci'] ?? '', // ModernDavaCard için
        'userEmail': widget.userEmail ?? '', // ModernDavaCard için
        'groupName': 'Dava Tarafları',
        'invitedAt': DateTime.now().toIso8601String(),
        'isRead': false,
        // ModernDavaCard formatı için ek alanlar
        'isOpened': false,
        'yorumSayisi': 0,
        'retweetSayisi': 0,
        'begeniSayisi': 0,
        'begenmemeSayisi': 0,
        'userLiked': false,
        'userDisliked': false,
        'userRetweeted': false, // Retweet state eklendi
        'yorumlar': [],
      };
      
      // Dava açana davet gönder
      HiveDatabaseService.addInvitation(widget.userEmail!, invitationForOpenerAndDefendant);
      
      // Davalıya da davet gönder (eğer varsa)
      if (davaliEmail.isNotEmpty) {
        HiveDatabaseService.addInvitation(davaliEmail, invitationForOpenerAndDefendant);
      }
      
      print('Dava açan ve davalıya da davet gönderildi');
    } catch (e) {
      print('Davet gönderme hatası: $e');
    }
  }

  // Kullanıcının görünüm adını al (gizlilik ayarlarına göre)
  Future<String> _getDisplayName(String? userEmail) async {
    if (userEmail == null) return 'Bilinmeyen Yargıç';
    
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      if (user == null) return 'Bilinmeyen Yargıç';
      
      final settings = await HiveDatabaseService.getOrCreateSettings(userEmail);
      final displayType = settings.stringSettings['display_name_type'] ?? 'yargic_adim';
      
      switch (displayType) {
        case 'gizli_yargic':
          return 'Gizli Yargıç';
        case 'yargic_adim':
          return user.judgeName;
        case 'eposta':
          return userEmail;
        default:
          return user.judgeName;
      }
    } catch (e) {
      // Hata durumunda yargıç adını döndür
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      return user?.judgeName ?? 'Bilinmeyen Yargıç';
    }
  }

  // Dava açma işlemini gerçekleştir
  void _processDavaOpening(String selectedGroup) async {
    // Dava adı minimum karakter kontrolü
    final davaAdiUzunluk = _davaAdiController.text.isNotEmpty 
        ? _davaAdiController.text.length 
        : (davaList[0].adi.trim().isEmpty || davaList[0].adi == "Ad  ver " ? 0 : davaList[0].adi.length);
    
    if (davaAdiUzunluk < 6) {
      _showDavaAdiMinLengthDialog();
      return;
    }
    
    // Eğer WhoBoom kullanıcısı seçiliyse, davalının "Bana Dava Açılsın" ayarını kontrol et
    if (isWhoboomUser && _davaliController.text.isNotEmpty) {
      final canOpenDava = await _checkIfUserAllowsDava(_davaliController.text);
      if (!canOpenDava) {
        _showDavaNotAllowedDialog();
        return;
      }
    }
    
    final currentDate = DateTime.now();
    final formattedDate = '${currentDate.day.toString().padLeft(2, '0')}.${currentDate.month.toString().padLeft(2, '0')}.${currentDate.year}';
    
    // Controller'lardan güncel verileri al
    final guncelDavaAdi = _davaAdiController.text.isNotEmpty 
        ? _davaAdiController.text 
        : (davaList[0].adi.trim().isEmpty || davaList[0].adi == "Ad  ver " 
            ? "@${widget.userEmail != null ? HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)?.judgeName ?? 'Bilinmeyen Yargıç' : 'Bilinmeyen Yargıç'} - Davası"
            : davaList[0].adi);
    
    final guncelDavali = _davaliController.text.isNotEmpty ? _davaliController.text : davaList[0].davali;
    final guncelDavaKonusu = _davaDetayController.text;
    
    // Eski dava ID'sini sakla (davaList[0] güncellenmeden önce)
    final oldDavaId = davaList[0].id;
    
    // Davacı bilgisini al
    final davaciBilgisi = await _getDisplayName(widget.userEmail);
    
    // Açılan davayı oluştur - ESKİ ID'Yİ KORU
    final openedDava = Dava(
      id: oldDavaId, // ESKİ ID'Yİ KORU - deliller kaybolmasın
      adi: guncelDavaAdi,
      davali: guncelDavali,
      mevkii: davaList[0].mevkii,
      kalanSure: formattedDate,
      profilResmi: davaList[0].profilResmi,
      davaKonusu: guncelDavaKonusu,
      davaci: davaciBilgisi,
      isOpened: true,
    );
    
    // Ana dava listesini güncelle
    setState(() {
      davaList[0] = openedDava;
    });
    
    // Kaydedilen davalar listesinden bu davayı kaldır (eski ID ile)
    final existingIndex = _savedDavalar.indexWhere((dava) => dava.id == oldDavaId);
    if (existingIndex != -1) {
      setState(() {
        _savedDavalar.removeAt(existingIndex);
      });
      
      // Veritabanından da kaldır (eski ID ile)
      HiveDatabaseService.deleteSavedDava(oldDavaId);
    }
    
    // Açılan davayı veritabanına kaydet (açtığım davalar için)
    try {
      HiveDatabaseService.saveOpenedDava({
        'id': openedDava.id,
        'davaAdi': openedDava.adi,
        'davaci': openedDava.davaci,
        'davali': openedDava.davali,
        'mevkii': openedDava.mevkii,
        'kalanSure': formattedDate,
        'profilResmi': openedDava.profilResmi,
        'davaKonusu': openedDava.davaKonusu,
        'kategori': openedDava.davaKategorisi,
        'isOpened': openedDava.isOpened,
        'openedAt': DateTime.now().toIso8601String(),
      });
      
      // ✅ Veritabanına kaydediliyor uygula
      // ✅ Kalıcı olarak saklanıyor uygula
      // ✅ Uygulama yeniden başlatıldığında korunuyor uygula
      
      // Grup ataması: Tüm gruplarda tetikle
      if (widget.userEmail != null) {
        final recipients = await HiveDatabaseService.pickGroupRecipients(
          widget.userEmail!,
          selectedGroup,
          count: 7,
          defendantEmail: openedDava.davali,
        );

        // 7 (seçilen grup) + 1 (dava açan) + 1 (dava açılan) kuralı
        final Set<String> recipientEmails = {
          ...recipients.map((r) => r.email),
        };
        // Dava açan
        recipientEmails.add(widget.userEmail!);
        // Dava açılan (varsa ve boş değilse)
        final davaliEmail = (openedDava.davali ?? '').trim();
        if (davaliEmail.isNotEmpty) {
          recipientEmails.add(davaliEmail);
        }

        // Gelen Davalar'a yaz
        for (final email in recipientEmails) {
          HiveDatabaseService.addIncomingDava(email, {
            'id': openedDava.id,
            'adi': openedDava.adi,
            'davaAdi': openedDava.adi, // ModernDavaCard için
            'davaKonusu': openedDava.davaKonusu,
            'davaci': openedDava.davaci, // Davacı verisi eklendi
            'davali': openedDava.davali,
            'displayName': openedDava.davaci, // ModernDavaCard için
            'userEmail': widget.userEmail ?? '', // ModernDavaCard için
            'mevkii': selectedGroup, // bilgi amaçlı
            'kalanSure': formattedDate,
            'profilResmi': openedDava.profilResmi,
            'openedAt': DateTime.now().toIso8601String(),
            // ModernDavaCard için engagement alanları
            'yorumSayisi': 0,
            'retweetSayisi': 0,
            'begeniSayisi': 0,
            'begenmemeSayisi': 0,
            'userLiked': false,
            'userDisliked': false,
            'userRetweeted': false,
            'yorumlar': [],
            'isOpened': false,
          });
        }
        // ignore: avoid_print
        print('Grup "$selectedGroup" alicilar: ${recipientEmails.join(', ')}');
      }
    } catch (e) {
      // Hata durumunda kullanıcıya bilgi ver
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Dava kaydedilirken hata oluştu: $e'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    _showDavaOpenedSuccessDialog(selectedGroup, formattedDate);
  }

  // Kullanıcının dava açılmasına izin verip vermediğini kontrol et
  Future<bool> _checkIfUserAllowsDava(String userName) async {
    try {
      final users = HiveDatabaseService.getAllRegistrations();
      final targetUser = users.firstWhere(
        (user) => user.judgeName.toLowerCase() == userName.toLowerCase(),
        orElse: () => throw Exception('Kullanıcı bulunamadı'),
      );
      
      final userSettings = await HiveDatabaseService.getOrCreateSettings(targetUser.email);
      return userSettings.privacySettings['genel_davaacilsin'] ?? true;
    } catch (e) {
      // Hata durumunda varsayılan olarak dava açılabilir kabul et
      return true;
    }
  }

  // Dava adı minimum karakter uyarısı dialog'u
  void _showDavaAdiMinLengthDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.warning,
                    size: 32,
                    color: Colors.orange[700],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dava Adı Çok Kısa! ⚠️',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dava adı en az 6 karakter olmalıdır.\n\nLütfen daha detaylı bir dava adı girin.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Tamam'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Dava açılmasına izin verilmeyen durumda gösterilecek dialog
  void _showDavaNotAllowedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                colors: [Colors.red.withOpacity(0.1), Colors.orange.withOpacity(0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Uyarı ikonu
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.block,
                    size: 32,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Başlık
                Text(
                  'Dava Açılamaz! ⚠️',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Mesaj
                Text(
                  '${_davaliController.text} kullanıcısı hesap ayarlarında "Bana Dava Açılsın" seçeneğini NO olarak ayarlamış.\n\nBu kullanıcıya dava açamazsınız.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                
                // Tamam butonu
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'TAMAM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modern alert gösterme fonksiyonu
  void _showModernAlert(BuildContext context, String title, String message, IconData icon, Color color) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 32,
                    color: color,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: color,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'TAMAM',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, DavaProvider>(
      builder: (context, authProvider, davaProvider, child) {
        // Düzenleme modunda kategori kontrolü yapma
        if (widget.editDava != null) {
          return _buildDavaAcPage(authProvider, davaProvider);
        }
    
    // Normal mod - kategori seçilmediyse boş sayfa göster
    if (widget.selectedCategory == null || widget.selectedSubCategory == null) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text(
            'DAVA AÇ',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
          backgroundColor: const Color(0xFF059669),
          elevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: Colors.white),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.category,
                size: 80,
                color: Colors.grey,
              ),
              SizedBox(height: 20),
              Text(
                'Kategori Seçimi Gerekli',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Dava açabilmek için önce bir kategori seçmelisiniz.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return _buildDavaAcPage(authProvider, davaProvider);
      },
    );
  }

  /// Dava Aç sayfasının ana içeriğini oluştur
  Widget _buildDavaAcPage(AuthProvider authProvider, DavaProvider davaProvider) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
                  onDateUpdate: (String date) {
                    // Ana dava aç ikonuna tıklandığında tarih güncelleme
                    setState(() {
                      davaList[0] = Dava(
                        id: davaList[0].id, // Mevcut ID'yi koru
                        adi: davaList[0].adi,
                        davali: davaList[0].davali,
                        mevkii: davaList[0].mevkii,
                        kalanSure: date,
                        profilResmi: davaList[0].profilResmi,
                        davaKonusu: davaList[0].davaKonusu, // Dava konusunu koru
                        davaKategorisi: davaList[0].davaKategorisi, // Kategori bilgisini koru
                        isOpened: davaList[0].isOpened,
                      );
                    });
                  },
                  onShowSavedDavalar: _showSavedDavalarDialog, // Kaydedilen davalar dialog'u için callback
                ),
              ),
              // ROW 4: Hamburger Iconu, Arama Çubuğu
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TreeMenuPageheadlines(
                  onMenuPressed: () {
                    setState(() {
                      showLeftIcons = !showLeftIcons;
                    });
                  },
                ),
              ),
              // ROW 5: 6 Icon Solda, Sağda Text Yazma Alanı (Scrollable with ListTile)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: showLeftIcons ? 60 : 0,
                      child: showLeftIcons
                          ? SingleChildScrollView(
                              child: Column(
                              children: [
                                // Adım 1: Sol menü ikonlarının padding'leri UI uygun olarak optimize edildi ve MdiIcons kullanımı eklendi
                                GestureDetector(
                                  onTap: () {
                                    _showSavedDavalarDialog();
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 4.0),
                                    child: Tooltip(
                                      message: 'Kaydedilen Davalar - Düzenlemek için tıklayın',
                                      child: Icon(
                                        MdiIcons.contentSaveOutline, // Dava Aç page de bu icon tıklanıldığında düzenlenmek üzere kaydedilen davalar için dialog kutusu açılır. Davala butonuna basılıp dava gönderilecek grup seçilirse artık o dava dialog kutusunda görünmez.
                                        size: 24,
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ),
                                ),
                                // Adım 2: İkinci icon padding'i optimize edildi ve MdiIcons kullanımı eklendi
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => ActigimDavalarPage(userEmail: widget.userEmail)),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                                    child: Icon(
                                      MdiIcons.briefcaseOutline,
                                      size: 24,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),
                                // Adım 3: Üçüncü icon padding'i optimize edildi ve MdiIcons kullanımı eklendi
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => const DelilleriIncelePage(),
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.fromLTRB(8.0, 4.0, 8.0, 4.0),
                                    child: Icon(
                                      MdiIcons.fileSearchOutline,
                                      size: 24,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ),

                              ],
                            ),
                          )
                          : const SizedBox.shrink(),
                    ),

                    Expanded(
                      child: Column(
                        children: [

                          // Dava listesi
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: davaList.length,
                            itemBuilder: (context, index) {
                              final dava = davaList[index];
                              final isExpanded = expandedCardIndex == index;

                              return FiveCardCaseInformation(
                                dava: dava,
                                isExpanded: isExpanded,
                                onTap: () {
                                  setState(() {
                                    if (expandedCardIndex == index) {
                                      expandedCardIndex = null;
                                    } else {
                                      expandedCardIndex = index;
                                    }
                                  });
                                },
                                davaliController: _davaliController,
                                filteredUsers: _filteredUsers,
                                showUserSuggestions: _showUserSuggestions,
                                onSelectUser: _selectUserSuggestion,
                                isWhoboomUser: isWhoboomUser,
                                userEmail: widget.userEmail,
                                onDateUpdate: (String date) {
                                  setState(() {
                                    davaList[index] = Dava(
                                      id: dava.id, // Mevcut ID'yi koru
                                      adi: dava.adi,
                                      davali: dava.davali,
                                      mevkii: dava.mevkii,
                                      kalanSure: date,
                                      profilResmi: dava.profilResmi,
                                      davaKonusu: dava.davaKonusu, // Dava konusunu koru
                                      davaKategorisi: dava.davaKategorisi, // Kategori bilgisini koru
                                      isOpened: dava.isOpened,
                                    );
                                  });
                                },
                                davaDetayController: _davaDetayController,
                                davaAdiController: _davaAdiController, // Dava adı controller'ı eklendi
                                canDavala: _canDavala,
                                onSaveDava: _saveDava,
                                onOpenDava: _openDava,
                                onCheckboxChanged: _onCheckboxChanged,
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class TreeMenuPageheadlines extends StatelessWidget {
  final VoidCallback? onMenuPressed;
  final String? title; // Başlık parametresi eklendi
  final bool isCollapsed; // Arayüzün küçültülüp küçültülmediğini kontrol eder
  final VoidCallback? onToggleCollapse; // Aç/kapa ok butonu için callback
  
  const TreeMenuPageheadlines({
    super.key, 
    this.onMenuPressed,
    this.title, // Başlık parametresi
    this.isCollapsed = false, // Varsayılan olarak açık
    this.onToggleCollapse, // Aç/kapa ok callback'i
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          icon: Icon(
            MdiIcons.menuOpen,
            size: 34,
            color: Colors.red,
          ),
          onPressed: onMenuPressed ?? () {
            print("Menu button pressed");
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              title ?? "Dava  Aç ", // Parametre varsa onu kullan, yoksa varsayılan
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        // Aç/kapa ok butonu - Sağa taşındı
        if (onToggleCollapse != null)
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
              size: 24,
              color: Colors.black,
            ),
            onPressed: onToggleCollapse,
            tooltip: isCollapsed ? 'Arayüzü Aç' : 'Arayüzü Kapat',
          ),
      ],
    );
  }
}

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final bool isExpanded;
  final VoidCallback? onTap;
  final TextEditingController davaliController;
  final List<String> filteredUsers;
  final bool showUserSuggestions;
  final Function(String) onSelectUser;
  final bool isWhoboomUser;
  final String? userEmail;
  final Function(String)? onDateUpdate;
  final TextEditingController davaDetayController;
  final TextEditingController davaAdiController; // Dava adı controller'ı eklendi
  final bool canDavala;
  final VoidCallback onSaveDava;
  final VoidCallback onOpenDava;
  final Function(bool?) onCheckboxChanged;

  const FiveCardCaseInformation({
    super.key, 
    required this.dava, 
    required this.isExpanded,
    this.onTap,
    required this.davaliController,
    required this.filteredUsers,
    required this.showUserSuggestions,
    required this.onSelectUser,
    required this.isWhoboomUser,
    this.userEmail,
    this.onDateUpdate,
    required this.davaDetayController,
    required this.davaAdiController, // Dava adı controller'ı eklendi
    required this.canDavala,
    required this.onSaveDava,
    required this.onOpenDava,
    required this.onCheckboxChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    child: userEmail != null 
                        ? FutureBuilder<String?>(
                            future: _getUserProfileImage(userEmail!),
                            builder: (context, snapshot) {
                              if (snapshot.hasData && snapshot.data != null) {
                                return Image.asset(
                                  snapshot.data!,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.asset(
                                      'lib/icons/07_profil_picture_davaci.png',
                                      width: 40,
                                      height: 40,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                );
                              } else {
                                return Image.asset(
                                  'lib/icons/07_profil_picture_davaci.png',
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                );
                              }
                            },
                          )
                        : Image.asset(
                            'lib/icons/07_profil_picture_davaci.png',
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                          ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Davacı bilgisi - Sabit metin + dinamik yargıç adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Davacı: ',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            FutureBuilder<String>(
                              future: _getDisplayName(userEmail),
                              builder: (context, snapshot) {
                                return Text(
                                  snapshot.data ?? 'Bilinmeyen Yargıç',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                    size: 24,
                  ),
                ],
              ),
              
              const SizedBox(height: 16),
              
              // Dava Adı
              _buildInfoRow('Dava Adı', dava.adi, true),
              const SizedBox(height: 8),
              
              // Dava Kategorisi - Sadece kategori seçilmişse göster
              if (dava.davaKategorisi.isNotEmpty) ...[
                _buildInfoRow('Kategori', dava.davaKategorisi, false),
                const SizedBox(height: 8),
              ],
              
              // Davalı - Özel satır
              _buildDavaliRow(),
              const SizedBox(height: 8),
              
              // Dava Açılış Tarihi - Sadece dava açıldıysa göster
              if (dava.isOpened) ...[
                _buildInfoRow('Dava Açılış Tarihi', dava.kalanSure, false),
                const SizedBox(height: 8),
              ],
              
              // Expanded Content - TAM GENİŞLİK
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  
                  // 🎨 Modern Dava Konusu Alanı - Maksimum Genişlik
                  Padding(
                    padding: const EdgeInsets.only(left: 0, right: 4),
                    child: ModernDavaContainer(
                      accentColor: const Color(0xFFFF6B35),
                      title: 'Dava Konusu',
                      icon: Icons.article,
                      child: Column(
                        children: [
                          ModernTextField(
                            controller: davaDetayController,
                            label: 'Davanızı Detaylı Anlatın',
                            hint: '🔥 Davanızın tüm detaylarını buraya yazın... Unutmayın, iyi bir anlatım daha fazla destek getirir!',
                            maxLines: 8,
                            maxLength: 285,
                            icon: MdiIcons.fileDocumentEdit,
                            enabled: !dava.isOpened,
                            accentColor: const Color(0xFFFF6B35),
                            onChanged: (value) {
                              print('📝 Dava konusu: ${value.length} karakter');
                            },
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CharacterCounterBadge(
                                current: davaDetayController.text.length,
                                max: 285,
                              ),
                              if (!dava.isOpened)
                                Flexible(
                                  child: Text(
                                    davaDetayController.text.length >= 285
                                        ? '✅ Harika! Yeterli detay'
                                        : '⚠️ ${285 - davaDetayController.text.length} karakter daha',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: davaDetayController.text.length >= 285
                                          ? Colors.green
                                          : Colors.orange,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                const SizedBox(height: 16),

                  //delil ekleme alanı
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: !dava.isOpened ? () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DelilEklePage(
                                  userEmail: userEmail,
                                  davaId: dava.id,
                                  davaAdi: dava.adi,
                                ),
                              ),
                            );
                          } : null,
                          icon: Icon(
                            Icons.add_circle_outline_outlined, 
                            size: 24,
                            color: !dava.isOpened ? Colors.white : Colors.grey[400],
                          ),
                          label: Text(
                            'DELİL EKLE ', 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: !dava.isOpened ? Colors.white : Colors.grey[400],
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !dava.isOpened ? Colors.blue : Colors.grey[300],
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: !dava.isOpened ? onSaveDava : null,
                        icon: const Icon(Icons.save, size: 18),
                        label: const Text('KAYDET'),
                        style: !dava.isOpened 
                            ? AppTheme.successButtonStyle 
                            : ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.textMuted,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                minimumSize: const Size(120, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (canDavala && !dava.isOpened) ? onOpenDava : null,
                        icon: const Icon(Icons.gavel_outlined, size: 18),
                        label: const Text('DAVALA'),
                        style: (canDavala && !dava.isOpened)
                            ? AppTheme.accentButtonStyle
                            : ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.textMuted,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                minimumSize: const Size(120, 48),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),


              ],
            ],
          ),
        ),
      ),
    );
  }

    Widget _buildDavaliRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const SizedBox(
              width: 76, // Sabit genişlik - diğer satırlarla aynı
              child: Text(
                'Davalı: ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: !dava.isOpened
                  ? SizedBox(
                      height: 48, // Sabit yükseklik - diğer satırlarla aynı
                      child: TextField(
                        controller: davaliController,
                        // Türkçe karakter desteği - tüm karakterleri kabul et
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
                        ],
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          hintText: isWhoboomUser ? 'üye ara... (en az 4 karakter)' : 'Bir isim yaz',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[400]!, width: 1.5),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.blue[600]!, width: 2),
                          ),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                          filled: true,
                          fillColor: Colors.grey[50],
                          prefixIcon: Container(
                            margin: const EdgeInsets.only(right: 8),
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                border: Border.all(color: Colors.green, width: 1.5),
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Transform.scale(
                                scale: 0.7,
                                child: Checkbox(
                                  value: isWhoboomUser,
                                  onChanged: onCheckboxChanged,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  activeColor: Colors.green,
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ),
                          ),
                          suffixIcon: isWhoboomUser 
                              ? const Icon(Icons.person_add, size: 18, color: Colors.green)
                              : null,
                        ),
                      ),
                    )
                  : SizedBox(
                      height: 48, // Sabit yükseklik - diğer satırlarla aynı
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[400]!, width: 1.5),
                        ),
                        child: Center(
                          child: Text(
                            dava.davali,
                            style: TextStyle(
                              fontSize: 14, 
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
        // Kullanıcı önerileri - sadece checkbox işaretli ve 4+ karakter yazıldığında göster
        if (showUserSuggestions && isWhoboomUser && !dava.isOpened) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: 84), // Davalı: yazısının hizası
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!, width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Başlık
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.person_search, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 6),
                      Text(
                        'Önerilen Üyeler (${filteredUsers.length})',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bilgilendirme mesajı - eğer hiç sonuç yoksa
                if (filteredUsers.isEmpty) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 16, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Bu isimle eşleşen üye bulunamadı veya dava açılmasına izin vermiyor',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange[700],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                // Öneriler listesi
                ...filteredUsers.map((userName) => InkWell(
                  onTap: () => onSelectUser(userName),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[200]!, width: 0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.green.withOpacity(0.1),
                          child: Icon(
                            Icons.person,
                            size: 16,
                            color: Colors.green[700],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                      ],
                    ),
                  ),
                )),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // Kullanıcının profil resmini al
  Future<String?> _getUserProfileImage(String email) async {
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(email);
      // Şimdilik varsayılan profil resmi döndürüyoruz
      // İleride kullanıcı modelinde profil resmi alanı eklenebilir
      return 'lib/icons/07_profil_picture_davaci.png';
    } catch (e) {
      return 'lib/icons/07_profil_picture_davaci.png';
    }
  }

  // Kullanıcının görünüm adını al (gizlilik ayarlarına göre)
  Future<String> _getDisplayName(String? userEmail) async {
    if (userEmail == null) return 'Bilinmeyen Yargıç';
    
    try {
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      if (user == null) return 'Bilinmeyen Yargıç';
      
      final settings = await HiveDatabaseService.getOrCreateSettings(userEmail);
      final displayType = settings.stringSettings['display_name_type'] ?? 'yargic_adim';
      
      switch (displayType) {
        case 'gizli_yargic':
          return 'Gizli Yargıç';
        case 'yargic_adim':
          return user.judgeName;
        case 'eposta':
          return userEmail;
        default:
          return user.judgeName;
      }
    } catch (e) {
      // Hata durumunda yargıç adını döndür
      final user = HiveDatabaseService.getRegistrationByEmail(userEmail);
      return user?.judgeName ?? 'Bilinmeyen Yargıç';
    }
  }

  Widget _buildInfoRow(String label, String value, bool isEditable) {
    return Row(
      children: [
        SizedBox(
          width: 76, // Sabit genişlik
          child: Text(
            '$label: ',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isEditable && !dava.isOpened
              ? TextField(
                  controller: label == 'Dava Adı' ? davaAdiController : null,
                  maxLength: label == 'Dava Adı' ? 171 : null,
                  // Türkçe karakter desteği - tüm karakterleri kabul et
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
                  ],
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  decoration: InputDecoration(
                    hintText: value,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.orange[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: const BorderRadius.all(Radius.circular(16)),
                      borderSide: BorderSide(color: Colors.orange[600]!, width: 2),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    counterText: '',
                    suffixIcon: label == 'Dava Adı'
                        ? CharacterCounterBadge(
                            current: davaAdiController.text.length,
                            max: 171,
                          )
                        : null,
                  ),
                )
              : Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.grey[100]!, Colors.grey[50]!],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: !dava.isOpened ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}

// GroupSelectionDialog widget'ı
class GroupSelectionDialog extends StatefulWidget {
  final String dialogTitle;
  final List<GroupOption> groupOptions;

  const GroupSelectionDialog({
    super.key,
    required this.dialogTitle,
    required this.groupOptions,
  });

  @override
  State<GroupSelectionDialog> createState() => _GroupSelectionDialogState();
}

class _GroupSelectionDialogState extends State<GroupSelectionDialog> {
  List<String> selectedGroups = [];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Başlık
            Text(
              widget.dialogTitle,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 20),
            
            // Grup seçenekleri
            ...widget.groupOptions.map((option) => _buildGroupOption(option)),
            
            const SizedBox(height: 20),
            
            // Butonlar
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('İptal'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: selectedGroups.isNotEmpty 
                        ? () => Navigator.of(context).pop(selectedGroups)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: selectedGroups.isNotEmpty ? Colors.blue : Colors.grey,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Gönder'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupOption(GroupOption option) {
    final isSelected = selectedGroups.contains(option.value);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          setState(() {
            if (isSelected) {
              selectedGroups.remove(option.value);
            } else {
              selectedGroups.add(option.value);
            }
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? option.color.withOpacity(0.1) : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? option.color : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: option.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  option.icon,
                  color: option.color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.value,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? option.color : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      option.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: option.color,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}