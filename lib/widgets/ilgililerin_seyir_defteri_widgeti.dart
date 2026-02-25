import 'package:flutter/material.dart';
import '../services/dava_consensus_service.dart';
import '../services/hive_database_service.dart';
import '../services/dava_timer_service.dart';

class IlgililerinSeyirDefteriWidgeti extends StatefulWidget {
  final String? davaId; // Dava ID'si
  final String? userEmail; // Kullanıcı email'i
  final String? davaAdi; // Dava adı
  final String? davaci; // Davacı
  final String? davali; // Davalı
  final String? kategori; // Dava kategorisi
  final String? davaKonusu; // Dava konusu
  final DateTime? openedAt; // Dava açılış tarihi
  final VoidCallback? onClose; // Widget kapatıldığında çağrılacak callback

  const IlgililerinSeyirDefteriWidgeti({
    super.key,
    this.davaId,
    this.userEmail,
    this.davaAdi,
    this.davaci,
    this.davali,
    this.kategori,
    this.davaKonusu,
    this.openedAt,
    this.onClose,
  });

  @override
  State<IlgililerinSeyirDefteriWidgeti> createState() => _IlgililerinSeyirDefteriWidgetiState();
}

class _IlgililerinSeyirDefteriWidgetiState extends State<IlgililerinSeyirDefteriWidgeti> {
  bool showDetails = true;
  bool isLiked = false;
  bool isDisliked = false;
  bool isRetweeted = false;
  
  int yorumSayisi = 0;
  int retweetSayisi = 0;
  int begeniSayisi = 0;
  int begenmemeSayisi = 0;
  
  List<Map<String, dynamic>> _participants = []; // Tüm katılımcılar (status bilgisiyle)
  List<Map<String, dynamic>> _rejecters = []; // Red eden kişiler
  bool _isLoadingRejecters = false;
  
  // Dava bilgileri
  String _davaAdi = '';
  String _davaci = '';
  String _davali = '';
  String _kategori = '';
  String _davaKonusu = '';
  DateTime? _openedAt;
  
  List<Map<String, String>> get caseDetails {
    return [
      if (_kategori.isNotEmpty) {"label": "Dava kategorisi", "value": _kategori},
      if (_davaci.isNotEmpty) {"label": "Davacı", "value": _davaci},
      if (_davali.isNotEmpty) {"label": "Davalı", "value": _davali},
    ];
  }

  final List<String> expandableItems = [
    "Davayı Yorumlamayı Kabul ve Red Edenler",
    "Davacı Haklı mı Haksız mı",
    "Deliller Hakkında",
    "Uygun Görülen Cezalar",
    "Hüküm Veren-Vermeyen",
    "Uzlaşma Var mı?",
    "Ceza Onayı",
    "Hediyeler",
    "Hediyeler (Gecikmeli)",
    "Ceza Onayı (Kişisel)",
    "Çekilen var mı (Kişisel)"
  ];

  final List<String> kisiSorular = [
    "19.Kişi ne dedi",
    "Destekleyen 19.Kişi ne dedi",
    "Kınayan 19.Kişi ne dedi",
    "Yorumlayan 19.Kişi ne dedi",
  ];

  @override
  void initState() {
    super.initState();
    _loadDavaInfo();
    if (widget.davaId != null && widget.davaId!.isNotEmpty) {
      _loadParticipants();
    }
  }
  
  /// Dava bilgilerini yükle
  void _loadDavaInfo() {
    // Önce widget parametrelerinden yükle
    _davaAdi = widget.davaAdi ?? '';
    _davaci = widget.davaci ?? '';
    _davali = widget.davali ?? '';
    _kategori = widget.kategori ?? '';
    _davaKonusu = widget.davaKonusu ?? '';
    _openedAt = widget.openedAt;
    
    // Eğer davaId varsa ve bilgiler eksikse, veritabanından yükle
    if (widget.davaId != null && widget.davaId!.isNotEmpty) {
      if (_davaAdi.isEmpty || _davaci.isEmpty || _davali.isEmpty) {
        _loadDavaInfoFromDatabase();
      }
    }
  }
  
  /// Dava bilgilerini veritabanından yükle
  void _loadDavaInfoFromDatabase() {
    try {
      // Önce açılan davalarda ara
      final openedDavalar = HiveDatabaseService.getOpenedDavalar();
      final dava = openedDavalar.firstWhere(
        (d) => d['id'] == widget.davaId,
        orElse: () => <String, dynamic>{},
      );
      
      if (dava.isNotEmpty) {
        setState(() {
          _davaAdi = _davaAdi.isEmpty 
              ? (dava['davaAdi'] ?? dava['adi'] ?? '').toString().trim()
              : _davaAdi;
          _davaci = _davaci.isEmpty 
              ? (dava['davaci'] ?? '').toString().trim()
              : _davaci;
          _davali = _davali.isEmpty 
              ? (dava['davali'] ?? '').toString().trim()
              : _davali;
          _kategori = _kategori.isEmpty 
              ? (dava['kategori'] ?? dava['davaKategori'] ?? '').toString().trim()
              : _kategori;
          _davaKonusu = _davaKonusu.isEmpty 
              ? (dava['davaKonusu'] ?? '').toString().trim()
              : _davaKonusu;
          
          // Tarih bilgisini parse et
          if (_openedAt == null && dava['openedAt'] != null) {
            try {
              _openedAt = DateTime.parse(dava['openedAt'].toString());
            } catch (e) {
              _openedAt = null;
            }
          }
          if (_openedAt == null && dava['createdAt'] != null) {
            try {
              _openedAt = DateTime.parse(dava['createdAt'].toString());
            } catch (e) {
              _openedAt = null;
            }
          }
        });
        return;
      }
      
      // Eğer açılan davalarda bulunamazsa, gelen davalarda ara
      if (widget.userEmail != null && widget.userEmail!.isNotEmpty) {
        final incomingDavalar = HiveDatabaseService.getIncomingDavalar(widget.userEmail!);
        final incomingDava = incomingDavalar.firstWhere(
          (d) => d['id'] == widget.davaId,
          orElse: () => <String, dynamic>{},
        );
        
        if (incomingDava.isNotEmpty) {
          setState(() {
            _davaAdi = _davaAdi.isEmpty 
                ? (incomingDava['davaAdi'] ?? incomingDava['adi'] ?? '').toString().trim()
                : _davaAdi;
            _davaci = _davaci.isEmpty 
                ? (incomingDava['davaci'] ?? '').toString().trim()
                : _davaci;
            _davali = _davali.isEmpty 
                ? (incomingDava['davali'] ?? '').toString().trim()
                : _davali;
            _kategori = _kategori.isEmpty 
                ? (incomingDava['kategori'] ?? incomingDava['davaKategori'] ?? '').toString().trim()
                : _kategori;
            _davaKonusu = _davaKonusu.isEmpty 
                ? (incomingDava['davaKonusu'] ?? '').toString().trim()
                : _davaKonusu;
            
            // Tarih bilgisini parse et
            if (_openedAt == null && incomingDava['openedAt'] != null) {
              try {
                _openedAt = DateTime.parse(incomingDava['openedAt'].toString());
              } catch (e) {
                _openedAt = null;
              }
            }
            if (_openedAt == null && incomingDava['createdAt'] != null) {
              try {
                _openedAt = DateTime.parse(incomingDava['createdAt'].toString());
              } catch (e) {
                _openedAt = null;
              }
            }
          });
        }
      }
    } catch (e) {
      print('❌ Dava bilgileri yüklenirken hata: $e');
    }
  }

  /// Katılımcı listesini yükle ve durumlarına göre sınıflandır
  Future<void> _loadParticipants() async {
    if (widget.davaId == null || widget.davaId!.isEmpty) return;
    
    setState(() {
      _isLoadingRejecters = true;
    });
    
    try {
      final participants = await HiveDatabaseService.getDavaParticipants(widget.davaId!);
      if (!mounted) return;
      setState(() {
        _participants = participants;
        _rejecters = participants
            .where((p) {
              final status = p['status']?.toString();
              return status == 'manual_rejected' || status == 'auto_rejected' || status == 'rejected';
            })
            .toList();
        _isLoadingRejecters = false;
      });
    } catch (e) {
      print('❌ Red eden kişiler yüklenirken hata: $e');
      setState(() {
        _isLoadingRejecters = false;
      });
    }
  }
  
  /// Dava açıklamasını oluştur
  String _buildDavaDescription() {
    final parts = <String>[];
    
    // Davacı bilgisi
    if (_davaci.isNotEmpty) {
      parts.add('"$_davaci"');
    }
    
    // Davalı bilgisi
    if (_davali.isNotEmpty) {
      parts.add('"$_davali"ya');
    }
    
    // Kategori bilgisi
    if (_kategori.isNotEmpty) {
      parts.add('"$_kategori" kategorisinde');
    }
    
    // Dava adı
    final davaAdiText = _davaAdi.isNotEmpty ? _davaAdi : 'Dava Adı Belirtilmemiş';
    parts.add('"$davaAdiText" adlı davayı');
    
    // Tarih bilgisi
    final tarihText = _openedAt != null 
        ? '${_openedAt!.day.toString().padLeft(2, '0')}.${_openedAt!.month.toString().padLeft(2, '0')}.${_openedAt!.year}'
        : DateTime.now().toString().substring(0, 10).replaceAll('-', '.');
    parts.add('"$tarihText" tarihi ile açmış bulunuyor.');
    
    final description = parts.join(' ');
    
    // Eğer hiç bilgi yoksa varsayılan mesaj
    if (description.trim().isEmpty || description == '"Dava Adı Belirtilmemiş" adlı davayı "..." tarihi ile açmış bulunuyor.') {
      return 'Dava bilgileri yükleniyor...';
    }
    
    return description;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          // Modern Header with Gradient
            Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE8FFE3),
                  Color(0xFFD4F4E8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF34dfae).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                // Date Badge

                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                    _davaAdi.isNotEmpty ? _davaAdi : 'Dava Adı Belirtilmemiş',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: Color(0xFF1A1A1A),
                          letterSpacing: -0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),

                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Action Buttons
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Close Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (widget.onClose != null) {
                            widget.onClose!.call();
                          } else {
                            Navigator.of(context).maybePop();
                          }
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.black,
                            size: 18,
                          ),
                      ),
                    ),
                  ),
                ],
              ),
              ],
            ),
            ),
          // Expandable Table Section with smooth animation
          if (showDetails)
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubic,
              child: _buildCaseTable(),
            ),
          ],
      ),
    );
  }

  Widget _buildCaseTable() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFAFAFA),
            Color(0xFFF5F5F5),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
              // Case Info Cards
              ...caseDetails.asMap().entries.map((entry) {
                final index = entry.key;
                final row = entry.value;
                return Padding(
                  padding: EdgeInsets.only(bottom: index < caseDetails.length - 1 ? 12 : 0),
                  child: _buildInfoCard(row["label"]!, row["value"]!),
                );
              }),
              const SizedBox(height: 16),
              // Description Card
              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey[200]!,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF34dfae).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            color: Color(0xFF34dfae),
                            size: 20,
                        ),
                      ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _buildDavaDescription(),
                            style: TextStyle(
                              color: Colors.grey[800],
                              fontSize: 13,
                              height: 1.5,
                            ),
                          ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 20),
            // Section Title
            _buildSectionTitle("Dava Detayları", Icons.gavel),
            const SizedBox(height: 14),
            // Expandable List with modern design
            ...expandableItems.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < expandableItems.length - 1 ? 8 : 0),
                child: _buildModernExpansionTile(
                  item,
                  Colors.green,
                  Icons.check_circle_outline,
                  index: index,
                ),
              );
            }),
            const SizedBox(height: 20),
            // Section Title
            _buildSectionTitle("19.Kişilerin Yorumları", Icons.people_outline),
            const SizedBox(height: 14),
            // Kişi Soruları with modern design
            ...kisiSorular.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: index < kisiSorular.length - 1 ? 8 : 0),
                child: _buildModernExpansionTile(
                  item,
                  Colors.teal,
                  Icons.chat_bubble_outline,
                  index: index,
                ),
              );
            }),

          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoCard(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
                  ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
            padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
              color: const Color(0xFF8A5FBF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
            child: const Icon(
              Icons.label_outline,
              color: Color(0xFF8A5FBF),
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF1A1A1A),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
        children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF34dfae).withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 16, color: const Color(0xFF34dfae)),
        ),
        const SizedBox(width: 8),
          Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1A1A1A),
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildModernExpansionTile(String title, Color color, IconData icon, {int index = 0}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          expansionTileTheme: ExpansionTileThemeData(
            iconColor: color,
            collapsedIconColor: color,
            textColor: const Color(0xFF1A1A1A),
            collapsedTextColor: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            collapsedShape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          maintainState: true,
          onExpansionChanged: (isExpanded) {
            // Expansion açıldığında smooth scroll için
            if (isExpanded) {
              // "Davayı Yorumlamayı Kabul ve Red Edenler" açıldığında verileri yenile
              if (title == "Davayı Yorumlamayı Kabul ve Red Edenler" && widget.davaId != null && widget.davaId!.isNotEmpty) {
                _loadParticipants();
              }
              // "Çekilen var mı (Kişisel)" açıldığında verileri yenile
              if (title == "Çekilen var mı (Kişisel)" && widget.davaId != null && widget.davaId!.isNotEmpty) {
                _loadParticipants();
              }
              Future.delayed(const Duration(milliseconds: 250), () {
                // Scroll işlemi için gerekirse burada yapılabilir
              });
            }
          },
          leading: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: Color(0xFF1A1A1A),
              letterSpacing: -0.2,
              height: 1.3,
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
          ),
          children: [
            // "Davayı Yorumlamayı Kabul ve Red Edenler" için özel içerik
            if (title == "Davayı Yorumlamayı Kabul ve Red Edenler" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildRejectersContent(color)
            // "Çekilen var mı (Kişisel)" için özel içerik
            else if (title == "Çekilen var mı (Kişisel)" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildCekilenContent(color)
            else if (title == "Davacı Haklı mı Haksız mı" && widget.davaId != null && widget.davaId!.isNotEmpty)
              _buildDavaciConsensusContent(color)
            else
              AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withOpacity(0.06),
                      color.withOpacity(0.03),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: color.withOpacity(0.2),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(
                        Icons.info_outline,
                        size: 15,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title.contains("Kişi") 
                            ? "$title: Henüz yorum yapılmadı."
                            : "Bu bölüm için içerik yakında eklenecektir.",
                        style: TextStyle(
                          color: color.withOpacity(0.9),
                          fontSize: 12.5,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Red eden kişileri gösteren içerik - İki sütunlu yapı
  Widget _buildRejectersContent(Color color) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white,
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  color.withOpacity(0.1),
                  color.withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.groups_outlined,
                    size: 20,
                    color: color,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Davada Hüküm Vermeyi Kabul ve Red Edenler',
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // Yükleniyor durumu
          if (_isLoadingRejecters)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Yükleniyor...',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // İki sütunlu yapı
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sol Sütun: Red Edenler
                Expanded(
                  child: _buildRejectedColumn(color),
                ),
                const SizedBox(width: 16),
                // Sağ Sütun: Aktif Kişiler (Dava Gönderilen 7 Kişi)
                Expanded(
                  child: _buildActiveColumn(color),
                ),
              ],
            ),


          ],
        ],
      ),
    );
  }
  
  /// Sol sütun: Red edenler listesi
  Widget _buildRejectedColumn(Color color) {
    // Red edenler listesini normalize et
    final normalizedRejecters = _rejecters
        .where((r) => (r['userEmail'] as String? ?? '').trim().isNotEmpty)
        .toList();
    
    if (normalizedRejecters.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.red[50]!,
              Colors.red[50]!.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.red.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.cancel_outlined,
                size: 36,
                color: Colors.red[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Red Edenler',
              style: TextStyle(
                color: Colors.red[900],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz red eden yok',
              style: TextStyle(
                color: Colors.red[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red[50]!,
            Colors.red[50]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.red[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red[100]!,
                  Colors.red[50]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.red[300]!,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.cancel,
                    size: 18,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Red',
                    style: TextStyle(
                      color: Colors.red[900],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${normalizedRejecters.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Red edenler listesi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: normalizedRejecters.asMap().entries.map((entry) {
                final index = entry.key;
                final rejecter = entry.value;
                final email = rejecter['userEmail'] as String? ?? '';
                final displayName = (rejecter['displayName'] ?? '').toString().isNotEmpty
                    ? rejecter['displayName'].toString()
                    : HiveDatabaseService.getRegistrationByEmail(email)?.judgeName ?? email.split('@')[0];
                final initials = _getInitials(displayName);
                // Profil resmi URL'sini al
                final settings = HiveDatabaseService.getSettings(email);
                final profileImageUrl = settings?.profileImageUrl;
                
                // Red tarihini bul
                String? rejectedTimeText;
                final rejectedAt = rejecter['statusUpdatedAt'] ?? rejecter['rejectedAt'] ?? '';
                
                if (rejectedAt.isNotEmpty) {
                  try {
                    final rejectedDate = DateTime.parse(rejectedAt.toString());
                    final now = DateTime.now();
                    final difference = now.difference(rejectedDate);
                    
                    if (difference.inDays > 0) {
                      rejectedTimeText = '${difference.inDays} gün önce';
                    } else if (difference.inHours > 0) {
                      rejectedTimeText = '${difference.inHours} saat önce';
                    } else if (difference.inMinutes > 0) {
                      rejectedTimeText = '${difference.inMinutes} dakika önce';
                    } else {
                      rejectedTimeText = 'Az önce';
                    }
                  } catch (e) {
                    rejectedTimeText = null;
                  }
                }
                
                final String statusLabel;
                final status = rejecter['status']?.toString() ?? 'rejected';
                if (status == 'auto_rejected') {
                  statusLabel = 'Süre doldu';
                } else {
                  statusLabel = 'Red';
                }

                return Container(
                  margin: EdgeInsets.only(bottom: index < normalizedRejecters.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.red[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.red[400],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                // Resim yüklenemezse initials göster
                              }
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.red[900],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  status == 'auto_rejected' ? Icons.schedule : Icons.block,
                                  size: 12,
                                  color: Colors.red[600],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusLabel,
                                  style: TextStyle(
                                    color: Colors.red[600],
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (rejectedTimeText != null) ...[
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    size: 12,
                                    color: Colors.red[400],
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    rejectedTimeText,
                                    style: TextStyle(
                                      color: Colors.red[400],
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  /// Sağ sütun: Aktif kişiler listesi (Dava gönderilen 7 kişi)
  Widget _buildActiveColumn(Color color) {
    // Aktif kişiler listesi (red edenler hariç) - email'leri normalize et
    final activeParticipants = _participants
        .where((participant) {
          final email = (participant['userEmail']?.toString() ?? '').trim().toLowerCase();
          if (email.isEmpty) return false;
          final status = participant['status']?.toString() ?? 'pending';
          return !(status == 'manual_rejected' || status == 'auto_rejected' || status == 'rejected');
        })
        .toList();

    if (activeParticipants.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green[50]!,
              Colors.green[50]!.withOpacity(0.5),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.green[200]!,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 36,
                color: Colors.green[400],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Kabul Edenler',
              style: TextStyle(
                color: Colors.green[900],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Henüz kabul eden yok',
              style: TextStyle(
                color: Colors.green[600],
                fontSize: 13,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[50]!,
            Colors.green[50]!.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green[200]!,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Başlık
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[100]!,
                  Colors.green[50]!,
                ],
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.green[300]!,
                  width: 1.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 18,
                    color: Colors.green[700],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Kabul Edenler',
                    style: TextStyle(
                      color: Colors.green[900],
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[700],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${activeParticipants.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Aktif kişiler listesi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: activeParticipants.asMap().entries.map((entry) {
                final index = entry.key;
                final participant = entry.value;
                final email = participant['userEmail']?.toString() ?? '';
                final user = HiveDatabaseService.getRegistrationByEmail(email);
                final displayName = (participant['displayName'] ?? '').toString().isNotEmpty
                    ? participant['displayName'].toString()
                    : user?.judgeName ?? (email.contains('@') ? email.split('@')[0] : email);
                final initials = _getInitials(displayName);
                // Profil resmi URL'sini al
                final settings = HiveDatabaseService.getSettings(email);
                final profileImageUrl = settings?.profileImageUrl;
                
                // Kabul tarihini bul (eğer varsa)
                String? acceptedTimeText;
                final status = participant['status']?.toString() ?? 'pending';
                if (status == 'accepted') {
                  final acceptedAtStr = participant['statusUpdatedAt']?.toString();
                  if (acceptedAtStr != null && acceptedAtStr.isNotEmpty) {
                    try {
                      final acceptedDate = DateTime.parse(acceptedAtStr);
                      final now = DateTime.now();
                      final difference = now.difference(acceptedDate);
                      if (difference.inDays > 0) {
                        acceptedTimeText = '${difference.inDays} gün önce';
                      } else if (difference.inHours > 0) {
                        acceptedTimeText = '${difference.inHours} saat önce';
                      } else if (difference.inMinutes > 0) {
                        acceptedTimeText = '${difference.inMinutes} dakika önce';
                      } else {
                        acceptedTimeText = 'Az önce';
                      }
                    } catch (_) {
                      acceptedTimeText = null;
                    }
                  }
                }
                
                return Container(
                  margin: EdgeInsets.only(bottom: index < activeParticipants.length - 1 ? 10 : 0),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green[300]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withOpacity(0.08),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Avatar
                      CircleAvatar(
                        radius: 21,
                        backgroundColor: Colors.green[400],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl)
                            : null,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                // Resim yüklenemezse initials göster
                              }
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : Text(
                                initials,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: TextStyle(
                                color: Colors.green[900],
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  status == 'accepted' ? Icons.check_circle : Icons.pending_outlined,
                                  size: 12,
                                  color: status == 'accepted' ? Colors.green[600] : Colors.green[600],
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    status == 'accepted' ? (acceptedTimeText ?? 'Onaylandı') : 'Beklemede',
                                    style: TextStyle(
                                      color: Colors.green[600],
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.check_circle,
                        color: Colors.green[400],
                        size: 20,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
  
  /// İsimden baş harfleri al
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    } else if (parts.length == 1 && parts[0].length >= 2) {
      return parts[0].substring(0, 2).toUpperCase();
    } else {
      return name.substring(0, name.length > 2 ? 2 : name.length).toUpperCase();
    }
  }

  /// Çekilen var mı (Kişisel) içeriğini oluştur
  Widget _buildCekilenContent(Color color) {
    return FutureBuilder<String>(
      future: _getCekilenText(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final cekilenText = snapshot.data ?? '';
        
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cekilenText.isNotEmpty ? Colors.orange[50]! : Colors.green[50]!,
                cekilenText.isNotEmpty ? Colors.orange[50]!.withOpacity(0.5) : Colors.green[50]!.withOpacity(0.5),
              ],
            ),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: cekilenText.isNotEmpty ? Colors.orange[300]! : Colors.green[300]!,
              width: 1.2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cekilenText.isNotEmpty ? Colors.orange[100]! : Colors.green[100]!,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      cekilenText.isNotEmpty ? Icons.warning_amber_rounded : Icons.check_circle_outline,
                      size: 20,
                      color: cekilenText.isNotEmpty ? Colors.orange[700]! : Colors.green[700]!,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      cekilenText.isNotEmpty ? 'Davadan Çekilen Kişiler' : 'Davadan Çekilen Yok',
                      style: TextStyle(
                        color: cekilenText.isNotEmpty ? Colors.orange[900]! : Colors.green[900]!,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (cekilenText.isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange[200]!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    cekilenText,
                    style: TextStyle(
                      color: Colors.grey[900],
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ] else ...[
                const SizedBox(height: 12),
                Text(
                  'Tüm kişiler hükümlerini vermiş veya henüz 7 gün geçmemiş.',
                  style: TextStyle(
                    color: Colors.green[700],
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  /// Çekilen kişiler metnini oluştur
  Future<String> _getCekilenText() async {
    if (widget.davaId == null || widget.davaId!.isEmpty) {
      return '';
    }

    final List<String> messages = [];

    final freezedDavaAdi = _davaAdi.isNotEmpty
        ? _davaAdi
        : (widget.davaAdi ?? 'Dava Adı Belirtilmemiş');

    // Kabul edilmiş ve 168 saat sonunda hüküm veremeyen kişiler.
    final expiredAcceptedMessages =
        await DavaTimerService.buildExpiredAcceptedMessages(
      davaId: widget.davaId!,
      davaAdi: freezedDavaAdi,
    );
    messages.addAll(expiredAcceptedMessages);

    // Dava açılış tarihini kontrol et
    if (_openedAt == null) {
      return messages.join('\n').trim();
    }

    // 7 gün geçmiş mi kontrol et
    final now = DateTime.now();
    final difference = now.difference(_openedAt!);
    if (difference.inDays < 7) {
      return messages.join('\n').trim();
    }

    // Tüm hükümleri al
    final hukumler =
        await HiveDatabaseService.getHukumlerByDavaId(widget.davaId!);
    final hukumVerilmisMevkiler = <String>{};
    for (final hukum in hukumler) {
      final mevki = hukum['userRole']?.toString() ?? '';
      if (mevki.isNotEmpty) {
        hukumVerilmisMevkiler.add(mevki);
      }
    }

    // Çekilen kişileri bul
    final cekilenKisiler = <Map<String, dynamic>>[];
    final participants =
        await HiveDatabaseService.getDavaParticipants(widget.davaId!);

    for (final participant in participants) {
      final status = participant['status']?.toString() ?? 'pending';
      if (status == 'accepted') {
        final mevki = participant['mevkii']?.toString();
        if (mevki != null && mevki.isNotEmpty) {
          hukumVerilmisMevkiler.add(mevki);
        }
      }
    }

    for (final participant in participants) {
      final email = participant['userEmail']?.toString() ?? '';
      if (email.isEmpty) continue;

      final status = participant['status']?.toString() ?? 'pending';
      final mevkiRaw = participant['mevkii']?.toString() ?? '';
      final normalizedMevki = mevkiRaw.endsWith(' Kararı')
          ? mevkiRaw.substring(0, mevkiRaw.length - 7)
          : mevkiRaw;

      if (status == 'pending' && normalizedMevki.isNotEmpty) {
        if (!hukumVerilmisMevkiler.contains(normalizedMevki)) {
          final kisiAdi =
              (participant['displayName'] ?? '').toString().isNotEmpty
                  ? participant['displayName'].toString()
                  : HiveDatabaseService.getRegistrationByEmail(email)
                          ?.judgeName ??
                      (email.contains('@')
                          ? email.split('@')[0]
                          : email);
          cekilenKisiler.add({
            'mevki': normalizedMevki,
            'isim': kisiAdi,
          });
        }
      }
    }

    if (cekilenKisiler.isNotEmpty) {
      final mevkiler =
          cekilenKisiler.map((k) => '"${k['mevki']}"').join(',');
      final isimler =
          cekilenKisiler.map((k) => '"${k['isim']}"').join(',');
      final davaci = _davaci.isNotEmpty ? _davaci : 'Davacı';
      final davali = _davali.isNotEmpty ? _davali : 'Davalı';

      messages.add(
        '$mevkiler $isimler vicdani problemleri sebebi ile '
        '"$davaci" \'in "$davali" \'ya açtığı davasından çekilmek zorunda kalmıştır.',
      );
    }

    return messages.join('\n').trim();
  }

  Future<DavaConsensusEvaluation> _getDavaciConsensusEvaluation() async {
    if (widget.davaId == null || widget.davaId!.isEmpty) {
      return const DavaConsensusEvaluation.empty();
    }
    return DavaConsensusService.evaluateConsensus(
      davaId: widget.davaId!,
      openedAt: _openedAt,
    );
  }

  String _buildDavaciConsensusMessage(DavaConsensusEvaluation evaluation) {
    final String davaciName = (_davaci.isNotEmpty
            ? _davaci
            : (widget.davaci ?? 'Davacı'))
        .trim();
    if (evaluation.isFinal) {
      return 'DAVACI "$davaciName" davada ortak akıl sonucu çoğunluk tarafından "${evaluation.verdictLabel}" görüldü.';
    }
    final String? remaining = evaluation.remainingLabel;
    if (remaining != null) {
      return 'Ortak akıl kararı için 7 günlük süre henüz dolmadı. Kalan süre: $remaining.';
    }
    return 'Ortak akıl kararı için veriler toplanıyor.';
  }

  Widget _buildDavaciConsensusContent(Color color) {
    return FutureBuilder<DavaConsensusEvaluation>(
      future: _getDavaciConsensusEvaluation(),
      builder: (BuildContext context,
          AsyncSnapshot<DavaConsensusEvaluation> snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 2),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  color.withOpacity(0.06),
                  color.withOpacity(0.03),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1.2,
              ),
            ),
            child: const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            ),
          );
        }

        final DavaConsensusEvaluation evaluation =
            snapshot.data ?? const DavaConsensusEvaluation.empty();
        final bool isFinal = evaluation.isFinal;
        final bool isHakli =
            evaluation.verdict == DavaConsensusVerdict.hakli;

        final Color baseColor = isFinal
            ? (isHakli ? Colors.green.shade600 : Colors.red.shade600)
            : Colors.orange.shade600;
        final IconData baseIcon = isFinal
            ? (isHakli ? Icons.verified : Icons.warning_amber_rounded)
            : Icons.timer;

        final String message = _buildDavaciConsensusMessage(evaluation);

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          margin: const EdgeInsets.only(bottom: 2),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                baseColor.withOpacity(0.15),
                Colors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: baseColor.withOpacity(0.35),
              width: 1.5,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: baseColor.withOpacity(0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: baseColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(baseIcon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isFinal
                          ? 'Ortak akıl kararı kesinleşti'
                          : 'Ortak akıl kararı bekleniyor',
                      style: TextStyle(
                        color: baseColor,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: TextStyle(
                  color: Colors.grey.shade900,
                  fontSize: 14,
                  height: 1.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  _buildConsensusStatChip(
                    label: 'Olumlu',
                    value: evaluation.positiveCount,
                    color: Colors.orange.shade600,
                  ),
                  const SizedBox(width: 12),
                  _buildConsensusStatChip(
                    label: 'Olumsuz',
                    value: evaluation.negativeCount,
                    color: Colors.blue.shade600,
                  ),
                ],
              ),
              if (!isFinal && evaluation.remainingLabel != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  'Kararın kesinleşmesine kalan süre: ${evaluation.remainingLabel}',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildConsensusStatChip({
    required String label,
    required int value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.4,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

