import 'package:flutter/material.dart';
import 'package:country_picker/country_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import '../services/hive_database_service.dart';
import '../models/settings_model.dart';
import '../utils/country_display_utils.dart';
import '../utils/country_picker_extension.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    home: HesapGizlilikAyarlariPage(),
  ));
}

class HesapGizlilikAyarlariPage extends StatefulWidget {
  final String? userEmail;
  
  const HesapGizlilikAyarlariPage({super.key, this.userEmail});
  
  @override
  State<HesapGizlilikAyarlariPage> createState() => _HesapGizlilikAyarlariPageState();
}

class _HesapGizlilikAyarlariPageState extends State<HesapGizlilikAyarlariPage> {
  SettingsModel? _settings;
  bool _isLoading = true;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImageFile; // Seçilen yerel resim dosyası
  
  // Text controllers
  final TextEditingController _profileImageController = TextEditingController();
  final TextEditingController _philosophyController = TextEditingController();
  final TextEditingController _postrestantController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _profileImageController.dispose();
    _philosophyController.dispose();
    _postrestantController.dispose();
    _countryController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    if (widget.userEmail != null) {
      try {
        final settings = await HiveDatabaseService.getOrCreateSettings(widget.userEmail!);
        setState(() {
          _settings = settings;
          _profileImageController.text = settings.profileImageUrl ?? '';
          _philosophyController.text = settings.philosophy ?? '';
          _postrestantController.text = settings.postrestantAddress ?? '';
          _countryController.text = settings.country ?? '';
          _languageController.text = settings.language ?? '';
          _isLoading = false;
        });
      } catch (e) {
        // Ayarlar yüklenirken hata oluştu
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    if (widget.userEmail != null && _settings != null) {
      try {
        await HiveDatabaseService.updatePrivacySetting(widget.userEmail!, key, value);
        setState(() {
          _settings!.updatePrivacySetting(key, value);
        });
      } catch (e) {
        // Ayar güncellenirken hata oluştu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar güncellenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    if (widget.userEmail != null) {
      try {
        // Yerel dosya seçildiyse base64'e çevir
        String? profileImageUrl;
        if (_selectedImageFile != null) {
          try {
            final bytes = await _selectedImageFile!.readAsBytes();
            final base64String = base64Encode(bytes);
            // Base64 string'i data URI formatına çevir
            profileImageUrl = 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('❌ Resim yüklenirken hata: $e'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        } else if (_profileImageController.text.isNotEmpty) {
          profileImageUrl = _profileImageController.text;
        }
        
        await HiveDatabaseService.updateProfileInfo(
          widget.userEmail!,
          profileImageUrl: profileImageUrl,
          philosophy: _philosophyController.text.isNotEmpty ? _philosophyController.text : null,
          postrestantAddress: _postrestantController.text.isNotEmpty ? _postrestantController.text : null,
          country: _countryController.text.isNotEmpty ? _countryController.text : null,
          language: _languageController.text.isNotEmpty ? _languageController.text : null,
        );
        
        // Ayarları yeniden yükle
        await _loadSettings();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedildi')),
        );
      } catch (e) {
        // Profil bilgileri kaydedilirken hata oluştu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedilirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _resetToDefaults() async {
    if (widget.userEmail != null) {
      try {
        await HiveDatabaseService.resetSettingsToDefaults(widget.userEmail!);
        await _loadSettings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar varsayılan değerlere sıfırlandı')),
        );
      } catch (e) {
        // Ayarlar sıfırlanırken hata oluştu
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar sıfırlanırken hata oluştu')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hesap ve Gizlilik Ayarları")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Hesap ve Gizlilik Ayarları")),
        body: const Center(child: Text("Ayarlar yüklenemedi")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Hesap ve Gizlilik Ayarları"),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfileInfo,
            tooltip: "Kaydet",
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetToDefaults,
            tooltip: "Varsayılanlara Sıfırla",
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ayarBolumu("SEYİR DEFTERİMİ GÖRSÜN", [
              ayarSatiri("Arkadaşlar", "seyir_arkadaslar"),
              ayarSatiri("Takipçiler", "seyir_takipciler"),
              ayarSatiri("Davalllarım", "seyir_davalllarim"),
              ayarSatiri("Herkes", "seyir_herkes"),
            ]),
            ayarBolumu("ONLINE GÖRÜNME", [
              ayarSatiri("Arkadaşlar", "online_arkadaslar"),
              ayarSatiri("Takipçiler", "online_takipciler"),
              ayarSatiri("Davalllarım", "online_davalllarim"),
              ayarSatiri("Herkes", "online_herkes"),
            ]),
            ayarBolumu("MESAJ KİMLER ATABİLSİN", [
              ayarSatiri("Arkadaşlar", "mesaj_arkadaslar"),
              ayarSatiri("Takipçiler", "mesaj_takipciler"),
              ayarSatiri("Davalllarım", "mesaj_davalllarim"),
              ayarSatiri("Herkes", "mesaj_herkes"),
            ]),
            const SizedBox(height: 20),
            const Text("PROFİL RESMİNİZ", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                // Profil resmi CircleAvatar (common_header_widgets.dart'daki gibi)
                GestureDetector(
                  onTap: () => _showImageSourceDialog(),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: _getProfileImage(),
                    child: _getProfileImage() == null
                        ? const Icon(Icons.account_circle, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _profileImageController,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(), 
                      hintText: "Profil Resmi Linki",
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _profileImageController.clear();
                            _selectedImageFile = null;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        // URL değiştiğinde state'i güncelle
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                // Önizleme butonu
                IconButton(
                  onPressed: _profileImageController.text.isNotEmpty || _selectedImageFile != null
                      ? () => _showImagePreview()
                      : null,
                  icon: const Icon(Icons.remove_red_eye),
                  tooltip: "Önizle",
                ),
                // Resim ekleme butonu
                IconButton(
                  onPressed: () => _showImageSourceDialog(),
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  tooltip: "Resim Ekle",
                ),
              ],
            ),
            const SizedBox(height: 20),
            ayarBolumu("GENEL", [
              ayarSatiri("+18 Dava, Reklam", "genel_18"),
              ayarSatiri("Bana Dava Açılsın", "genel_davaacilsin"),
              ayarSatiri("Postrestant adresim", "genel_postrestant"),
              ayarSatiri("Tanımak", "genel_tanimak"),
            ]),
            ayarBolumu("DAVETLER", [
              ayarSatiri("Eylem Davetleri", "davet_eylem"),
              ayarSatiri("Dava Davetleri", "davet_dava"),
              ayarSatiri("Arkadaşlık Davetleri", "davet_arkadaslik"),
              ayarSatiri("7-Yargıç", "davet_7yargic"),
            ]),
            // ŞU ADLA GÖRÜN - Radio Button Mantığı
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "ŞU ADLA GÖRÜN",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildRadioOption("Gizli Yargıç Adı", "gizli_yargic", "adim_soyadim"),
                  _buildRadioOption("Yargıç Adım", "yargic_adim", "yargic_adim"),
                  _buildRadioOption("E-posta", "eposta", "eposta"),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Felsefem"),
            TextField(
              controller: _philosophyController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Felsefenizi yazın..."),
            ),
            const SizedBox(height: 10),
            const Text("Postrestant Adress:"),
            TextField(
              controller: _postrestantController,
              maxLines: 2,
              decoration: const InputDecoration(border: OutlineInputBorder(), hintText: "Postane adresinizi yazın..."),
            ),
            const SizedBox(height: 10),
            // Ülke Seçimi (country_picker ile)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Ülke", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () {
                    showCountryPickerWithKurdistan(
                      context: context,
                      showPhoneCode: false,
                      onSelect: (String countryName) {
                        setState(() {
                          _countryController.text = countryName;
                        });
                      },
                    );
                  },
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(minHeight: 48),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.white,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _countryController.text.isNotEmpty
                        ? CountryDisplayUtils.getDisplayName(_countryController.text)
                        : 'Ülke seçiniz',
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveProfileInfo,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              child: const Text("Tüm Değişiklikleri Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  Widget ayarBolumu(String baslik, List<Widget> cocuklar) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.teal, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: const TextStyle(fontWeight: FontWeight.bold)),
          ...cocuklar,
        ],
      ),
    );
  }

  Widget ayarSatiri(String etiket, String key) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(etiket),
        Row(
          children: [
            Switch(
              value: _settings?.privacySettings[key] ?? true, // Varsayılan olarak true (açık)
              onChanged: (val) {
                _updatePrivacySetting(key, val);
              },
            ),
            const Text("OK"),
          ],
        ),
      ],
    );
  }

  // Radio button seçeneği oluştur
  Widget _buildRadioOption(String label, String value, String settingKey) {
    final currentValue = _settings?.stringSettings['display_name_type'] ?? 'yargic_adim';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            groupValue: currentValue,
            onChanged: (newValue) {
              if (newValue != null) {
                _updateDisplayNameType(newValue);
              }
            },
            activeColor: Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // Görünüm adı tipini güncelle
  void _updateDisplayNameType(String newType) async {
    try {
      final settings = await HiveDatabaseService.getOrCreateSettings(widget.userEmail!);
      settings.stringSettings['display_name_type'] = newType;
      await HiveDatabaseService.saveSettings(settings);
      
      // Ayarları yeniden yükle
      await _loadSettings();
      
      setState(() {
        // State'i güncelle
      });
    } catch (e) {
      // Hata durumunda işlem yapma
    }
  }

  // Profil resmi görselini döndür
  ImageProvider? _getProfileImage() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    } else if (_profileImageController.text.isNotEmpty) {
      try {
        return NetworkImage(_profileImageController.text);
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // Resim kaynağı seçim dialog'u
  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Profil Resmi Seç'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library, color: Colors.blue),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text('Kameradan Çek'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Resim seçme fonksiyonu
  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _selectedImageFile = File(image.path);
          // Yerel dosya seçildiğinde URL'i temizle
          // Not: Yerel dosyaları veritabanına kaydetmek için base64 veya dosya yükleme servisi gerekebilir
          // Şimdilik sadece görsel olarak gösteriyoruz
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Resim seçildi. Kaydetmek için "Tüm Değişiklikleri Kaydet" butonuna basın.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Resim seçilemedi: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // Resim önizleme dialog'u
  void _showImagePreview() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Profil Resmi Önizleme',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ClipOval(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      shape: BoxShape.circle,
                    ),
                    child: _selectedImageFile != null
                        ? Image.file(
                            _selectedImageFile!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.error, size: 50);
                            },
                          )
                        : _profileImageController.text.isNotEmpty
                            ? Image.network(
                                _profileImageController.text,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(Icons.error, size: 50);
                                },
                              )
                            : const Icon(Icons.account_circle, size: 100),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Kapat'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
