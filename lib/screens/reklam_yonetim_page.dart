import 'package:flutter/material.dart';
import 'package:its19/utils/feather_icons.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/admin_stat_card.dart';
import '../widgets/delil_surface.dart';

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
  bool _loading = true;
  String? _loadError;

  bool get _authorized => HiveDatabaseService.isAdmin(widget.adminEmail);

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
    _searchController.addListener(_filterReklamlar);
    if (_authorized) {
      _loadReklamlar();
    } else {
      _loading = false;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Reklamları Hive'dan yükle
  Future<void> _loadReklamlar() async {
    if (!_authorized) return;
    if (mounted && !_loading) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    try {
      final reklamlar = await HiveDatabaseService.getAllReklamlar();
      if (!mounted) return;
      setState(() {
        allReklamlar = reklamlar;
        _loading = false;
        _loadError = null;
      });
      _filterReklamlar();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = 'Reklamlar yüklenemedi.';
      });
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

  Color _green(SeyirPalette palette) =>
      palette.isDark ? SeyirTokens.brand : const Color(0xFF059669);

  BoxDecoration _mint(SeyirPalette palette) {
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: palette.isDark
            ? [
                const Color(0xFF06352A),
                Color.alphaBlend(
                  SeyirTokens.brand.withValues(alpha: 0.16),
                  palette.surface,
                ),
              ]
            : const [Color(0xFFF0FDFA), Color(0xFFD1FAE5)],
      ),
    );
  }

  ButtonStyle _iconTap(Color foreground) {
    return IconButton.styleFrom(
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: foreground,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final green = _green(palette);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text('Reklam Yönetimi', style: palette.headline(color: Colors.white)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          if (_authorized)
            IconButton(
              style: _iconTap(Colors.white),
              icon: const Icon(FeatherIcons.refreshCw),
              onPressed: _loadReklamlar,
              tooltip: 'Yenile',
            ),
        ],
      ),
      body: !_authorized
          ? const Padding(
              padding: EdgeInsets.all(SeyirTokens.space4),
              child: DelilSoftEmpty(
                title: 'Yetkiniz yok',
                message: 'Bu sayfayı yalnızca yöneticiler kullanabilir.',
                icon: Icons.lock_outline,
              ),
            )
          : Container(
              decoration: _mint(palette),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(SeyirTokens.space4),
                    child: Row(
                      children: [
                        Expanded(
                          child: _buildStatCard(
                            'Toplam',
                            '${allReklamlar.length}',
                            Icons.campaign,
                          ),
                        ),
                        const SizedBox(width: SeyirTokens.space2),
                        Expanded(
                          child: _buildStatCard(
                            'Aktif',
                            '${allReklamlar.where((r) => r['durum'] == 'aktif').length}',
                            Icons.check_circle,
                          ),
                        ),
                        const SizedBox(width: SeyirTokens.space2),
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
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
                    child: Column(
                      children: [
                        TextField(
                          controller: _searchController,
                          style: palette.body(),
                          decoration: InputDecoration(
                            hintText: 'Reklam ara (ad, başlık, kod, kategori)...',
                            hintStyle: palette.body(
                              color: palette.textMuted,
                              weight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(FeatherIcons.search, color: green),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    style: _iconTap(palette.textSecondary),
                                    icon: const Icon(Icons.clear),
                                    onPressed: _searchController.clear,
                                  )
                                : null,
                            filled: true,
                            fillColor: palette.surfaceMuted,
                            border: const OutlineInputBorder(borderRadius: SeyirTokens.radiusMdAll),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: SeyirTokens.radiusMdAll,
                              borderSide: BorderSide(color: palette.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: SeyirTokens.radiusMdAll,
                              borderSide: BorderSide(color: green, width: 1.4),
                            ),
                          ),
                        ),
                        const SizedBox(height: SeyirTokens.space3),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip('Tümü', 'all'),
                              const SizedBox(width: SeyirTokens.space2),
                              _buildFilterChip('Aktif', 'aktif'),
                              const SizedBox(width: SeyirTokens.space2),
                              _buildFilterChip('Pasif', 'pasif'),
                              const SizedBox(width: SeyirTokens.space2),
                              _buildFilterChip('Taslak', 'taslak'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: SeyirTokens.space4),
                  Expanded(child: _buildReklamList(palette)),
                ],
              ),
            ),
      floatingActionButton: _authorized
          ? FloatingActionButton.extended(
              onPressed: _addNewReklam,
              backgroundColor: const Color(0xFF059669),
              foregroundColor: Colors.white,
              extendedPadding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space4,
              ),
              icon: const Icon(Icons.add),
              label: const Text('Yeni Reklam'),
            )
          : null,
    );
  }

  Widget _buildReklamList(SeyirPalette palette) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: _green(palette)),
      );
    }
    if (_loadError != null) {
      return DelilLoadError(
        message: _loadError!,
        onRetry: _loadReklamlar,
      );
    }
    if (filteredReklamlar.isEmpty) {
      final query = _searchController.text.trim();
      return ListView(
        padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
        children: [
          DelilSoftEmpty(
            title: 'Reklam bulunamadı',
            message: query.isEmpty
                ? 'Henüz kayıtlı reklam yok.'
                : '"$query" için eşleşme yok.',
            icon: Icons.campaign_outlined,
          ),
        ],
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
      itemCount: filteredReklamlar.length,
      itemBuilder: (context, index) {
        return _buildReklamCard(filteredReklamlar[index]);
      },
    );
  }

  /// İstatistik kartı
  Widget _buildStatCard(String title, String value, IconData icon) {
    return AdminStatCard(title: title, value: value, icon: icon);
  }

  /// Filtre chip'i
  Widget _buildFilterChip(String label, String filterValue) {
    final palette = SeyirPalette.of(context);
    final green = _green(palette);
    final isSelected = _filterStatus == filterValue;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      materialTapTargetSize: MaterialTapTargetSize.padded,
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space2,
      ),
      onSelected: (selected) {
        setState(() {
          _filterStatus = filterValue;
          _filterReklamlar();
        });
      },
      backgroundColor: palette.surfaceMuted,
      selectedColor: green.withValues(alpha: 0.2),
      checkmarkColor: green,
      side: BorderSide(color: isSelected ? green : palette.border),
      labelStyle: palette.body(
        color: isSelected ? green : palette.textSecondary,
        weight: isSelected ? FontWeight.w700 : FontWeight.w500,
      ),
    );
  }

  /// Reklam kartı
  Widget _buildReklamCard(Map<String, dynamic> reklam) {
    final palette = SeyirPalette.of(context);
    final durum = reklam['durum'] as String? ?? 'taslak';
    final durumColor = durum == 'aktif'
        ? Colors.green
        : durum == 'pasif'
            ? Colors.red
            : Colors.orange;
    final durumText = palette.foreground(durumColor);

    return Card(
      color: palette.card,
      margin: const EdgeInsets.only(bottom: SeyirTokens.space3),
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        side: BorderSide(color: palette.border),
      ),
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
          style: palette.body(weight: FontWeight.w700),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: SeyirTokens.space1),
            Text(
              'Kategori: ${reklam['reklamKategorisi'] as String? ?? 'DİĞER'}',
              style: palette.body(weight: FontWeight.w400, color: palette.textSecondary),
            ),
            Text(
              'Kod: ${reklam['reklamKodu'] as String? ?? 'Kod yok'}',
              style: palette.body(weight: FontWeight.w400, color: palette.textSecondary),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeyirTokens.space2,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: palette.tint(durumColor),
                    borderRadius: SeyirTokens.radiusMdAll,
                    border: Border.all(color: palette.tintBorder(durumColor)),
                  ),
                  child: Text(
                    durum.toUpperCase(),
                    style: palette.caption(
                      color: durumText,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: SeyirTokens.space2),
                Text(
                  'Gösterim: ${reklam['gosterimSayisi'] ?? 0}',
                  style: palette.caption(),
                ),
                const SizedBox(width: SeyirTokens.space2),
                Text(
                  'Tıklama: ${reklam['tiklanmaSayisi'] ?? 0}',
                  style: palette.caption(),
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
            style: TextButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
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
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
            ),
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
                style: TextButton.styleFrom(
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                ),
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
                  minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                ),
                child: Text(isEdit ? 'Kaydet' : 'Ekle'),
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      reklamAdiController.dispose();
      reklamBasligiController.dispose();
      reklamAciklamasiController.dispose();
      reklamResmiController.dispose();
      reklamKoduController.dispose();
      hedefUrlController.dispose();
    });
  }
}

