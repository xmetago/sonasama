import 'package:flutter/material.dart';
import 'package:flutter_feather_icons/flutter_feather_icons.dart';
import '../services/hive_database_service.dart';

/// Reklam Yönetim Sayfası
/// Admin panelinden erişilen reklam yönetim sayfası
/// Reklam ekleme, düzenleme, silme ve listeleme işlemlerini yapar
class ReklamYonetimPage extends StatefulWidget {
  final String adminEmail;

  const ReklamYonetimPage({super.key, required this.adminEmail});

  @override
  State<ReklamYonetimPage> createState() => _ReklamYonetimPageState();
}

class _ReklamYonetimPageState extends State<ReklamYonetimPage> {
  List<Map<String, dynamic>> allReklamlar = [];
  List<Map<String, dynamic>> filteredReklamlar = [];
  final TextEditingController _searchController = TextEditingController();
  String _filterStatus = 'all'; // all, aktif, pasif, taslak

  // Ana kategoriler listesi
  final List<String> _kategoriler = [
    'OTOMOTİV',
    'İŞ DÜNYASI & ENDÜSTRİ',
    'EĞLENCE & KÜLTÜR',
    'AİLE & EBEVEYNLİK',
    'YEMEK & İÇECEK',
    'SAĞLIK & ZİNDELİK',
    'EV & BAHÇE',
    'MEDYA & YAYINCILIK',
    'MODA & AKSESUAR',
    'SEYAHAT & TURİZM',
    'SPOR',
    'TEKNOLOJİ & ELEKTRONİK',
    'TELEKOMÜNİKASYON',
    'EĞİTİM',
    'FİNANS & BANKACILIK',
    'EMLAK & GAYRİMENKUL',
    'ALIŞVERİŞ',
    'TOPLUM & KAMU',
    'KİŞİSEL HİZMETLER & İŞLETMELER',
    'HOBİLER & İLGİ ALANLARI',
    'İŞ KARİYER & KURUMSAL YAŞAM',
    'DİĞER',
  ];

  @override
  void initState() {
    super.initState();
    _loadReklamlar();
    _searchController.addListener(_filterReklamlar);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reklamları Hive'dan yükle
  Future<void> _loadReklamlar() async {
    try {
      // Tüm reklamları getir (aktif, pasif, taslak)
      final reklamlar = await HiveDatabaseService.getAllReklamlar();
      
      setState(() {
        allReklamlar = reklamlar;
        _filterReklamlar();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reklamlar yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Reklamları filtrele
  void _filterReklamlar() {
    final query = _searchController.text.toLowerCase().trim();
    
    setState(() {
      filteredReklamlar = allReklamlar.where((reklam) {
        // Arama kriteri
        final matchesSearch = query.isEmpty ||
            (reklam['reklamAdi'] as String? ?? '').toLowerCase().contains(query) ||
            (reklam['reklamBasligi'] as String? ?? '').toLowerCase().contains(query) ||
            (reklam['reklamKodu'] as String? ?? '').toLowerCase().contains(query) ||
            (reklam['reklamKategorisi'] as String? ?? '').toLowerCase().contains(query);
        
        // Durum filtresi
        final durum = reklam['durum'] as String? ?? 'taslak';
        final matchesFilter = _filterStatus == 'all' ||
            (_filterStatus == 'aktif' && durum == 'aktif') ||
            (_filterStatus == 'pasif' && durum == 'pasif') ||
            (_filterStatus == 'taslak' && durum == 'taslak');
        
        return matchesSearch && matchesFilter;
      }).toList();
      
      // Tarihe göre sırala (en yeni üstte)
      filteredReklamlar.sort((a, b) {
        final aDate = a['olusturulmaTarihi'] as String? ?? '';
        final bDate = b['olusturulmaTarihi'] as String? ?? '';
        return bDate.compareTo(aDate);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reklam Yönetimi'),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(FeatherIcons.refreshCw),
            onPressed: _loadReklamlar,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
          ),
        ),
        child: Column(
          children: [
            // İstatistikler
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      'Toplam',
                      '${allReklamlar.length}',
                      Icons.campaign,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Aktif',
                      '${allReklamlar.where((r) => r['durum'] == 'aktif').length}',
                      Icons.check_circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatCard(
                      'Pasif',
                      '${allReklamlar.where((r) => r['durum'] == 'pasif').length}',
                      Icons.cancel,
                    ),
                  ),
                ],
              ),
            ),
            
            // Arama ve filtre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Reklam ara (ad, başlık, kod, kategori)...',
                      prefixIcon: const Icon(FeatherIcons.search, color: Color(0xFF059669)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                              },
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('Tümü', 'all'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Aktif', 'aktif'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Pasif', 'pasif'),
                        const SizedBox(width: 8),
                        _buildFilterChip('Taslak', 'taslak'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Reklam listesi
            Expanded(
              child: filteredReklamlar.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.campaign, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'Reklam bulunamadı',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filteredReklamlar.length,
                      itemBuilder: (context, index) {
                        final reklam = filteredReklamlar[index];
                        return _buildReklamCard(reklam);
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addNewReklam(),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Yeni Reklam'),
      ),
    );
  }

  /// İstatistik kartı
  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF059669)),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF059669),
            ),
          ),
          Text(
            title,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Filtre chip'i
  Widget _buildFilterChip(String label, String filterValue) {
    final isSelected = _filterStatus == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _filterStatus = filterValue;
          _filterReklamlar();
        });
      },
      selectedColor: const Color(0xFF059669).withOpacity(0.2),
      checkmarkColor: const Color(0xFF059669),
      labelStyle: TextStyle(
        color: isSelected ? const Color(0xFF059669) : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  /// Reklam kartı
  Widget _buildReklamCard(Map<String, dynamic> reklam) {
    final durum = reklam['durum'] as String? ?? 'taslak';
    final durumColor = durum == 'aktif'
        ? Colors.green
        : durum == 'pasif'
            ? Colors.red
            : Colors.orange;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: durumColor,
          child: Icon(
            durum == 'aktif'
                ? Icons.check_circle
                : durum == 'pasif'
                    ? Icons.cancel
                    : Icons.edit,
            color: Colors.white,
          ),
        ),
        title: Text(
          reklam['reklamBasligi'] as String? ?? 'Başlık yok',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Kategori: ${reklam['reklamKategorisi'] as String? ?? 'DİĞER'}'),
            Text('Kod: ${reklam['reklamKodu'] as String? ?? 'Kod yok'}'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: durumColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: durumColor),
                  ),
                  child: Text(
                    durum.toUpperCase(),
                    style: TextStyle(
                      color: durumColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'Gösterim: ${reklam['gosterimSayisi'] ?? 0}',
                  style: const TextStyle(fontSize: 11),
                ),
                const SizedBox(width: 8),
                Text(
                  'Tıklama: ${reklam['tiklanmaSayisi'] ?? 0}',
                  style: const TextStyle(fontSize: 11),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => <PopupMenuEntry<String>>[
            const PopupMenuItem<String>(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Düzenle'),
                ],
              ),
            ),
            PopupMenuItem<String>(
              value: 'toggle_status',
              child: Row(
                children: [
                  Icon(
                    durum == 'aktif' ? Icons.visibility_off : Icons.visibility,
                    color: durum == 'aktif' ? Colors.orange : Colors.green,
                  ),
                  const SizedBox(width: 8),
                  Text(durum == 'aktif' ? 'Pasif Yap' : 'Aktif Yap'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem<String>(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Sil', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'edit') {
              _editReklam(reklam);
            } else if (value == 'toggle_status') {
              _toggleReklamStatus(reklam);
            } else if (value == 'delete') {
              _deleteReklam(reklam);
            }
          },
        ),
        onTap: () => _editReklam(reklam),
      ),
    );
  }

  /// Yeni reklam ekle
  void _addNewReklam() {
    _showReklamDialog();
  }

  /// Reklam düzenle
  void _editReklam(Map<String, dynamic> reklam) {
    _showReklamDialog(reklam: reklam);
  }

  /// Reklam durumunu değiştir
  Future<void> _toggleReklamStatus(Map<String, dynamic> reklam) async {
    final currentStatus = reklam['durum'] as String? ?? 'taslak';
    final newStatus = currentStatus == 'aktif' ? 'pasif' : 'aktif';
    
    final updatedReklam = Map<String, dynamic>.from(reklam);
    updatedReklam['durum'] = newStatus;
    updatedReklam['guncellenmeTarihi'] = DateTime.now().toIso8601String();
    
    await HiveDatabaseService.saveReklam(updatedReklam);
    _loadReklamlar();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reklam ${newStatus == 'aktif' ? 'aktif' : 'pasif'} yapıldı'),
          backgroundColor: newStatus == 'aktif' ? Colors.green : Colors.orange,
        ),
      );
    }
  }

  /// Reklam sil
  void _deleteReklam(Map<String, dynamic> reklam) {
    final reklamBasligi = reklam['reklamBasligi'] as String? ?? 'Reklam';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reklam Sil'),
        content: Text('$reklamBasligi isimli reklamı silmek istediğinizden emin misiniz?\n\nBu işlem geri alınamaz!'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final reklamId = reklam['id'] as String?;
              if (reklamId != null) {
                try {
                  await HiveDatabaseService.deleteReklam(reklamId);
                  
                  Navigator.pop(context);
                  _loadReklamlar();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('$reklamBasligi silindi'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Reklam silinirken hata: $e'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
  }

  /// Reklam ekleme/düzenleme dialog'u
  void _showReklamDialog({Map<String, dynamic>? reklam}) {
    final isEdit = reklam != null;
    
    final reklamAdiController = TextEditingController(text: reklam?['reklamAdi'] ?? '');
    final reklamBasligiController = TextEditingController(text: reklam?['reklamBasligi'] ?? '');
    final reklamAciklamasiController = TextEditingController(text: reklam?['reklamAciklamasi'] ?? '');
    final reklamResmiController = TextEditingController(text: reklam?['reklamResmi'] ?? '');
    final reklamKoduController = TextEditingController(text: reklam?['reklamKodu'] ?? '');
    final hedefUrlController = TextEditingController(text: reklam?['hedefUrl'] ?? '');
    
    String selectedKategori = reklam?['reklamKategorisi'] ?? 'DİĞER';
    String selectedDurum = reklam?['durum'] ?? 'taslak';
    DateTime? baslangicTarihi;
    DateTime? bitisTarihi;
    
    if (reklam?['baslangicTarihi'] != null) {
      try {
        final baslangicStr = reklam?['baslangicTarihi'] as String?;
        if (baslangicStr != null) {
          baslangicTarihi = DateTime.parse(baslangicStr);
        }
      } catch (e) {
        // Hata durumunda null bırak
      }
    }
    
    if (reklam?['bitisTarihi'] != null) {
      try {
        final bitisStr = reklam?['bitisTarihi'] as String?;
        if (bitisStr != null) {
          bitisTarihi = DateTime.parse(bitisStr);
        }
      } catch (e) {
        // Hata durumunda null bırak
      }
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(isEdit ? 'Reklam Düzenle' : 'Yeni Reklam Ekle'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: reklamAdiController,
                    decoration: const InputDecoration(
                      labelText: 'Reklam Adı *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reklamBasligiController,
                    decoration: const InputDecoration(
                      labelText: 'Reklam Başlığı *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reklamAciklamasiController,
                    decoration: const InputDecoration(
                      labelText: 'Reklam Açıklaması',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reklamResmiController,
                    decoration: const InputDecoration(
                      labelText: 'Reklam Resmi URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com/image.jpg',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reklamKoduController,
                    decoration: const InputDecoration(
                      labelText: 'Reklam Kodu',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: hedefUrlController,
                    decoration: const InputDecoration(
                      labelText: 'Hedef URL',
                      border: OutlineInputBorder(),
                      hintText: 'https://example.com',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedKategori,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Kategori *',
                      border: OutlineInputBorder(),
                    ),
                    items: _kategoriler.map((kategori) {
                      return DropdownMenuItem(
                        value: kategori,
                        child: Text(
                          kategori,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setDialogState(() {
                        selectedKategori = value ?? 'DİĞER';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: selectedDurum,
                    decoration: const InputDecoration(
                      labelText: 'Durum *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'taslak', child: Text('Taslak')),
                      DropdownMenuItem(value: 'aktif', child: Text('Aktif')),
                      DropdownMenuItem(value: 'pasif', child: Text('Pasif')),
                    ],
                    onChanged: (value) {
                      setDialogState(() {
                        selectedDurum = value ?? 'taslak';
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          title: Text(baslangicTarihi == null
                              ? 'Başlangıç Tarihi'
                              : 'Başlangıç: ${baslangicTarihi!.day}/${baslangicTarihi!.month}/${baslangicTarihi!.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: baslangicTarihi ?? DateTime.now(),
                              firstDate: DateTime.now().subtract(const Duration(days: 365)),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                baslangicTarihi = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: EdgeInsets.zero,
                          title: Text(bitisTarihi == null
                              ? 'Bitiş Tarihi'
                              : 'Bitiş: ${bitisTarihi!.day}/${bitisTarihi!.month}/${bitisTarihi!.year}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: const Icon(Icons.calendar_today),
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: bitisTarihi ?? DateTime.now().add(const Duration(days: 30)),
                              firstDate: baslangicTarihi ?? DateTime.now(),
                              lastDate: DateTime.now().add(const Duration(days: 365)),
                            );
                            if (date != null) {
                              setDialogState(() {
                                bitisTarihi = date;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (reklamAdiController.text.isEmpty ||
                      reklamBasligiController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Lütfen zorunlu alanları doldurun'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }
                  
                  final now = DateTime.now();
                  final reklamId = reklam?['id'] as String? ??
                      'reklam_${now.millisecondsSinceEpoch}';
                  
                  final reklamData = {
                    'id': reklamId,
                    'reklamAdi': reklamAdiController.text.trim(),
                    'reklamBasligi': reklamBasligiController.text.trim(),
                    'reklamAciklamasi': reklamAciklamasiController.text.trim(),
                    'reklamResmi': reklamResmiController.text.trim().isEmpty
                        ? null
                        : reklamResmiController.text.trim(),
                    'reklamKodu': reklamKoduController.text.trim().isEmpty
                        ? null
                        : reklamKoduController.text.trim(),
                    'reklamKategorisi': selectedKategori,
                    'durum': selectedDurum,
                    'baslangicTarihi': baslangicTarihi?.toIso8601String(),
                    'bitisTarihi': bitisTarihi?.toIso8601String(),
                    'hedefUrl': hedefUrlController.text.trim().isEmpty
                        ? null
                        : hedefUrlController.text.trim(),
                    'tiklanmaSayisi': reklam?['tiklanmaSayisi'] ?? 0,
                    'gosterimSayisi': reklam?['gosterimSayisi'] ?? 0,
                    'maksimumButce': reklam?['maksimumButce'],
                    'harcananButce': reklam?['harcananButce'] ?? 0.0,
                    'olusturulmaTarihi': reklam?['olusturulmaTarihi'] ?? now.toIso8601String(),
                    'guncellenmeTarihi': now.toIso8601String(),
                    'olusturanKullaniciId': widget.adminEmail,
                    'hedefKitlesi': reklam?['hedefKitlesi'],
                    'priority': reklam?['priority'] ?? 1,
                  };
                  
                  await HiveDatabaseService.saveReklam(reklamData);
                  
                  Navigator.pop(context);
                  _loadReklamlar();
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(isEdit ? 'Reklam güncellendi' : 'Reklam eklendi'),
                        backgroundColor: const Color(0xFF059669),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF059669),
                  foregroundColor: Colors.white,
                ),
                child: Text(isEdit ? 'Kaydet' : 'Ekle'),
              ),
            ],
          );
        },
      ),
    );
  }
}

