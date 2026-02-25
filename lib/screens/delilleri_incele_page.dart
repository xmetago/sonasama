import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/evidence_viewer_widget.dart';
import '../services/hive_database_service.dart';

// Model class for Dava (delil için de kullanılabilir)
class Dava {
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;

  Dava({
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
  });
}

/// Delilleri İncele Sayfası
/// Yargıla sayfasından erişilen, dava delillerini görüntüleme sayfası
/// Modern EvidenceViewerWidget kullanır
class DelilleriIncelePage extends StatefulWidget {
  final String? userEmail;
  final String? davaId; // Opsiyonel dava ID - null ise kabul edilen davalar gösterilir

  const DelilleriIncelePage({
    super.key,
    this.userEmail,
    this.davaId,
  });

  @override
  State<DelilleriIncelePage> createState() => _DelilleriIncelePageState();
}

class _DelilleriIncelePageState extends State<DelilleriIncelePage> {
  List<Map<String, dynamic>> _acceptedDavalar = [];
  bool _isLoading = true;
  String? _selectedDavaId; // Deliller için kullanılan gerçek davaId
  String? _selectedDropdownValue; // Dropdown için benzersiz değer

  @override
  void initState() {
    super.initState();
    // Eğer widget'tan davaId gelmişse onu kullan
    // Ama önce accepted davaları yükleyip davaId alanını kontrol etmeliyiz
    _selectedDavaId = widget.davaId;
    _loadAcceptedDavalar();
  }

  /// Kabul edilen davaları yükle
  Future<void> _loadAcceptedDavalar() async {
    try {
      final acceptedDavalar = await HiveDatabaseService.getAcceptedDavalar(
        widget.userEmail ?? '',
      );
      
      setState(() {
        _acceptedDavalar = acceptedDavalar;
        _isLoading = false;
        
        // Eğer widget'tan davaId gelmişse, accepted davalar içinde eşleşeni bul
        if (widget.davaId != null && _acceptedDavalar.isNotEmpty) {
          // Önce davaId ile eşleşen dava ara
          final matchingIndex = _acceptedDavalar.indexWhere(
            (dava) {
              final davaId = (dava['davaId'] as String?) ?? (dava['id'] as String?);
              return davaId?.trim().toLowerCase() == widget.davaId!.trim().toLowerCase() ||
                     (dava['id'] as String?)?.trim().toLowerCase() == widget.davaId!.trim().toLowerCase();
            },
          );
          
          if (matchingIndex != -1) {
            final matchingDava = _acceptedDavalar[matchingIndex];
            _selectedDavaId = (matchingDava['davaId'] as String?) ?? 
                             (matchingDava['id'] as String?);
            // Dropdown için benzersiz değer oluştur
            _selectedDropdownValue = (matchingDava['id'] as String?) ?? 
                                    '${matchingDava['davaId'] as String? ?? 'dava'}_$matchingIndex';
            print('🔍 Widget davaId ile eşleşen dava bulundu: $_selectedDavaId');
          }
        }
        
        // Eğer dava ID belirtilmemişse ve listede dava varsa ilkini seç
        // Önce davaId alanını dene, yoksa id kullan
        if (_selectedDavaId == null && _acceptedDavalar.isNotEmpty) {
          final firstDava = _acceptedDavalar.first;
          const firstIndex = 0;
          _selectedDavaId = (firstDava['davaId'] as String?) ?? 
                           (firstDava['id'] as String?);
          // Dropdown için benzersiz değer oluştur
          _selectedDropdownValue = (firstDava['id'] as String?) ?? 
                                  '${firstDava['davaId'] as String? ?? 'dava'}_$firstIndex';
          print('🔍 İlk dava seçildi: $_selectedDavaId');
        }
      });
      
      print('✅ ${_acceptedDavalar.length} kabul edilmiş dava yüklendi');
      if (_selectedDavaId != null) {
        print('🔍 Seçili dava ID: $_selectedDavaId');
      }
    } catch (e) {
      print('❌ Davalar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

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
                  onShowSavedDavalar: () {
                    // Delilleri incele sayfasında kaydedilen davalar dialog'u açılamaz
                    // Bu sayfa sadece delil inceleme işlemleri için
                  },
                ),
              ),
              // ROW 4: Başlık satırı
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        MdiIcons.menuOpen,
                        size: 34,
                        color: Colors.red,
                      ),
                      onPressed: () {},
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.content_paste_search,
                              color: Colors.blue[700],
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "DELİLLERİ İNCELE",
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // ROW 5: Dava seçici ve Delil görüntüleyici
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32.0),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_acceptedDavalar.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                        Icon(
                          MdiIcons.gavel,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz kabul edilmiş dava yok',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Dava kabul ettiğinizde delillerini buradan inceleyebilirsiniz',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        ],
                      ),
                    ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(8.0),
                      child: Column(
                        children: [
                      // Dava seçici dropdown (birden fazla dava varsa)
                      if (_acceptedDavalar.length > 1)
                        Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.blue[200]!,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedDropdownValue,
                              isExpanded: true,
                              icon: Icon(
                                Icons.arrow_drop_down,
                                color: Colors.blue[700],
                              ),
                              items: _acceptedDavalar.asMap().entries.map((entry) {
                                final index = entry.key;
                                final dava = entry.value;
                                // Her item için benzersiz bir value oluştur
                                // Önce id alanını kullan (her zaman benzersizdir)
                                // Eğer id yoksa davaId + index kombinasyonu kullan
                                final uniqueValue = (dava['id'] as String?) ?? 
                                                   '${dava['davaId'] as String? ?? 'dava'}_$index';
                                return DropdownMenuItem<String>(
                                  value: uniqueValue,
                                  child: Text(
                                    dava['adi'] as String? ?? 'İsimsiz Dava',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedDropdownValue = newValue;
                                  // Seçilen dava için gerçek davaId'yi bul
                                  if (newValue != null) {
                                    final selectedIndex = _acceptedDavalar.asMap().entries.firstWhere(
                                      (entry) {
                                        final index = entry.key;
                                        final dava = entry.value;
                                        final uniqueValue = (dava['id'] as String?) ?? 
                                                           '${dava['davaId'] as String? ?? 'dava'}_$index';
                                        return uniqueValue == newValue;
                                      },
                                      orElse: () => _acceptedDavalar.asMap().entries.first,
                                    );
                                    
                                    final selectedDava = selectedIndex.value;
                                    // Deliller için gerçek davaId'yi kullan
                                    _selectedDavaId = (selectedDava['davaId'] as String?) ?? 
                                                     (selectedDava['id'] as String?);
                                    print('🔍 Dava seçildi - Dropdown: $newValue, DavaId: $_selectedDavaId');
                                  }
                                });
                              },
                            ),
                          ),
                        ),
                      
                      // Modern Delil Görüntüleyici Widget
                      // Dava seçildiğinde delilleri göster
                      if (_selectedDavaId != null)
                        EvidenceViewerWidget(
                          key: ValueKey(_selectedDavaId), // Dava değiştiğinde widget'ı yeniden oluştur
                          davaId: _selectedDavaId!.trim(), // Trim yaparak eşleşmeyi garanti et
                          userEmail: widget.userEmail,
                          showCaseInfo: true,
                          caseInfoCard: _buildDavaInfoCard(),
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

  /// Dava bilgi kartı oluştur
  Widget _buildDavaInfoCard() {
    if (_selectedDavaId == null) return const SizedBox.shrink();
    
    // Seçili davayı bul
    final selectedDava = _acceptedDavalar.firstWhere(
      (dava) => dava['id'] == _selectedDavaId,
      orElse: () => {},
    );
    
    if (selectedDava.isEmpty) return const SizedBox.shrink();
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.blue[50]!,
              Colors.white,
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    MdiIcons.gavel,
                    color: Colors.blue[700],
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedDava['adi'] as String? ?? 'İsimsiz Dava',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (selectedDava['davaKonusu'] != null &&
                          (selectedDava['davaKonusu'] as String).isNotEmpty)
                        Text(
                          selectedDava['davaKonusu'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            
            // Detaylar
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Davacı',
                    selectedDava['davaci'] as String? ?? '-',
                    Icons.person,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Davalı',
                    selectedDava['davali'] as String? ?? '-',
                    Icons.person_outline,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildInfoItem(
                    'Görev',
                    selectedDava['userRole'] as String? ?? '-',
                    Icons.badge,
                  ),
                ),
                Expanded(
                  child: _buildInfoItem(
                    'Kalan Süre',
                    selectedDava['kalanSure'] as String? ?? '-',
                    MdiIcons.timerSand,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Bilgi item widget'ı
  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: Colors.blue[700],
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Reused Widgets from GelenDavalarPage

class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_up_alt_outlined,
                            size: 19,
                            color: Colors.green,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Haklı... ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(5.0),
                        child: Image.asset(dava.profilResmi, width: 60, height: 50),
                      ),
                      const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.thumb_down_off_alt_outlined,
                            size: 19,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Haksız ',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dava Adı    :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.adi, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Text('Davalı :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Row(
                              children: [
                                Flexible(child: Text(dava.davali, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                const Spacer(),
                                const Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.green),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Görev        :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 4),
                          Flexible(child: Text(dava.mevkii, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.green),
                          const SizedBox(width: 4),
                          const Text('Kalan Süre :', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Flexible(
                            child: Text(
                              dava.kalanSure,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              minimumSize: const Size(60, 30),
                            ),
                            child:Icon(MdiIcons.gavel, size: 19, color: Colors.black54),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
