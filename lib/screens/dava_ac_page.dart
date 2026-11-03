import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart'; // TextInputFormatter için
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/dava_ac_case_card.dart';
import '../widgets/group_selection_dialog.dart';
export '../widgets/group_selection_dialog.dart' show GroupOption, GroupSelectionDialog;
export '../widgets/dava_ac_case_card.dart' show Dava, FiveCardCaseInformation;
import '../widgets/dava_gonderilecek_grup_dialog.dart';
import '../widgets/dava_opened_success_dialog.dart';
import '../widgets/modern_success_alert_dialog.dart';
import 'actigim_davalar_page.dart' hide Dava, FiveCardCaseInformation;
import 'home_page.dart' hide Dava;
import 'delilleri_incele_page.dart' hide Dava, FiveCardCaseInformation;
import '../services/hive_database_service.dart';
import '../utils/dialog_utils.dart';
import '../models/dava.dart' as dava_model; // Dava modeli için import eklendi (alias ile)
import '../providers/auth_provider.dart';
import '../providers/dava_provider.dart';
import '../utils/app_local_date_format.dart';
import '../utils/dava_map_utils.dart';
import '../utils/verified_party_utils.dart';
import '../services/verified_users_service.dart';

class DavaAcPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi
  final String? selectedCategory; // Seçilen kategori
  final String? selectedSubCategory; // Seçilen alt kategori
  final dava_model.Dava? editDava; // Düzenlenecek dava (yeni parametre)
  /// Kategori seçilince açıldığında true verilir; sayfa başlangıçta collapsed (üst arayüz küçük) açılır.
  final bool initialCollapsed;

  const DavaAcPage({
    super.key,
    this.userEmail,
    this.selectedCategory,
    this.selectedSubCategory,
    this.editDava, // Düzenleme modu için parametre eklendi
    this.initialCollapsed = false,
  });

  @override
  State<DavaAcPage> createState() => _DavaAcPageState();
}

class _DavaAcPageState extends State<DavaAcPage> {
  int commentCount = 0;
  int retweetCount = 0;
  int likeCount = 0;
  int dislikeCount = 0;
  int? expandedCardIndex = 0; // 0 = dava konusu kartı başlangıçta açık (expanded)
  bool showLeftIcons = false; // Sol ikonları gösterme durumu
  late bool isHeaderCollapsed; // Üst arayüzün küçültülüp küçültülmediği (Dava Aç sayfası)
  bool _highlightSaveIcon = false; // Kaydet ikonunu vurgulamak için (yanıp sönme)
  bool _hasPendingSavedDava = false; // En az bir düzenlenebilir/kaydedilmiş dava var mı?
  Timer? _saveIconBlinkTimer; // Kaydet ikonunun sürekli yanıp sönme timer'ı
  bool isWhoboomUser = true; // Checkbox için - WHObOOM kullanıcısı mı? (varsayılan seçili)
  final TextEditingController _davaliController = TextEditingController();
  final FocusNode _davaliFocusNode = FocusNode();
  final TextEditingController _davaDetayController = TextEditingController();
  final TextEditingController _davaAdiController = TextEditingController(); // Dava adı için controller
  List<String> _filteredUsers = [];
  bool _showUserSuggestions = false;
  bool _userJustSelected = false; // Öneriden seçim yapıldığında listeyi tekrar açma
  bool _canDavala = false; // DAVALA butonu aktif mi?
  List<Dava> _savedDavalar = []; // Kaydedilen davalar listesi
  String? _davalaDisabledReason;
  bool _showDavaAdiError = false;
  bool _showDavaliError = false;
  String? _davaAdiErrorText;
  String? _davaliErrorText;

  // Son açılan dava için Seyir Defteri modal bilgisi (HomePage açılınca modal açılacak)
  String? _lastOpenedDavaIdForSeyirDefteriModal;
  DateTime? _lastOpenedDavaOpenedAtForSeyirDefteriModal;
  String? _lastOpenedDavaAdiForSeyirDefteriModal;
  String? _lastOpenedDavaDavaciForSeyirDefteriModal;
  String? _lastOpenedDavaDavaliForSeyirDefteriModal;
  String? _lastOpenedDavaKategoriForSeyirDefteriModal;
  String? _lastOpenedDavaKonusuForSeyirDefteriModal;

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
    isHeaderCollapsed = widget.initialCollapsed;
    _davaliController.addListener(_onDavaliChanged);
    _davaliFocusNode.addListener(() {
      if (!_davaliFocusNode.hasFocus) {
        setState(() {
          _showUserSuggestions = false;
        });
      }
    });
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

    // Timer'ları durdur
    _saveIconBlinkTimer?.cancel();

    // Controller ve focus node'ları temizle
    _davaliController.dispose();
    _davaliFocusNode.dispose();
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
        HiveDatabaseService.saveDava(withDavaKategoriFields({
          'id': beklemedeDava.id,
          'davaAdi': beklemedeDava.davaAdi,
          'davaci': beklemedeDava.davaci,
          'davali': beklemedeDava.davali,
          'mevkii': beklemedeDava.mevkii,
          'kalanSure': beklemedeDava.kalanSure,
          'profilResmi': beklemedeDava.profilResmi,
          'davaKonusu': beklemedeDava.davaKonusu,
          'isOpened': beklemedeDava.isOpened,
          'savedAt': DateTime.now().toIso8601String(),
        }, beklemedeDava.kategori));

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
    // Öneri listesinden seçim yapıldıysa bu değişiklik için arama tetikleme
    if (_userJustSelected) {
      _userJustSelected = false;
      return;
    }

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

      // Kullanıcı yazmaya başladığında varsa davalı hata balonunu gizle
      if (_davaliErrorText != null && _davaliErrorText!.isNotEmpty) {
        _showDavaliError = false;
      }
    });

    // DAVALA butonunu kontrol et
    _checkDavalaButton();
  }

  // Kullanıcıları isme göre filtrele ve "Bana Dava Açılsın" ayarını kontrol et
  Future<void> _filterUsersByName(String searchText) async {
    try {
      final users = HiveDatabaseService.getAllRegistrations();
      final filteredUsers = <String>[];

      final openerJudgeName = _openerJudgeName();

      for (final user in users) {
        // Kullanıcı adı arama kriterine uyuyor mu?
        if (!user.judgeName.toLowerCase().contains(searchText.toLowerCase())) {
          continue;
        }

        // Mavi tiksiz kullanıcılar, mavi tikli ünlüleri öneri listesinde görmez.
        if (!VerifiedUsersService.canOpenCaseAgainst(
          openerJudgeName: openerJudgeName,
          defendantJudgeName: user.judgeName,
        )) {
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
          if (_userJustSelected) {
            _showUserSuggestions = false;
            _userJustSelected = false;
          } else {
            _showUserSuggestions = filteredUsers.isNotEmpty;
          }
        });
      }
    } catch (e) {
      // Hata durumunda boş liste göster
      if (mounted) {
        setState(() {
          _filteredUsers = [];
          _showUserSuggestions = false;
          _userJustSelected = false;
        });
      }
    }
  }

  // Kullanıcı önerisini seç
  void _selectUserSuggestion(String userName) {
    _userJustSelected = true;
    _davaliController.text = userName;
    if (mounted) FocusScope.of(context).unfocus();
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

      // Kullanıcı yazmaya başladığında varsa dava adı hata balonunu gizle
      if (_davaAdiErrorText != null && _davaAdiErrorText!.isNotEmpty) {
        _showDavaAdiError = false;
      }
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

  String _openerJudgeName() {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) return '';
    return HiveDatabaseService.getRegistrationByEmail(widget.userEmail!)
            ?.judgeName
            .trim() ??
        '';
  }

  bool _isBlockedFromSuingVerifiedCelebrity() {
    if (!isWhoboomUser) return false;
    final davali = _davaliController.text.trim();
    if (davali.isEmpty || davali == 'Davalı  adını gir ') return false;
    return !VerifiedPartyUtils.canUserOpenCaseAgainst(
      openerPartyDisplay: _openerJudgeName(),
      defendantPartyDisplay: davali,
    );
  }

  // DAVALA butonunun aktif olup olmadığını kontrol et
  void _checkDavalaButton() {
    final davaAdiUzunluk = _davaAdiController.text.isNotEmpty
        ? _davaAdiController.text.length
        : (davaList[0].adi.trim().isEmpty || davaList[0].adi == "Ad  ver " ? 0 : davaList[0].adi.length);

    final davaliSecildi = _davaliController.text.isNotEmpty && _davaliController.text != "Davalı  adını gir ";
    final davaKonusuUzunluk = _davaDetayController.text.length;
    final verifiedBlock = _isBlockedFromSuingVerifiedCelebrity();

    setState(() {
      _davalaDisabledReason = verifiedBlock
          ? 'Mavi tikli ünlülere yalnızca mavi tikli kullanıcılar dava açabilir.'
          : null;
      _canDavala = davaAdiUzunluk >= 6 &&
          davaliSecildi &&
          davaKonusuUzunluk >= 285 &&
          !verifiedBlock;
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

    // Güncel dava adını ve davalıyı doğrudan input'lardan al
    final rawDavaAdi = _davaAdiController.text.trim();
    final rawDavali = _davaliController.text.trim();

    // Dava adı zorunlu
    if (rawDavaAdi.isEmpty || rawDavaAdi == "Ad  ver ") {
      setState(() {
        _showDavaAdiError = true;
        _davaAdiErrorText = 'Davaya bir başlık vermelisin. Dava adını en az 6 karakter olacak şekilde doldur.';
      });
      return;
    }

    // Davalı zorunlu
    if (rawDavali.isEmpty || rawDavali == "Davalı  adını gir ") {
      setState(() {
        _showDavaliError = true;
        _davaliErrorText = 'Davalı bilgisini doldurmalısın. Davalı adını girmeden kaydedemezsin.';
      });
      return;
    }

    final guncelDavaAdi = rawDavaAdi;
    final guncelDavali = rawDavali;
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
    HiveDatabaseService.saveDava(withDavaKategoriFields({
      'id': savedDava.id,
      'adi': savedDava.adi,
      'davali': savedDava.davali,
      'mevkii': savedDava.mevkii,
      'kalanSure': savedDava.kalanSure,
      'profilResmi': savedDava.profilResmi,
      'davaKonusu': savedDava.davaKonusu,
      'davaci': savedDava.davaci,
      'isOpened': savedDava.isOpened,
    }, savedDava.davaKategorisi));

    setState(() {
      if (existingIndex != -1) {
        // Aynı ID'li dava varsa güncelle
        _savedDavalar[existingIndex] = savedDava;
      } else {
        // Yeni dava ise en üste ekle
        _savedDavalar.insert(0, savedDava);
      }
      // En az bir düzenlenebilir/kaydedilmiş dava olduğunu işaretle
      _hasPendingSavedDava = _savedDavalar.isNotEmpty;
    });

    // Dava kaydetme işlemi
    ModernSuccessAlertDialog.show(
      context,
      title: 'Başarılı!',
      message: existingIndex != -1
          ? 'Dava başarıyla güncellendi.'
          : 'Dava, daha sonra düzenlenmek üzere kaydedildi.',
      icon: Icons.save,
      color: Colors.green,
      onEdit: () {
        if (!mounted) return;
        final editModel = dava_model.Dava(
          id: savedDava.id,
          davaAdi: savedDava.adi,
          kategori: savedDava.davaKategorisi,
          davaci: savedDava.davaci,
          davali: savedDava.davali,
          mevkii: savedDava.mevkii,
          kalanSure: savedDava.kalanSure,
          profilResmi: savedDava.profilResmi,
          davaKonusu: savedDava.davaKonusu,
          isOpened: savedDava.isOpened,
        );
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (context) => DavaAcPage(
              userEmail: widget.userEmail,
              editDava: editModel,
              initialCollapsed: isHeaderCollapsed,
            ),
          ),
        );
      },
    );

    // Kaydetme sonrası arayüz:
    // - Üst arayüz açık kalsın (collapse false)
    // - Sol menü ikonları açık olsun
    // - Kaydedilen davalar ikonunu, düzenlenecek dava olduğu sürece yanıp söndür
    setState(() {
      isHeaderCollapsed = false;
      showLeftIcons = true;
    });

    _startSaveIconBlinkTimerIfNeeded();
  }

  /// Kayıtlı dava varken kaydet ikonunu yanıp söndürür (sayfa açılışında da çalışır).
  void _startSaveIconBlinkTimerIfNeeded() {
    _saveIconBlinkTimer?.cancel();
    if (!_hasPendingSavedDava) {
      if (mounted) {
        setState(() {
          _highlightSaveIcon = false;
        });
      }
      return;
    }
    if (mounted) {
      setState(() {
        _highlightSaveIcon = true;
      });
    }
    _saveIconBlinkTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted || !_hasPendingSavedDava) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _highlightSaveIcon = false;
          });
        }
        return;
      }
      setState(() {
        _highlightSaveIcon = !_highlightSaveIcon;
      });
    });
  }

  // Kaydedilen davaları göster - Global utility fonksiyonunu kullan
  Future<void> _showSavedDavalarDialog() async {
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

    await showSavedDavalarDialog(context, userEmail);
    if (!mounted) return;
    // Dialog kapandıktan sonra (silme/düzenleme sonrası) ikon durumunu senkronize et
    _loadSavedDavalarFromDatabase();
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
        davaKategorisi: resolveDavaKategoriFromMap(davaMap),
        isOpened: davaMap['isOpened'] ?? false,
      )).toList();
      _hasPendingSavedDava = _savedDavalar.isNotEmpty;
    });
    _startSaveIconBlinkTimerIfNeeded();
  }

  void _navigateToSeyirDefteri() {
    final email = widget.userEmail;
    if (email == null || email.isEmpty) return;
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => HomePage(userEmail: email),
      ),
    );
  }

  String? _resolveDavaliEmailFromOpenedDava(String davaId) {
    final openedDava = HiveDatabaseService.getOpenedDavalar().firstWhere(
      (d) => (d['id'] ?? d['davaId'] ?? '').toString() == davaId,
      orElse: () => <String, dynamic>{},
    );
    if (openedDava.isEmpty) return null;

    final rawDavali = (openedDava['davali'] ?? '').toString().trim();
    if (rawDavali.isEmpty) return null;

    if (rawDavali.contains('@')) {
      final byEmail = HiveDatabaseService.getRegistrationByEmail(rawDavali);
      return byEmail?.email ?? rawDavali;
    }

    final byJudgeName = HiveDatabaseService.getRegistrationByJudgeName(rawDavali);
    return byJudgeName?.email;
  }

  /// Dava açıldığında:
  /// - Davayı açan kişi
  /// - Sabit Grup19 kayıtlı kullanıcıları
  /// - Davanın davalısı
  /// için seyir defterine (`dava_share`) yayın ekler.
  Future<void> _publishOpenedDavaToSeyirDefteri(String davaId) async {
    final ownerEmail = widget.userEmail;
    if (ownerEmail == null || ownerEmail.isEmpty) return;

    final grup19Emails = HiveDatabaseService.getRegisteredGrup19MemberEmails();
    final davaliEmail = _resolveDavaliEmailFromOpenedDava(davaId);

    final targets = <String>{
      ownerEmail,
      ...grup19Emails,
      if (davaliEmail != null && davaliEmail.isNotEmpty) davaliEmail,
    };

    await Future.wait(
      targets.map((targetEmail) async {
        try {
          await HiveDatabaseService.shareDava(davaId, targetEmail);
        } catch (e) {
          // Kullanıcı bazında hata alırsak diğer hedefler çalışmaya devam etsin.
          print('⚠️ Seyir defterine paylaşım hatası: $targetEmail - $e');
        }
      }),
    );
  }

  // Kaydedilen davayı sil
  void _deleteSavedDava(int index, [Function? setDialogState]) {
    final davaToDelete = _savedDavalar[index];

    // Veritabanından sil
    HiveDatabaseService.deleteSavedDava(davaToDelete.id);

    setState(() {
      _savedDavalar.removeAt(index);
      _hasPendingSavedDava = _savedDavalar.isNotEmpty;
      // Düzenlenecek dava kalmadıysa yanıp sönmeyi durdur
      if (!_hasPendingSavedDava) {
        _saveIconBlinkTimer?.cancel();
        _highlightSaveIcon = false;
      }
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
    DavaGonderilecekGrupDialog.show(
      context,
      onConfirm: _processDavaOpening,
    );
  }

  // Dava açıldı başarı dialog'u göster
  void _showDavaOpenedSuccessDialog(String selectedGroup, String formattedDate) {
    DavaOpenedSuccessDialog.show(
      context,
      selectedGroup: selectedGroup,
      formattedDate: formattedDate,
      userEmail: widget.userEmail,
      onDavetEt: _showDavetGondermeDialog,
      onTamam: () {
        _loadSavedDavalarFromDatabase();
        _navigateToSeyirDefteri();
      },
    );
  }

  // Davet gönderildi uyarı dialog'unu göster
  void _showDavetGonderildiDialog(List<String> selectedGroups) {
    bool dialogDismissed = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
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
                      dialogDismissed = true;
                      Navigator.of(dialogContext).pop();
                      _navigateToSeyirDefteri();
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

    // 12 saniye sonra dialog'u otomatik kapat
    Future.delayed(const Duration(seconds: 12), () {
      if (mounted && !dialogDismissed && Navigator.canPop(context)) {
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
      final openerSettings = await HiveDatabaseService.getOrCreateSettings(widget.userEmail!);
      if (openerSettings.privacySettings['davet_dava'] ?? true) {
        HiveDatabaseService.addInvitation(widget.userEmail!, invitationForOpenerAndDefendant);
      }

      // Davalıya da davet gönder (eğer varsa)
      if (davaliEmail.isNotEmpty) {
        final defendantSettings = await HiveDatabaseService.getOrCreateSettings(davaliEmail);
        if (defendantSettings.privacySettings['davet_dava'] ?? true) {
          HiveDatabaseService.addInvitation(davaliEmail, invitationForOpenerAndDefendant);
        }
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
    // DAVA ATA'ya basıldığı anda (await öncesi): dava açılış zamanı — cihazın yerel saat dilimi.
    final DateTime davaAcilisAni = DateTime.now();
    final Locale davaLocale = Localizations.localeOf(context);

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
      if (_isBlockedFromSuingVerifiedCelebrity()) {
        _showVerifiedCelebrityBlockedDialog();
        return;
      }

      final canOpenDava = await _checkIfUserAllowsDava(_davaliController.text);
      if (!canOpenDava) {
        _showDavaNotAllowedDialog();
        return;
      }
    }

    if (!mounted) return;
    final formattedDate =
        AppLocalDateFormat.formatShortDateTimeForLocale(davaLocale, davaAcilisAni);

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

    // Seyir Defteri modalı için bilgileri sakla (HomePage açılınca modal açılır)
    _lastOpenedDavaIdForSeyirDefteriModal = openedDava.id;
    _lastOpenedDavaOpenedAtForSeyirDefteriModal = davaAcilisAni;
    _lastOpenedDavaAdiForSeyirDefteriModal = openedDava.adi;
    _lastOpenedDavaDavaciForSeyirDefteriModal = openedDava.davaci;
    _lastOpenedDavaDavaliForSeyirDefteriModal = openedDava.davali;
    _lastOpenedDavaKategoriForSeyirDefteriModal = openedDava.davaKategorisi;
    _lastOpenedDavaKonusuForSeyirDefteriModal = openedDava.davaKonusu;

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
      HiveDatabaseService.saveOpenedDava(withDavaKategoriFields({
        'id': openedDava.id,
        'davaAdi': openedDava.adi,
        'davaci': openedDava.davaci,
        'davali': openedDava.davali,
        'mevkii': openedDava.mevkii,
        'kalanSure': formattedDate,
        'profilResmi': openedDava.profilResmi,
        'davaKonusu': openedDava.davaKonusu,
        'isOpened': openedDava.isOpened,
        'openedAt': davaAcilisAni.toUtc().toIso8601String(),
        'createdAt': davaAcilisAni.toUtc().toIso8601String(),
        'lifecycleStatus': 'AwaitingRole',
        'isArchived': false,
        'isAppealable': false,
      }, openedDava.davaKategorisi));

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
          sameCountryOnly: true,
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
            'davaliEmail': davaliEmail.isNotEmpty ? davaliEmail : openedDava.davali,
            'displayName': openedDava.davaci, // ModernDavaCard için
            'userEmail': widget.userEmail ?? '', // ModernDavaCard için
            'mevkii': selectedGroup, // bilgi amaçlı
            'kalanSure': formattedDate,
            'profilResmi': openedDava.profilResmi,
            'openedAt': davaAcilisAni.toUtc().toIso8601String(),
            'createdAt': davaAcilisAni.toUtc().toIso8601String(),
            'lifecycleStatus': 'AwaitingRole',
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

    // Seyir defterine yalnızca (kendisi + Grup19 listesi) yayın ekle.
    await _publishOpenedDavaToSeyirDefteri(openedDava.id);
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

  void _showVerifiedCelebrityBlockedDialog() {
    final davaliName = _davaliController.text.trim();
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
                colors: [Colors.blue.withOpacity(0.1), Colors.indigo.withOpacity(0.05)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.verified,
                    size: 32,
                    color: Colors.blue.shade700,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Dava Açılamaz',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade800,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  davaliName.isNotEmpty
                      ? '"$davaliName" mavi tikli (ünlü) bir kullanıcıdır.\n\nMavi tik sahibi olmayan kullanıcılar, mavi tikli ünlülere dava açamaz.'
                      : 'Mavi tik sahibi olmayan kullanıcılar, mavi tikli ünlülere dava açamaz.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade700,
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
            backgroundColor: const Color(0xFFE0F5EF), // #169371 paletine uygun açık zemin
            appBar: AppBar(
              title: const Text(
                'DAVA AÇ',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  fontSize: 20,
                ),
              ),
              backgroundColor: const Color(0xFF169371), // 2 numaralı renk (#169371)
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

  /// Collapsed (tek satır) üst başlık satırı - Dava Aç sayfası
  Widget _buildCollapsedHeaderRow() {
    return CollapsedWbHeaderRow(
      title: 'Dava  Aç ',
      onExpandHeader: () => setState(() => isHeaderCollapsed = !isHeaderCollapsed),
      onToggleLeftNav: () => setState(() => showLeftIcons = !showLeftIcons),
    );
  }

  /// Dava Aç sayfasının ana içeriğini oluştur
  Widget _buildDavaAcPage(AuthProvider authProvider, DavaProvider davaProvider) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Üst Arayüz Bölümü - Kategori seçilince başlangıçta collapsed açılır
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: isHeaderCollapsed ? 40 : null,
                child: isHeaderCollapsed
                    ? _buildCollapsedHeaderRow()
                    : Column(
                  children: [
                    ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                        userEmail: widget.userEmail,
                        onDateUpdate: (String date) {
                          setState(() {
                            davaList[0] = Dava(
                              id: davaList[0].id,
                              adi: davaList[0].adi,
                              davali: davaList[0].davali,
                              mevkii: davaList[0].mevkii,
                              kalanSure: date,
                              profilResmi: davaList[0].profilResmi,
                              davaKonusu: davaList[0].davaKonusu,
                              davaKategorisi: davaList[0].davaKategorisi,
                              isOpened: davaList[0].isOpened,
                            );
                          });
                        },
                        onShowSavedDavalar: _showSavedDavalarDialog,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TreeMenuPageheadlines(
                        title: "Dava  Aç ",
                        isCollapsed: isHeaderCollapsed,
                        onToggleCollapse: () {
                          setState(() => isHeaderCollapsed = !isHeaderCollapsed);
                        },
                        onMenuPressed: () {
                          setState(() => showLeftIcons = !showLeftIcons);
                        },
                      ),
                    ),
                  ],
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
                                padding: const EdgeInsets.fromLTRB(8.0, 8.0, 8.0, 8.0),
                                child: Tooltip(
                                  message: 'Kaydedilen Davalar - Düzenlemek için tıklayın',
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: _highlightSaveIcon || _hasPendingSavedDava
                                          ? Colors.blue.withOpacity(0.08)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: _highlightSaveIcon || _hasPendingSavedDava
                                            ? Colors.blueAccent
                                            : Colors.transparent,
                                        width: _highlightSaveIcon ? 3 : (_hasPendingSavedDava ? 1.5 : 0),
                                      ),
                                      boxShadow: _highlightSaveIcon
                                          ? [
                                              BoxShadow(
                                                color: Colors.blue.withOpacity(0.45),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : [],
                                    ),
                                    child: Icon(
                                      MdiIcons.contentSaveOutline, // Dava Aç page de bu icon tıklanıldığında düzenlenmek üzere kaydedilen davalar için dialog kutusu açılır. Davala butonuna basılıp dava gönderilecek grup seçilirse artık o dava dialog kutusunda görünmez.
                                      size: 24,
                                      color: Colors.black54,
                                    ),
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
                                padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
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
                                padding: const EdgeInsets.fromLTRB(8.0, 48.0, 8.0, 8.0),
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
                                showDavaAdiError: _showDavaAdiError,
                                davaAdiErrorText: _davaAdiErrorText,
                                showDavaliError: _showDavaliError,
                                davaliErrorText: _davaliErrorText,
                                davaliFocusNode: _davaliFocusNode,
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


