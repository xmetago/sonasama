import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';
import '../services/hive_database_service.dart';
import '../providers/dava_provider.dart';

/// ✨ Modern Mobil Uyumlu Ceza Yönetim Widget'ı
/// 
/// Telefon uygulaması için optimize edilmiş, kullanıcı dostu ceza yönetim arayüzü
class CezaYonetimWidget extends StatefulWidget {
  final String? davaId;
  final String davaAdi;
  final String davaDavali;
  final String davaDavaci;
  final String? userEmail;

  const CezaYonetimWidget({
    super.key,
    this.davaId,
    required this.davaAdi,
    required this.davaDavali,
    required this.davaDavaci,
    this.userEmail,
  });

  @override
  State<CezaYonetimWidget> createState() => _CezaYonetimWidgetState();
}

class _CezaYonetimWidgetState extends State<CezaYonetimWidget>
    with TickerProviderStateMixin {
  // Kategori seçimi
  String activeCategory = 'Hazır Ceza';
  final List<String> categories = ['Hazır Ceza', 'Üyelerden'];

  // Seçim durumları
  int? selectedReadyIndex;
  String? selectedMember;
  int? selectedMemberPenaltyIndex;
  String? selectedPenaltyText;
  
  // Açılır menü durumları (hangi cezanın açıklaması açık)
  int? expandedReadyIndex; // Hazır cezalar için
  String? expandedMember; // Üye cezaları için
  int? expandedMemberPenaltyIndex; // Üye cezası index'i

  // Özel ceza yazma
  final TextEditingController _customTitleCtrl = TextEditingController(); // Ceza başlığı
  final TextEditingController _customDescriptionCtrl = TextEditingController(); // Ceza açıklaması
  final FocusNode _customTitleFocus = FocusNode();
  final FocusNode _customDescriptionFocus = FocusNode();
  bool _isCustomPenaltyValid = false;
  bool _isCustomPenaltySelected = false; // Özel ceza seçildi mi?
  bool _isPenaltyApplied = false; // Ceza uygulandı mı?

  // Tab controller
  TabController? _tabController;

  // Animasyon controller'ları
  AnimationController? _coffinAnimationController;

  // Beğeni durumları
  Map<String, int> _cezaBegenileri = <String, int>{};
  Map<String, bool> _userLikedCezalar = <String, bool>{};

  // Hazır ceza listesi
  final List<Map<String, String>> readyPenalties = <Map<String, String>>[
    {'name': 'Küçük Emrah Kaderi Yaşasın', 'description': 'Küçük Emrah filmindeki gibi zorlu bir kader yaşaması.'},
    {'name': 'Kuranı Baştan Sona Okusun', 'description': 'Kuran-ı Kerim\'i baştan sona okuyup anlaması gerekiyor.'},
    {'name': 'Ya Ölüm Ya İstiklal Desin', 'description': 'Kurtuluş Savaşı ruhunu anlaması için bu sözü hayat felsefesi haline getirmesi gerekiyor.'},
    {'name': '100 Kişiye İyilik Etsin', 'description': 'Toplam 100 kişiye iyilik yapması ve bunu belgelemek için fotoğraf çekmesi gerekiyor.'},
    {'name': 'Yaşlanınca Sokak Köpekleri Gibi Sokakta Ölsün', 'description': 'Bu ceza sembolik olarak verilmiştir. Kişinin yalnızlığını ve çaresizliğini hissetmesi amaçlanmıştır.'},
    {'name': 'Evlenmek Nasip Olmasın', 'description': 'Evlilik konusunda zorluklar yaşaması.'},
    {'name': 'Kendini Devredışı Bıraksın', 'description': 'Kendini toplumdan izole etmesi.'},
    {'name': 'Öldürülesiye Dövme', 'description': 'Sembolik olarak ağır bir ceza.'},
    {'name': 'Küçük Emrah Gibi Sürüne', 'description': 'Zorlu bir hayat yaşaması.'},
    {'name': 'İktidardan Sopa Yiye', 'description': 'Sosyal ve politik zorluklar yaşaması.'},
    {'name': '30 Kedi Besleme', 'description': '30 kediyi besleme sorumluluğu alması.'},
    {'name': '40 Yetimi Doyurma', 'description': '40 yetimi doyurma görevi alması.'},
    {'name': 'Tüm Sosyal Medya Hesapları Silinsin', 'description': 'Sosyal medya hesaplarını silmesi.'},
    {'name': '1 Yıl Boyunca Sadece Ekmek ve Su Yesin', 'description': 'Bir yıl boyunca sadece ekmek ve su ile beslenmesi.'},
    {'name': 'Her Gün 10 Sayfa Kitap Okusun', 'description': 'Her gün en az 10 sayfa kitap okuma zorunluluğu.'},
    {'name': '1 Ay Boyunca İnternetsiz Yaşasın', 'description': 'Bir ay boyunca internet kullanmaması.'},
    {'name': 'Tüm Günahlarını Sosyal Medyada İtiraf Etsin', 'description': 'Günahlarını sosyal medyada itiraf etmesi.'},
    {'name': 'Her Gün 5 Km Koşu Yapsın', 'description': 'Her gün 5 kilometre koşu yapması.'},
    {'name': '1 Hafta Boyunca Telefon Kullanmasın', 'description': 'Bir hafta boyunca telefon kullanmaması.'},
    {'name': 'Tüm Parasını Hayır Kurumuna Bağışlasın', 'description': 'Tüm parasını hayır kurumuna bağışlaması.'},
    // Hafif Cezalar (Göz Açıp Kapayıncaya Kadar)
    {'name': 'Sanal Mesafe', 'description': '1 ay boyunca kişinin sosyal medya hesaplarını, telefon rehberini ve oyun lobilerini göremeyeceksiniz. Aynı mahallede karşılaşırsanız, en yakın kediyi sevmekle meşgul olacaksınız.'},
    {'name': 'Kumbara Fonu', 'description': 'Kişiye, istediği bir çikolata veya dondurma türünü alacak kadar sembolik bir miktar (örneğin, 50 TL) ödeyeceksiniz. Afiyet olsun!'},
    {'name': 'Mikro Temizlik Operasyonu', 'description': 'Bulunduğunuz sokakta, yürüyüş yaparken en az 10 çöp toplayıp çöp kutusuna atacaksınız. Selfie ile kanıtlayacaksınız.'},
    {'name': 'Kişisel Gelişim Molası', 'description': 'İki hafta boyunca günde 15 dakika, nasıl yapılır videoları izleyecek veya bir hobi edinmeye çalışacaksınız. Örgü örmek serbest.'},
    {'name': 'Nazik Telafi Görevi', 'description': 'Yanlış anlaşılmaya neden olduğunuz kişiye, samimi bir özür mesajı yazacak ve onu güldürecek bir internet videosu paylaşacaksınız.'},
    {'name': 'Evdeki Kaşif Modu', 'description': '1 hafta sonu boyunca evden sadece acil durumlarda (bakkal, eczane) çıkabilirsiniz. Bu süreyi evde unuttuğunuz bir beceriyi (yemek yapmak gibi) geliştirerek geçireceksiniz.'},
    {'name': 'Trafik Canavarına İlahi', 'description': 'Trafikte yaptığınız kabalığın kefareti olarak, arabanızın içinde, yüksek sesle 10 dakika klasik müzik dinleyeceksiniz.'},
    {'name': 'Altın Bilet', 'description': 'Cezası affedildi! Bunun karşılığında, bugün içten bir iltifat etmek veya birine teşekkür etmek gibi mini bir iyilik yapacaksınız.'},
    {'name': 'Manevi Çikolata Tazmini', 'description': 'Kişinin kalbini kırdıysanız, gönlünü almak için bir kutu kaliteli çikolata alacaksınız.'},
    {'name': 'Buzdolabı Hacizi', 'description': 'Borcunuz olan kişinin buzdolabındaki en lezzetli tatlıyı veya içeceği, onun izniyle alacaksınız. (Not: Gerçek değil, sadece komik bir fikir!)'},
    // Orta Şiddetli Cezalar (Biraz Daha Ciddi Ama Yine de Komik)
    {'name': 'Mola Zili', 'description': '48 saatlik bir "dijital detoks" cezası aldınız. Tüm sosyal medya ve anlık mesajlaşma uygulamalarından uzak kalacaksınız.'},
    {'name': 'Ayakkabı Bağcığı İşkencesi', 'description': 'Bir hafta boyunca, her gün sürekli çözülen ayakkabı bağcıkları ile yaşayacaksınız. Dayanabilir misiniz?'},
    {'name': 'Sohbet Grubu Sürgünü', 'description': '3 gün boyunca en sevdiğiniz WhatsApp veya Discord grubundan atılacaksınız. Grupta neler olup bittiğini merak etmek cezanızın bir parçası.'},
    {'name': 'Sevdiklerinden Mahrum Kalma Cezası', 'description': 'Bir hafta boyunca en sevdiğiniz atıştırmalıktan (çikolata, cips, kola vb.) uzak duracaksınız.'},
    // Ağır Cezalar (Tamamen Hayali ve Abartılı)
    {'name': 'Sonsuz Dizi Kuyruğu', 'description': 'İzleme listenizdeki tüm dizileri bitirene kadar yeni bir diziye başlayamayacaksınız. Bu, gerçek bir müebbet hapisi kadar zorlu olabilir.'},
    {'name': 'Sosyal Medya İdamı', 'description': 'En komik ve utanç verici selfieniz, bir yakınınızın sosyal medya hesabından 24 saatliğine paylaşılacak.'},
    {'name': 'Pil Bitirme Cezası', 'description': 'Telefonunuzun şarjı %5\'in altına düşene kadar oyun oynamaya veya video izlemeye devam edeceksiniz. Telefonun kapanma anı, infaz anınız olacak.'},
    {'name': 'Dikensiz Kazık', 'description': 'Bir parti oyununda veya topluluk önünde konuşma yaparken, en az 5 dakika boyunca ayakta sabit bir şekilde duracak ve konuşmanızı bitirene kadar yerinizden kıpırdayamayacaksınız.'},
    {'name': 'Acılı Soslu Cezalandırma', 'description': 'Yemeğinize, dayanabildiğiniz en acı sosu ekleyip hepsini bitireceksiniz. Gözlerinizden yaşlar gelmesi, cezanın bir parçasıdır.'},
    {'name': 'Muz Soyma Performansı', 'description': 'Tek bir muzu, kabuğu hiç parçalanmadan ve mükemmel bir şekilde soymaya çalışacaksınız. Başarısız olursanız, muzu kabuğuyla yemek zorunda kalacaksınız.'},
    {'name': 'Sabır Testi', 'description': 'IKEA\'dan aldığınız bir mobilyayı, kullanma kılavuzuna hiç bakmadan kurmaya çalışacaksınız. Gerçek bir çile!'},
  ];

  // Üye cezaları (sabit)
  final Map<String, Map<String, dynamic>> _staticMemberPenalties = <String, Map<String, dynamic>>{
    'whodoom': {
      'avatar': 'W',
      'hashtag': '#whoBOOM',
      'penalties': <String>[
        'Küçük emrah kaderi yaşasın',
        'Kuranı baştan sona okusun',
        'Ya ölüm ya istiklal desin',
      ],
    },
    'nasrullah_keskin': {
      'avatar': 'N',
      'hashtag': '#nasrullahBOOM',
      'penalties': <String>[
        '100 kişiye iyilik etsin',
        'Yaşlanınca sokak köpekleri gibi sokakta ölsün',
        'Evlenmek nasip olmasın',
        'Kendini devredışı bıraksın',
      ],
    },
    'cheguevera_del': {
      'avatar': 'C',
      'hashtag': '#chegueveraBOOM',
      'penalties': <String>[
        'Öldürülesiye dövme',
        'Küçük Emrah gibi sürüne',
        'İktidardan sopa yiye',
        '30 kedi besleme',
        '40 yetimi doyurma',
      ],
    },
  };

  // Özel cezalar (kullanıcıların oluşturduğu cezalar)
  final Map<String, Map<String, dynamic>> _customMemberPenalties = <String, Map<String, dynamic>>{};

  // Üye cezaları getter (statik + özel cezalar birleşik)
  Map<String, Map<String, dynamic>> get memberPenalties {
    final Map<String, Map<String, dynamic>> combined = <String, Map<String, dynamic>>{};
    
    // Önce statik cezaları ekle
    combined.addAll(_staticMemberPenalties);
    
    // Sonra özel cezaları ekle (üzerine yazabilir veya yeni kullanıcılar ekleyebilir)
    for (final entry in _customMemberPenalties.entries) {
      if (combined.containsKey(entry.key)) {
        // Kullanıcı zaten varsa, cezalarını ekle
        final existingPenalties = combined[entry.key]!['penalties'] as List<String>;
        final newPenalties = entry.value['penalties'] as List<String>;
        combined[entry.key]!['penalties'] = <String>[...existingPenalties, ...newPenalties];
      } else {
        // Yeni kullanıcı ekle
        combined[entry.key] = entry.value;
      }
    }
    
    return combined;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _coffinAnimationController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
    _customTitleCtrl.addListener(_onCustomPenaltyChanged);
    _customDescriptionCtrl.addListener(_onCustomPenaltyChanged);
    _loadCezaBegenileri();
  }

  /// Ceza beğenilerini yükle
  Future<void> _loadCezaBegenileri() async {
    try {
      final begeniler = await HiveDatabaseService.getAllCezaBegenileri();
      final userEmail = widget.userEmail ?? '';
      final userLiked = <String, bool>{};
      
      for (final cezaName in begeniler.keys) {
        final isLiked = await HiveDatabaseService.isCezaLikedByUser(cezaName, userEmail);
        userLiked[cezaName] = isLiked;
      }
      
      setState(() {
        _cezaBegenileri = begeniler;
        _userLikedCezalar = userLiked;
      });
    } catch (e) {
      print('❌ Ceza beğenileri yüklenirken hata: $e');
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _coffinAnimationController?.dispose();
    _customTitleCtrl.dispose();
    _customDescriptionCtrl.dispose();
    _customTitleFocus.dispose();
    _customDescriptionFocus.dispose();
    super.dispose();
  }

  void _onCustomPenaltyChanged() {
    final titleLength = _customTitleCtrl.text.trim().length;
    final descriptionLength = _customDescriptionCtrl.text.trim().length;
    setState(() {
      // Başlık en az 3 karakter, açıklama en az 15 karakter olmalı
      _isCustomPenaltyValid = titleLength >= 3 && 
                              titleLength <= 100 && 
                              descriptionLength >= 15 && 
                              descriptionLength <= 400;
    });
  }

  void _selectReady(int index) {
    final penalty = readyPenalties[index];
    final cezaName = penalty['name']!;
    
    setState(() {
      // Aynı cezaya tıklanırsa açılır menüyü kapat/aç
      if (expandedReadyIndex == index) {
        expandedReadyIndex = null;
      } else {
        expandedReadyIndex = index;
      }
      
      selectedReadyIndex = index;
      selectedMemberPenaltyIndex = null;
      selectedMember = null;
      selectedPenaltyText = cezaName;
      // Üye cezaları açılır menüsünü kapat
      expandedMember = null;
      expandedMemberPenaltyIndex = null;
    });
  }

  void _selectMemberPenalty(String member, int idx) {
    final penaltyText = memberPenalties[member]!['penalties'][idx] as String;
    
    setState(() {
      // Aynı cezaya tıklanırsa açılır menüyü kapat/aç
      if (expandedMember == member && expandedMemberPenaltyIndex == idx) {
        expandedMember = null;
        expandedMemberPenaltyIndex = null;
      } else {
        expandedMember = member;
        expandedMemberPenaltyIndex = idx;
      }
      
      selectedMember = member;
      selectedMemberPenaltyIndex = idx;
      selectedReadyIndex = null;
      selectedPenaltyText = penaltyText;
      // Hazır cezalar açılır menüsünü kapat
      expandedReadyIndex = null;
    });
  }

  void _saveCustomPenalty() {
    final title = _customTitleCtrl.text.trim();
    
    if (_isCustomPenaltyValid) {
      // Kullanıcı email'ini al (yoksa "guest" kullan)
      final userEmail = widget.userEmail ?? 'guest';
      final userName = userEmail.split('@').first; // Email'den kullanıcı adını çıkar
      
      setState(() {
        selectedPenaltyText = title; // Başlık seçilen ceza olarak gösterilir
        selectedReadyIndex = null;
        selectedMemberPenaltyIndex = null;
        selectedMember = null;
        _isCustomPenaltySelected = true;
        
        // Özel cezayı "Üyelerden" kısmına ekle
        if (_customMemberPenalties.containsKey(userEmail)) {
          // Kullanıcı zaten varsa, cezasını ekle
          final existingPenalties = _customMemberPenalties[userEmail]!['penalties'] as List<String>;
          if (!existingPenalties.contains(title)) {
            existingPenalties.add(title);
          }
        } else {
          // Yeni kullanıcı ekle
          final avatar = userName.isNotEmpty ? userName[0].toUpperCase() : 'U';
          _customMemberPenalties[userEmail] = {
            'avatar': avatar,
            'hashtag': '#${userName}BOOM',
            'penalties': <String>[title],
          };
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Özel cezanız kaydedildi, seçildi ve "Üyelerden" kısmına eklendi.'),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Özel cezayı güncelle
  void _updateCustomPenalty() {
    final title = _customTitleCtrl.text.trim();
    final oldTitle = selectedPenaltyText;
    
    if (_isCustomPenaltyValid && _isCustomPenaltySelected && !_isPenaltyApplied) {
      final userEmail = widget.userEmail ?? 'guest';
      
      setState(() {
        selectedPenaltyText = title;
        
        // "Üyelerden" kısmındaki cezayı güncelle
        if (_customMemberPenalties.containsKey(userEmail)) {
          final penalties = _customMemberPenalties[userEmail]!['penalties'] as List<String>;
          final index = penalties.indexOf(oldTitle ?? '');
          if (index != -1) {
            penalties[index] = title;
          }
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: <Widget>[
              Icon(Icons.update, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text('Özel cezanız güncellendi ve "Üyelerden" kısmında da güncellendi.'),
              ),
            ],
          ),
          backgroundColor: Colors.blue.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Ceza beğenisi toggle
  Future<void> _toggleCezaBegeni(String cezaName) async {
    if (widget.userEmail == null || widget.userEmail!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Beğeni için giriş yapmanız gerekiyor.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      await HiveDatabaseService.toggleCezaBegeni(cezaName, widget.userEmail!);
      await _loadCezaBegenileri();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Beğeni güncellenirken hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _applyPenalty() {
    if (selectedPenaltyText == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: <Widget>[
              Icon(Icons.error, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('Lütfen önce bir ceza seçiniz.'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: <Widget>[
            Icon(Icons.gavel, color: Colors.red.shade700, size: 24),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('Ceza Uygula'),
            ),
          ],
        ),
        content: Text('"$selectedPenaltyText" cezası uygulanacak. Onaylıyorsunuz?'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              
              // Ceza verisini veritabanına kaydet (Provider üzerinden - senkronizasyon için)
              if (widget.davaId != null && widget.davaId!.isNotEmpty && 
                  widget.userEmail != null && widget.userEmail!.isNotEmpty &&
                  selectedPenaltyText != null) {
                try {
                  // Provider üzerinden kaydet (senkronizasyon için)
                  final davaProvider = Provider.of<DavaProvider>(context, listen: false);
                  await davaProvider.updateCezaForDava(
                    davaId: widget.davaId!,
                    userEmail: widget.userEmail!,
                    cezaText: selectedPenaltyText!,
                  );
                  print('✅ [CezaYonetimWidget] Ceza Provider üzerinden kaydedildi');
                } catch (e) {
                  print('❌ Ceza kaydedilirken hata: $e');
                }
              }
              
              setState(() {
                _isPenaltyApplied = true;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: <Widget>[
                      const Icon(Icons.check_circle, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text('✅ Veritabanına kaydediliyor...\n'
                            '✅ Kalıcı olarak saklanıyor...\n'
                            '✅ Uygulama yeniden başlatıldığında korunuyor...\n'
                            'Ceza başarıyla uygulandı: $selectedPenaltyText'),
                      ),
                    ],
                  ),
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Onayla'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.98,
      builder: (BuildContext context, ScrollController scrollController) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.grey.shade50,
                Colors.blue.shade50,
                Colors.purple.shade50,
              ],
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              _buildHeader(),
              if (_tabController != null) ...[
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController!,
                    children: <Widget>[
                      _buildCezaSecimiTab(scrollController),
                      _buildOzelCezaTab(scrollController),
                      _buildSecilenCezaTab(scrollController),
                    ],
                  ),
                ),
              ] else
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                ),
              _buildBottomActions(),
            ],
          ),
        );
      },
    );
  }

  /// Kompakt başlık
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            Color(0xFF2c3e50),
            Color(0xFF34495e),
          ],
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              MdiIcons.gavel,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Ceza Yönetim',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white, size: 22),
            onPressed: () => Navigator.of(context).pop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  /// Tab bar
  Widget _buildTabBar() {
    if (_tabController == null) {
      return const SizedBox.shrink();
    }
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController!,
        labelColor: Colors.blue.shade700,
        unselectedLabelColor: Colors.grey.shade600,
        indicatorColor: Colors.blue.shade700,
        indicatorWeight: 3,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const <Widget>[
          Tab(
            icon: Icon(Icons.list, size: 20),
            text: 'Ceza Seç',
          ),
          Tab(
            icon: Icon(Icons.edit, size: 20),
            text: 'Özel Ceza',
          ),
          Tab(
            icon: Icon(Icons.check_circle, size: 20),
            text: 'Seçilen',
          ),
        ],
      ),
    );
  }

  /// Ceza seçimi tab'ı
  Widget _buildCezaSecimiTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Kategori seçici
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: _buildCategoryButton('Hazır Ceza', 0),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCategoryButton('Üyelerden', 1),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Ceza listesi
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: activeCategory == 'Hazır Ceza'
                ? _buildReadyList()
                : _buildMembersList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryButton(String label, int index) {
    final bool isActive = activeCategory == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          activeCategory = label;
          selectedReadyIndex = null;
          selectedMemberPenaltyIndex = null;
          selectedMember = null;
          // Açılır menüleri kapat
          expandedReadyIndex = null;
          expandedMember = null;
          expandedMemberPenaltyIndex = null;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: <Color>[
                    Colors.blue.shade600,
                    Colors.purple.shade600,
                  ],
                )
              : null,
          color: isActive ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isActive ? Colors.white : Colors.grey.shade700,
            fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildReadyList() {
    // Beğeni sayısına göre sıralama
    final List<Map<String, String>> sortedPenalties = List<Map<String, String>>.from(readyPenalties);
    sortedPenalties.sort((a, b) {
      final aName = a['name']!;
      final bName = b['name']!;
      final aLikes = _cezaBegenileri[aName] ?? 0;
      final bLikes = _cezaBegenileri[bName] ?? 0;
      if (aLikes != bLikes) {
        return bLikes.compareTo(aLikes); // Yüksek beğeni önce
      }
      // Beğeni sayısı eşitse orijinal sırayı koru
      return readyPenalties.indexOf(a).compareTo(readyPenalties.indexOf(b));
    });

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: sortedPenalties.length,
      separatorBuilder: (BuildContext context, int index) => Divider(
        height: 1,
        color: Colors.grey.shade200,
      ),
      itemBuilder: (BuildContext context, int index) {
        final penalty = sortedPenalties[index];
        final cezaName = penalty['name']!;
        final originalIndex = readyPenalties.indexOf(penalty);
        final bool selected = selectedReadyIndex == originalIndex;
        final int likeCount = _cezaBegenileri[cezaName] ?? 0;
        final bool isLiked = _userLikedCezalar[cezaName] ?? false;
        
        final bool isExpanded = expandedReadyIndex == originalIndex;
        final String? description = penalty['description'];
        
        return Column(
          children: <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _selectReady(originalIndex),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected ? Colors.blue.shade50 : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: <Color>[
                              Colors.blue.shade400,
                              Colors.purple.shade400,
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            (index + 1).toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          cezaName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                            color: selected ? Colors.blue.shade900 : Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Beğeni butonu
                      GestureDetector(
                        onTap: () => _toggleCezaBegeni(cezaName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isLiked ? Colors.red.shade50 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isLiked ? Colors.red.shade300 : Colors.grey.shade300,
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isLiked ? Colors.red.shade700 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                likeCount.toString(),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isLiked ? Colors.red.shade700 : Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        isExpanded ? Icons.expand_less : Icons.expand_more,
                        color: Colors.grey.shade600,
                        size: 20,
                      ),
                      if (selected) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.check_circle,
                          color: Colors.blue.shade700,
                          size: 20,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            // Açılır açıklama kutusu
            if (isExpanded && description != null && description.isNotEmpty)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                margin: const EdgeInsets.only(top: 4, left: 44, right: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: <Color>[
                      Colors.blue.shade50,
                      Colors.purple.shade50,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.blue.shade200,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildMembersList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: memberPenalties.length,
      separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 8),
      itemBuilder: (BuildContext context, int index) {
        final String member = memberPenalties.keys.elementAt(index);
        final Map<String, dynamic> memberData = memberPenalties[member]!;
        final List<String> penalties = memberData['penalties'] as List<String>;
        return Container(
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ExpansionTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.purple.shade400,
                    Colors.blue.shade400,
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  memberData['avatar'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            title: Text(
              member,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            children: <Widget>[
              ...penalties.asMap().entries.map((MapEntry<int, String> entry) {
                final int idx = entry.key;
                final String txt = entry.value;
                final bool selected = (selectedMember == member &&
                    selectedMemberPenaltyIndex == idx);
                final bool isExpanded = (expandedMember == member &&
                    expandedMemberPenaltyIndex == idx);
                
                return Column(
                  children: <Widget>[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectMemberPenalty(member, idx),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 16,
                          ),
                          decoration: BoxDecoration(
                            color: selected ? Colors.purple.shade50 : Colors.transparent,
                          ),
                          child: Row(
                            children: <Widget>[
                              if (_coffinAnimationController != null)
                                RotationTransition(
                                  turns: _coffinAnimationController!,
                                  child: Icon(
                                    MdiIcons.coffin,
                                    size: 18,
                                    color: Colors.purple.shade600,
                                  ),
                                )
                              else
                                Icon(
                                  MdiIcons.coffin,
                                  size: 18,
                                  color: Colors.purple.shade600,
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  txt,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: selected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: selected
                                        ? Colors.purple.shade900
                                        : Colors.grey.shade800,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.expand_less : Icons.expand_more,
                                color: Colors.grey.shade600,
                                size: 18,
                              ),
                              if (selected) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.purple.shade700,
                                  size: 18,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Açılır bilgilendirme kutusu
                    if (isExpanded)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.only(top: 4, left: 44, right: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              Colors.purple.shade50,
                              Colors.blue.shade50,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.purple.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.purple.shade700,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '$txt cezası üye tarafından önerilmiştir.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade800,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                );
              }),
            ],
          ),
        );
      },
    );
  }

  /// Özel ceza tab'ı
  Widget _buildOzelCezaTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.orange.shade50,
                  Colors.pink.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.lightbulb_outline, color: Colors.orange.shade700, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Aklınızdaki Ceza',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade900,
                    ),
                  ),
                ),
                if (_isCustomPenaltySelected && !_isPenaltyApplied)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.edit, size: 14, color: Colors.green.shade800),
                        const SizedBox(width: 4),
                        Text(
                          'Düzenlenebilir',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade800,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // 1. Ceza Başlığı
          Text(
            '1. Ceza Başlığı',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPenaltyApplied ? Colors.grey.shade200 : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              controller: _customTitleCtrl,
              focusNode: _customTitleFocus,
              maxLines: 1,
              maxLength: 100,
              enabled: !_isPenaltyApplied,
              readOnly: _isPenaltyApplied,
              style: TextStyle(
                fontSize: 14,
                color: _isPenaltyApplied ? Colors.grey.shade600 : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _isPenaltyApplied 
                    ? 'Ceza uygulandı, artık düzenlenemez'
                    : 'Ceza başlığını girin (en az 3, en fazla 100 karakter)',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          // 2. Ceza Açıklaması
          Text(
            '2. Ceza Açıklaması',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isPenaltyApplied ? Colors.grey.shade200 : Colors.grey.shade300,
              ),
            ),
            child: TextField(
              controller: _customDescriptionCtrl,
              focusNode: _customDescriptionFocus,
              minLines: 4,
              maxLines: 8,
              maxLength: 400,
              enabled: !_isPenaltyApplied,
              readOnly: _isPenaltyApplied,
              style: TextStyle(
                fontSize: 14,
                color: _isPenaltyApplied ? Colors.grey.shade600 : Colors.black87,
              ),
              decoration: InputDecoration(
                hintText: _isPenaltyApplied 
                    ? 'Ceza uygulandı, artık düzenlenemez'
                    : 'Ceza açıklamasını girin (en az 15, en fazla 400 karakter)',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(16),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _customTitleCtrl.text.length >= 3 && _customTitleCtrl.text.length <= 100
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Başlık: ${_customTitleCtrl.text.length}/100',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _customTitleCtrl.text.length >= 3 && _customTitleCtrl.text.length <= 100
                            ? Colors.green.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _customDescriptionCtrl.text.length >= 15 && _customDescriptionCtrl.text.length <= 400
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Açıklama: ${_customDescriptionCtrl.text.length}/400',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _customDescriptionCtrl.text.length >= 15 && _customDescriptionCtrl.text.length <= 400
                            ? Colors.green.shade800
                            : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isCustomPenaltySelected && !_isPenaltyApplied)
                ElevatedButton.icon(
                  icon: const Icon(Icons.update, size: 18),
                  label: const Text('Güncelle'),
                  onPressed: _isCustomPenaltyValid ? _updateCustomPenalty : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                )
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.save, size: 18),
                  label: const Text('Kaydet'),
                  onPressed: _isCustomPenaltyValid && !_isPenaltyApplied 
                      ? _saveCustomPenalty 
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Seçilen ceza tab'ı
  Widget _buildSecilenCezaTab(ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  Colors.green.shade50,
                  Colors.teal.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.green.shade300, width: 2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 24),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Seçilen Ceza',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    selectedPenaltyText ?? 'Henüz bir ceza seçilmedi',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: selectedPenaltyText != null
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: selectedPenaltyText != null
                          ? Colors.green.shade900
                          : Colors.grey.shade600,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  /// Alt aksiyon butonları
  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: <Widget>[
            Expanded(
              child: OutlinedButton.icon(
                icon: const Icon(Icons.close, size: 18),
                label: const Text('İptal'),
                onPressed: () => Navigator.of(context).pop(),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.gavel, size: 18),
                label: const Text('Ceza Uygula'),
                onPressed: _applyPenalty,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

