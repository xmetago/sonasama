import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:convert';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../services/account_deletion_service.dart';
import '../services/hive_database_service.dart';
import '../models/settings_model.dart';
import '../theme/app_theme.dart';
import '../theme/seyir_tokens.dart';
import '../utils/country_display_utils.dart';
import '../utils/country_picker_extension.dart';
import '../widgets/delil_surface.dart';

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: WhoBoomTheme.light,
    darkTheme: WhoBoomTheme.dark,
    home: const HesapGizlilikAyarlariPage(),
  ));
}

class HesapGizlilikAyarlariPage extends StatefulWidget {
  final String? userEmail;
  final Future<SettingsModel> Function(String email)? settingsLoader;

  const HesapGizlilikAyarlariPage({
    super.key,
    this.userEmail,
    this.settingsLoader,
  });

  @override
  State<HesapGizlilikAyarlariPage> createState() => _HesapGizlilikAyarlariPageState();
}

class _HesapGizlilikAyarlariPageState extends State<HesapGizlilikAyarlariPage> {
  SettingsModel? _settings;
  bool _isLoading = true;
  bool _loadFailed = false;
  bool _needsLogin = false;
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImageFile;

  final TextEditingController _profileImageController = TextEditingController();
  final TextEditingController _philosophyController = TextEditingController();
  final TextEditingController _postrestantController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _languageController = TextEditingController();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _passwordFeedback;
  bool _passwordOk = false;
  bool _passwordBusy = false;
  bool _deletingAccount = false;

  static const List<String> _languages = ['Türkçe', 'English'];

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
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final email = widget.userEmail?.trim();
    if (email == null || email.isEmpty) {
      if (!mounted) return;
      setState(() {
        _settings = null;
        _isLoading = false;
        _loadFailed = false;
        _needsLogin = true;
      });
      return;
    }

    try {
      final settings = widget.settingsLoader != null
          ? await widget.settingsLoader!(email)
          : await HiveDatabaseService.getOrCreateSettings(email);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _profileImageController.text = settings.profileImageUrl ?? '';
        _philosophyController.text = settings.philosophy ?? '';
        _postrestantController.text = settings.postrestantAddress ?? '';
        _countryController.text = settings.country ?? '';
        _languageController.text = _canonicalLanguage(settings.language);
        _isLoading = false;
        _loadFailed = false;
        _needsLogin = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _settings = null;
        _isLoading = false;
        _loadFailed = true;
        _needsLogin = false;
      });
    }
  }

  String _canonicalLanguage(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return '';
    final lower = value.toLowerCase();
    if (lower == 'tr' ||
        lower == 'türkçe' ||
        lower == 'turkce' ||
        lower == 'turkish') {
      return 'Türkçe';
    }
    if (lower == 'en' || lower == 'english' || lower == 'ingilizce') {
      return 'English';
    }
    return value;
  }

  Future<void> _updatePrivacySetting(String key, bool value) async {
    if (widget.userEmail != null && _settings != null) {
      try {
        await HiveDatabaseService.updatePrivacySetting(widget.userEmail!, key, value);
        setState(() {
          _settings!.updatePrivacySetting(key, value);
        });
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayar güncellenirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _saveProfileInfo() async {
    if (widget.userEmail != null) {
      try {
        String? profileImageUrl;
        if (_selectedImageFile != null) {
          try {
            final bytes = await _selectedImageFile!.readAsBytes();
            final base64String = base64Encode(bytes);
            profileImageUrl = 'data:image/jpeg;base64,$base64String';
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Resim yüklenirken hata oluştu'),
                backgroundColor: SeyirTokens.reject,
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

        _selectedImageFile = null;
        await _loadSettings();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedildi')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profil bilgileri kaydedilirken hata oluştu')),
        );
      }
    }
  }

  Future<void> _confirmReset() async {
    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Varsayılanlara sıfırla'),
          content: const Text(
            'Tüm ayarlar varsayılan değerlere sıfırlanacak. Emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              style: TextButton.styleFrom(
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              ),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              ),
              child: const Text('Sıfırla'),
            ),
          ],
        );
      },
    );
    if (approved == true && mounted) {
      await _resetToDefaults();
    }
  }

  Future<void> _resetToDefaults() async {
    if (widget.userEmail != null) {
      try {
        await HiveDatabaseService.resetSettingsToDefaults(widget.userEmail!);
        _selectedImageFile = null;
        await _loadSettings();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar varsayılan değerlere sıfırlandı')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ayarlar sıfırlanırken hata oluştu')),
        );
      }
    }
  }

  Future<void> _changePassword() async {
    final auth = _maybeAuth();
    final email = widget.userEmail?.trim().toLowerCase();
    final signedIn = auth?.userEmail?.trim().toLowerCase();
    if (auth == null || signedIn == null || signedIn.isEmpty || signedIn != email) {
      setState(() {
        _passwordOk = false;
        _passwordFeedback = 'Giriş gerekli.';
      });
      return;
    }

    setState(() {
      _passwordBusy = true;
      _passwordFeedback = null;
    });
    final error = await auth.reauthenticateAndUpdatePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) return;
    setState(() {
      _passwordBusy = false;
      _passwordOk = error == null;
      _passwordFeedback = error ?? 'Şifre başarıyla değiştirildi.';
      if (error == null) {
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  AuthProvider? _maybeAuth() {
    try {
      return Provider.of<AuthProvider>(context, listen: false);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesap ve Gizlilik Ayarları')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_needsLogin) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesap ve Gizlilik Ayarları')),
        body: const Padding(
          padding: EdgeInsets.all(SeyirTokens.space4),
          child: DelilSoftEmpty(
            title: 'Giriş gerekli',
            message: 'Ayarları görmek için giriş yapın.',
            icon: Icons.lock_outline,
          ),
        ),
      );
    }

    if (_loadFailed || _settings == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Hesap ve Gizlilik Ayarları')),
        body: Padding(
          padding: const EdgeInsets.all(SeyirTokens.space4),
          child: DelilLoadError(
            message: 'Ayarlar yüklenemedi',
            onRetry: _loadSettings,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hesap ve Gizlilik Ayarları'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveProfileInfo,
            tooltip: 'Kaydet',
            style: _iconStyle(palette),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _confirmReset,
            tooltip: 'Varsayılanlara Sıfırla',
            style: _iconStyle(palette),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(SeyirTokens.space3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ayarBolumu('SEYİR DEFTERİMİ GÖRSÜN', [
              ayarSatiri('Arkadaşlar', 'seyir_arkadaslar'),
              ayarSatiri('Takipçiler', 'seyir_takipciler'),
              ayarSatiri('Davalılarım', 'seyir_davalllarim'),
              ayarSatiri('Herkes', 'seyir_herkes'),
            ]),
            ayarBolumu('ONLINE GÖRÜNME', [
              ayarSatiri('Arkadaşlar', 'online_arkadaslar'),
              ayarSatiri('Takipçiler', 'online_takipciler'),
              ayarSatiri('Davalarım', 'online_davalllarim'),
              ayarSatiri('Herkes', 'online_herkes'),
            ]),
            ayarBolumu('MESAJ KİMLER ATABİLSİN', [
              ayarSatiri('Arkadaşlar', 'mesaj_arkadaslar'),
              ayarSatiri('Takipçiler', 'mesaj_takipciler'),
              ayarSatiri('Davalarım', 'mesaj_davalllarim'),
              ayarSatiri('Herkes', 'mesaj_herkes'),
            ]),
            const SizedBox(height: SeyirTokens.space4),
            Text('PROFİL RESMİNİZ', style: palette.title()),
            const SizedBox(height: SeyirTokens.space2),
            Row(
              children: [
                GestureDetector(
                  onTap: _showImageSourceDialog,
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: palette.surfaceMuted,
                    backgroundImage: _profileImage(),
                    child: _profileImage() == null
                        ? Icon(Icons.account_circle, size: 40, color: palette.textMuted)
                        : null,
                  ),
                ),
                const SizedBox(width: SeyirTokens.space3),
                Expanded(
                  child: TextField(
                    controller: _profileImageController,
                    style: _inputStyle(palette),
                    decoration: _fieldDecoration(
                      palette,
                      hint: 'Profil Resmi Linki',
                      suffix: IconButton(
                        icon: const Icon(Icons.clear),
                        tooltip: 'Temizle',
                        style: _iconStyle(palette),
                        onPressed: () {
                          setState(() {
                            _profileImageController.clear();
                            _selectedImageFile = null;
                          });
                        },
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
                const SizedBox(width: SeyirTokens.space2),
                IconButton(
                  onPressed: _profileImageController.text.isNotEmpty || _selectedImageFile != null
                      ? _showImagePreview
                      : null,
                  icon: const Icon(Icons.remove_red_eye),
                  tooltip: 'Önizle',
                  style: _iconStyle(palette),
                ),
                IconButton(
                  onPressed: _showImageSourceDialog,
                  icon: const Icon(Icons.add_circle, color: SeyirTokens.accept),
                  tooltip: 'Resim Ekle',
                  style: _iconStyle(palette, foreground: SeyirTokens.accept),
                ),
              ],
            ),
            const SizedBox(height: SeyirTokens.space4),
            ayarBolumu('GENEL', [
              ayarSatiri('+18 Dava, Reklam', 'genel_18'),
              ayarSatiri('Bana Dava Açılsın', 'genel_davaacilsin'),
              ayarSatiri('Postrestant adresim', 'genel_postrestant'),
              ayarSatiri('Tanınmak', 'genel_tanimak'),
            ]),
            ayarBolumu('DAVETLER', [
              ayarSatiri('Eylem Davetleri', 'davet_eylem'),
              ayarSatiri('Dava Davetleri', 'davet_dava'),
              ayarSatiri('Arkadaşlık Davetleri', 'davet_arkadaslik'),
              ayarSatiri('7-Yargıç', 'davet_7yargic'),
            ]),
            Container(
              margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
              padding: const EdgeInsets.all(SeyirTokens.space4),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: SeyirTokens.radiusSmAll,
                border: Border.all(color: _crispBorder(palette)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ŞU ADLA GÖRÜN',
                    style: palette.title(color: palette.textSecondary),
                  ),
                  const SizedBox(height: SeyirTokens.space3),
                  RadioGroup<String>(
                    groupValue: _settings?.stringSettings['display_name_type'] ?? 'yargic_adim',
                    onChanged: (value) {
                      if (value != null) {
                        _updateDisplayNameType(value);
                      }
                    },
                    child: Column(
                      children: [
                        _buildRadioOption('Gizli Yargıç Adı', 'gizli_yargic'),
                        _buildRadioOption('Yargıç Adım', 'yargic_adim'),
                        _buildRadioOption('E-posta', 'eposta'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SeyirTokens.space4),
            Text('Felsefem', style: palette.body()),
            TextField(
              controller: _philosophyController,
              maxLines: 2,
              style: _inputStyle(palette),
              decoration: _fieldDecoration(palette, hint: 'Felsefenizi yazın...'),
            ),
            const SizedBox(height: SeyirTokens.space3),
            Text('Postrestant Adres', style: palette.body()),
            TextField(
              controller: _postrestantController,
              maxLines: 2,
              style: _inputStyle(palette),
              decoration: _fieldDecoration(palette, hint: 'Postane adresinizi yazın...'),
            ),
            const SizedBox(height: SeyirTokens.space3),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Ülke', style: palette.title()),
                const SizedBox(height: SeyirTokens.space2),
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
                    constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
                    padding: const EdgeInsets.symmetric(
                      horizontal: SeyirTokens.space4,
                      vertical: SeyirTokens.space3,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: _crispBorder(palette)),
                      borderRadius: SeyirTokens.radiusSmAll,
                      color: palette.card,
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _countryController.text.isNotEmpty
                          ? CountryDisplayUtils.getDisplayName(_countryController.text)
                          : 'Ülke seçiniz',
                      style: palette.body(
                        weight: FontWeight.w400,
                        color: _countryController.text.isNotEmpty
                            ? palette.textPrimary
                            : palette.textMuted,
                      ).copyWith(fontSize: SeyirTokens.typeTitle),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: SeyirTokens.space4),
            Text('Dil', style: palette.title()),
            const SizedBox(height: SeyirTokens.space2),
            _languageField(palette),
            const SizedBox(height: SeyirTokens.space4),
            _passwordSection(palette),
            const SizedBox(height: SeyirTokens.space4),
            ElevatedButton(
              onPressed: _saveProfileInfo,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
                padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
              ),
              child: const Text(
                'Tüm Değişiklikleri Kaydet',
                style: TextStyle(fontSize: SeyirTokens.typeTitle),
              ),
            ),
            const SizedBox(height: SeyirTokens.space6),
            _deleteAccountSection(palette),
          ],
        ),
      ),
    );
  }

  Widget _deleteAccountSection(SeyirPalette palette) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(SeyirTokens.space4),
      decoration: BoxDecoration(
        color: SeyirTokens.reject.withValues(alpha: palette.isDark ? 0.16 : 0.08),
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: SeyirTokens.reject.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HESABI SİL',
            style: palette.title(color: SeyirTokens.reject),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            'Kaydınız, davalarınız, delilleriniz, mesajlarınız, arkadaşlıklarınız ve tercihleriniz silinir. Bu işlem geri alınamaz.',
            style: palette.body(color: palette.textSecondary),
          ),
          const SizedBox(height: SeyirTokens.space3),
          OutlinedButton(
            key: const Key('delete-account'),
            onPressed: _deletingAccount ? null : _confirmDeleteAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: SeyirTokens.reject,
              side: const BorderSide(color: SeyirTokens.reject),
              minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
            ),
            child: _deletingAccount
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Hesabımı sil',
                    style: TextStyle(fontSize: SeyirTokens.typeTitle),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final email = widget.userEmail?.trim() ?? '';
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesabı silmek için oturum açın.')),
      );
      return;
    }

    final emailController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        var errorText = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final palette = SeyirPalette.of(context);
            return AlertDialog(
              title: Text(
                'Hesabı sil',
                style: palette.title(color: SeyirTokens.reject),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Onaylamak için e-posta adresinizi yazın. Bu işlem geri alınamaz.',
                    style: palette.body(),
                  ),
                  const SizedBox(height: SeyirTokens.space3),
                  TextField(
                    key: const Key('delete-account-email'),
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: InputDecoration(
                      hintText: 'E-posta adresiniz',
                      errorText: errorText.isEmpty ? null : errorText,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Vazgeç'),
                ),
                TextButton(
                  key: const Key('delete-account-confirm'),
                  onPressed: () {
                    final typed = emailController.text.trim().toLowerCase();
                    if (typed != email.toLowerCase()) {
                      setDialogState(() {
                        errorText = 'E-posta adresi eşleşmiyor.';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(true);
                  },
                  child: const Text(
                    'Hesabımı sil',
                    style: TextStyle(color: SeyirTokens.reject),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    emailController.dispose();
    if (confirmed != true || !mounted) return;

    final user = HiveDatabaseService.getRegistrationByEmail(email);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hesap kaydı bulunamadı.')),
      );
      return;
    }

    setState(() => _deletingAccount = true);
    try {
      final result = await AccountDeletionService.deleteAccount(
        userId: user.id,
        email: user.email,
      );
      if (!mounted) return;
      context.read<AuthProvider>().logout();
      if (result.remoteErrors.isNotEmpty) {
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Hesap silindi'),
            content: const Text(
              'Yerel hesabınız silindi. Bazı sohbet veya dosya kayıtları silinemedi.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Tamam'),
              ),
            ],
          ),
        );
      }
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute<void>(builder: (_) => const WhoBoomLoginPage()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _deletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hesap silinemedi. Lütfen tekrar deneyin.'),
          backgroundColor: SeyirTokens.reject,
        ),
      );
    }
  }

  Widget _languageField(SeyirPalette palette) {
    final selected = _canonicalLanguage(_languageController.text);
    final choices = <String>[
      ..._languages,
      if (selected.isNotEmpty && !_languages.contains(selected)) selected,
    ];
    return Container(
      key: const Key('settings-language'),
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
      padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
      decoration: BoxDecoration(
        border: Border.all(color: _crispBorder(palette)),
        borderRadius: SeyirTokens.radiusSmAll,
        color: palette.card,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selected.isEmpty ? null : selected,
          hint: Text(
            'Dil seçiniz',
            style: palette.body(weight: FontWeight.w400, color: palette.textMuted),
          ),
          dropdownColor: palette.card,
          iconEnabledColor: palette.textSecondary,
          style: _inputStyle(palette),
          items: [
            for (final language in choices)
              DropdownMenuItem<String>(
                value: language,
                child: Text(language, style: _inputStyle(palette)),
              ),
          ],
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _languageController.text = value;
            });
          },
        ),
      ),
    );
  }

  Widget _passwordSection(SeyirPalette palette) {
    final feedbackColor = _passwordOk
        ? (palette.isDark ? const Color(0xFF6EE7B7) : SeyirTokens.accept)
        : (palette.isDark ? const Color(0xFFFCA5A5) : SeyirTokens.reject);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
      padding: const EdgeInsets.all(SeyirTokens.space2),
      decoration: BoxDecoration(
        border: Border.all(color: _tealBorder(palette)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('ŞİFRE DEĞİŞTİR', style: palette.title()),
          const SizedBox(height: SeyirTokens.space2),
          Text('Mevcut şifre', style: palette.body()),
          TextField(
            key: const Key('password-current'),
            controller: _currentPasswordController,
            obscureText: true,
            style: _inputStyle(palette),
            decoration: _fieldDecoration(palette, hint: 'Mevcut şifreniz'),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text('Yeni şifre', style: palette.body()),
          TextField(
            key: const Key('password-new'),
            controller: _newPasswordController,
            obscureText: true,
            style: _inputStyle(palette),
            decoration: _fieldDecoration(palette, hint: 'Yeni şifreniz'),
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text('Yeni şifre tekrar', style: palette.body()),
          TextField(
            key: const Key('password-confirm'),
            controller: _confirmPasswordController,
            obscureText: true,
            style: _inputStyle(palette),
            decoration: _fieldDecoration(palette, hint: 'Yeni şifrenizi tekrar yazın'),
          ),
          const SizedBox(height: SeyirTokens.space3),
          ElevatedButton(
            key: const Key('password-submit'),
            onPressed: _passwordBusy ? null : _changePassword,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(double.infinity, SeyirTokens.tapTarget),
              padding: const EdgeInsets.symmetric(vertical: SeyirTokens.space3),
            ),
            child: _passwordBusy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Şifreyi güncelle',
                    style: TextStyle(fontSize: SeyirTokens.typeTitle),
                  ),
          ),
          if (_passwordFeedback != null) ...[
            const SizedBox(height: SeyirTokens.space2),
            Text(
              _passwordFeedback!,
              key: const Key('password-feedback'),
              textAlign: TextAlign.center,
              style: palette.body(weight: FontWeight.w400, color: feedbackColor),
            ),
          ],
        ],
      ),
    );
  }

  Color _crispBorder(SeyirPalette palette) {
    return palette.isDark ? SeyirTokens.neutral400 : palette.border;
  }

  Color _tealBorder(SeyirPalette palette) {
    return palette.isDark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E);
  }

  TextStyle _inputStyle(SeyirPalette palette) {
    return palette.body(weight: FontWeight.w400).copyWith(
      fontSize: SeyirTokens.typeTitle,
    );
  }

  ButtonStyle _iconStyle(SeyirPalette palette, {Color? foreground}) {
    return IconButton.styleFrom(
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: foreground ?? palette.textPrimary,
    );
  }

  InputDecoration _fieldDecoration(
    SeyirPalette palette, {
    String? hint,
    Widget? suffix,
  }) {
    final side = BorderSide(color: _crispBorder(palette));
    return InputDecoration(
      hintText: hint,
      hintStyle: palette.body(weight: FontWeight.w400, color: palette.textMuted),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space4,
        vertical: SeyirTokens.space3,
      ),
      border: OutlineInputBorder(borderRadius: SeyirTokens.radiusSmAll, borderSide: side),
      enabledBorder: OutlineInputBorder(borderRadius: SeyirTokens.radiusSmAll, borderSide: side),
      focusedBorder: OutlineInputBorder(
        borderRadius: SeyirTokens.radiusSmAll,
        borderSide: BorderSide(color: _tealBorder(palette), width: 2),
      ),
    );
  }

  Widget ayarBolumu(String baslik, List<Widget> cocuklar) {
    final palette = SeyirPalette.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space2),
      padding: const EdgeInsets.all(SeyirTokens.space2),
      decoration: BoxDecoration(
        border: Border.all(color: _tealBorder(palette)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(baslik, style: palette.title()),
          ...cocuklar,
        ],
      ),
    );
  }

  Widget ayarSatiri(String etiket, String key) {
    final palette = SeyirPalette.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
      child: Row(
        children: [
          Expanded(child: Text(etiket, style: palette.body())),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Switch(
                value: _settings?.privacySettings[key] ?? true,
                materialTapTargetSize: MaterialTapTargetSize.padded,
                activeThumbColor: SeyirTokens.accept,
                activeTrackColor: SeyirTokens.accept.withValues(alpha: 0.45),
                onChanged: (val) {
                  _updatePrivacySetting(key, val);
                },
              ),
              Text('OK', style: palette.body(color: palette.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioOption(String label, String value) {
    final palette = SeyirPalette.of(context);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: SeyirTokens.space1),
      constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
      child: Row(
        children: [
          Radio<String>(
            value: value,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            activeColor: SeyirTokens.accept,
          ),
          const SizedBox(width: SeyirTokens.space2),
          Expanded(
            child: Text(label, style: palette.body()),
          ),
        ],
      ),
    );
  }

  Future<void> _updateDisplayNameType(String newType) async {
    final email = widget.userEmail;
    if (email == null) return;
    try {
      final settings = await HiveDatabaseService.getOrCreateSettings(email);
      settings.stringSettings['display_name_type'] = newType;
      await HiveDatabaseService.saveSettings(settings);
      await _loadSettings();
    } catch (e) {
      // Hata durumunda işlem yapma
    }
  }

  ImageProvider<Object>? _profileImage() {
    if (_selectedImageFile != null) {
      return FileImage(_selectedImageFile!);
    }
    return profileImageFromStored(_profileImageController.text);
  }

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
                leading: const Icon(Icons.photo_library, color: Color(0xFF2563EB)),
                title: const Text('Galeriden Seç'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: SeyirTokens.accept),
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
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resim seçildi. Kaydetmek için "Tüm Değişiklikleri Kaydet" butonuna basın.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Resim seçilemedi.'),
          backgroundColor: SeyirTokens.reject,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showImagePreview() {
    final provider = _profileImage();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final palette = SeyirPalette.of(context);
        return Dialog(
          child: Container(
            padding: const EdgeInsets.all(SeyirTokens.space4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Profil Resmi Önizleme', style: palette.headline()),
                const SizedBox(height: SeyirTokens.space4),
                ClipOval(
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      shape: BoxShape.circle,
                    ),
                    child: provider == null
                        ? Icon(Icons.account_circle, size: 100, color: palette.textMuted)
                        : Image(
                            image: provider,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(Icons.error, size: 50, color: palette.textMuted);
                            },
                          ),
                  ),
                ),
                const SizedBox(height: SeyirTokens.space4),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
                  ),
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

/// Kayıtlı profil resmini çözer. Base64 veri adresi bellekten, http adresi ağdan okunur.
ImageProvider<Object>? profileImageFromStored(String? raw) {
  if (raw == null || raw.isEmpty) return null;
  if (raw.startsWith('data:image')) {
    try {
      final parts = raw.split(',');
      if (parts.length < 2) return null;
      final bytes = base64Decode(parts[1]);
      if (bytes.isEmpty) return null;
      return MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return NetworkImage(raw);
  }
  return null;
}
