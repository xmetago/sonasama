import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/registration_model.dart';
import '../screens/delil_ekle_page.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import 'modern_dava_form_widgets.dart';

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

/// Varsayılan silüet bir profil fotoğrafı sayılmaz.
const String _placeholderProfileAsset = 'lib/icons/07_profil_picture_davaci.png';

/// Açık temada mevcut gri/beyaz yüzeyler, koyu temada [SeyirPalette].
class _CaseTone {
  const _CaseTone(this.palette);

  final SeyirPalette palette;

  bool get dark => palette.isDark;

  Color get sectionFill => dark ? palette.surfaceMuted : const Color(0xFFFAFAFA);
  Color get sectionBorder => dark ? palette.border : const Color(0xFFEEEEEE);
  Color get label => dark ? palette.textSecondary : const Color(0xFF9E9E9E);
  Color get field => dark ? palette.card : const Color(0xFFFFFFFF);
  Color get fieldMuted => dark ? palette.surfaceMuted : const Color(0xFFFAFAFA);
  Color get fieldBorder => dark ? palette.border : const Color(0xFFE0E0E0);
  Color get fieldBorderStrong => dark ? palette.border : const Color(0xFFBDBDBD);
  Color get ink => dark ? palette.textPrimary : const Color(0xDD000000);
  Color get inkMuted => dark ? palette.textSecondary : const Color(0xFF757575);
  Color get hint => dark ? palette.textMuted : const Color(0xFF9E9E9E);
  Color get hintFaint => dark ? palette.textMuted : const Color(0xFFBDBDBD);
  Color get title => dark ? palette.textPrimary : const Color(0xFF424242);
  Color get body => dark ? palette.textPrimary : const Color(0xFF1A1A1A);
  Color get focus => dark ? SeyirTokens.brand : const Color(0xFF059669);
  Color get suggestion => dark ? palette.card : const Color(0xFFFFFFFF);
  Color get disabledFill => dark ? palette.surfaceMuted : const Color(0xFFF5F5F5);
  Color get counterMuted => dark ? palette.textMuted : const Color(0xFF9CA3AF);
  Color get davalaOffBg => dark ? palette.surfaceMuted : SeyirTokens.neutral200;
  Color get davalaOffFg => dark ? palette.textPrimary : SeyirTokens.neutral700;
  Color get saveIcon => dark ? palette.textPrimary : const Color(0xFF455A64);
  Color get saveBg =>
      dark ? palette.surfaceMuted : const Color(0xFF455A64).withValues(alpha: 0.10);
  Color get addIcon => dark ? SeyirTokens.brand : const Color(0xFF1976D2);
  Color get addBg => dark ? palette.brandSoft : const Color(0xFF1976D2).withValues(alpha: 0.10);
  Color get iconOff => palette.textSecondary;
  Color get iconOffBg => dark ? palette.surfaceMuted : const Color(0xFF9E9E9E).withValues(alpha: 0.16);

  static const TextStyle labelStyleBase = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.bold,
  );

  TextStyle labelStyle() => labelStyleBase.copyWith(color: label);

  static const double labelWidth = 76;
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
  final bool showDavaAdiError;
  final String? davaAdiErrorText;
  final bool showDavaliError;
  final String? davaliErrorText;
  final FocusNode davaliFocusNode;

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
    required this.showDavaAdiError,
    required this.davaAdiErrorText,
    required this.showDavaliError,
    required this.davaliErrorText,
    required this.davaliFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final tone = _CaseTone(SeyirPalette.of(context));
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
              // Davacı solda, seçilen davalı sağda. Gerçek fotoğraf yoksa silüet.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _MemberAvatar(
                    token: userEmail ?? '',
                    load: () => _loadProfileByEmail(userEmail),
                  ),
                  _MemberAvatar(
                    token: davaliController.text,
                    load: () => _loadDavaliProfile(davaliController.text),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 1-Davacı, 2-Dava Adı, 3-Davalı, 4-Kategori — alt alta, estetik blok
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: tone.sectionFill,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: tone.sectionBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Davacı
                    _buildDavaciRow(context),
                    const SizedBox(height: 10),
                    // 2. Dava Adı
                    _buildInfoRow(context, 'Dava Adı', dava.adi, true),
                    const SizedBox(height: 10),
                    // 3. Davalı
                    _buildDavaliRow(context),
                    const SizedBox(height: 10),
                    // 4. Kategori (sadece metin, input değil)
                    if (dava.davaKategorisi.isNotEmpty) ...[
                      _buildKategoriRow(context, dava.davaKategorisi),
                      const SizedBox(height: 10),
                    ],
                    // Dava Açılış Tarihi — sadece dava açıldıysa
                    if (dava.isOpened) _buildInfoRow(context, 'Dava Açılış Tarihi', dava.kalanSure, false),
                  ],
                ),
              ),

              // Expanded Content - TAM GENİŞLİK
              if (isExpanded) ...[
                const SizedBox(height: 12),

                // Dava Konusu - Sade, geniş metin alanı (min 285, max 6346)
                Padding(
                  padding: const EdgeInsets.only(left: 0, right: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'Dava Konusu',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: tone.title,
                          ),
                        ),
                      ),
                      Stack(
                        children: [
                          TextField(
                            controller: davaDetayController,
                            maxLines: 16,
                            maxLength: 77401,
                            enabled: !dava.isOpened,
                            decoration: InputDecoration(
                              hintText: 'Davanızı detaylı anlatın (en az 285, en fazla 77401 karakter)',
                              hintStyle: TextStyle(
                                fontSize: 14,
                                color: tone.hint,
                              ),
                              filled: true,
                              fillColor: dava.isOpened ? tone.disabledFill : tone.fieldMuted,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: tone.fieldBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: tone.fieldBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: tone.focus, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              counterText: '', // 0/6346 göstergesi kaldırıldı, alan daha geniş
                            ),
                            style: TextStyle(fontSize: 15, height: 1.4, color: tone.body),
                            onChanged: (value) {},
                          ),
                          Positioned(
                            right: 10,
                            bottom: 8,
                            child: IgnorePointer(
                              child: Text(
                                '${davaDetayController.text.length} / 285',
                                style: TextStyle(
                                  fontSize: 11,
                                  height: 1,
                                  fontWeight: FontWeight.w500,
                                  color: davaDetayController.text.length >= 285
                                      ? SeyirTokens.brand
                                      : tone.counterMuted,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    ],
                  ),
                ),

                const SizedBox(height: 4),

                // Kaydet · Delil Ekle (ikon) · Davala — daha uyumlu, sade aksiyon stilleri
                Row(
                  children: [
                    Tooltip(
                      message: 'Kaydet',
                      child: IconButton(
                        onPressed: !dava.isOpened ? onSaveDava : null,
                        icon: const Icon(Icons.save_outlined, size: 24),
                        style: _actionIconStyle(
                          tone,
                          enabled: !dava.isOpened,
                          foreground: tone.saveIcon,
                          background: tone.saveBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: 'Delil Ekle',
                      child: IconButton(
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
                        icon: const Icon(Icons.add_circle_outline_outlined, size: 24),
                        style: _actionIconStyle(
                          tone,
                          enabled: !dava.isOpened,
                          foreground: tone.addIcon,
                          background: tone.addBg,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (canDavala && !dava.isOpened) ? onOpenDava : null,
                        icon: const Icon(Icons.gavel_outlined, size: 19),
                        label: Text(
                          'DAVALA',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            fontFamily: Theme.of(context).textTheme.bodyLarge?.fontFamily,
                          ),
                        ),
                        style: _davalaButtonStyle(
                          tone,
                          canDavala && !dava.isOpened,
                          Theme.of(context).textTheme.bodyLarge?.fontFamily,
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

  ButtonStyle _actionIconStyle(
    _CaseTone tone, {
    required bool enabled,
    required Color foreground,
    required Color background,
  }) {
    return IconButton.styleFrom(
      foregroundColor: foreground,
      disabledForegroundColor: tone.iconOff,
      backgroundColor: enabled ? background : tone.iconOffBg,
      disabledBackgroundColor: tone.iconOffBg,
      padding: const EdgeInsets.all(10),
      minimumSize: const Size(48, 48),
      fixedSize: const Size(48, 48),
      maximumSize: const Size(48, 48),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  ButtonStyle _davalaButtonStyle(_CaseTone tone, bool enabled, String? fontFamily) {
    final Color enabledFg = tone.palette.onSolid(SeyirTokens.brand);
    return ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return tone.davalaOffBg;
        }
        return SeyirTokens.brand;
      }),
      foregroundColor: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) {
          return tone.davalaOffFg;
        }
        return enabledFg;
      }),
      elevation: WidgetStateProperty.resolveWith((states) {
        if (!enabled || states.contains(WidgetState.disabled)) return 0;
        return 2;
      }),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      ),
      minimumSize: const WidgetStatePropertyAll(Size(120, 48)),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      textStyle: WidgetStatePropertyAll(
        TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          fontFamily: fontFamily,
        ),
      ),
      overlayColor: WidgetStatePropertyAll(
        SeyirTokens.neutral900.withValues(alpha: 0.06),
      ),
    );
  }

  /// 1. Davacı — alt alta sırada birinci alan (estetik, diğer satırlarla hizalı).
  Widget _buildDavaciRow(BuildContext context) {
    final tone = _CaseTone(SeyirPalette.of(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _CaseTone.labelWidth,
          child: Text(
            'Davacı: ',
            style: tone.labelStyle(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FutureBuilder<String>(
            future: _getDisplayName(userEmail),
            builder: (context, snapshot) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                constraints: const BoxConstraints(minHeight: 36),
                decoration: BoxDecoration(
                  color: tone.field,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tone.fieldBorder),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  snapshot.data ?? 'Bilinmeyen Yargıç',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: tone.ink,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 4. Kategori — input değil, sadece metin; diğer etiketlerle aynı stil ve genişlik.
  Widget _buildKategoriRow(BuildContext context, String kategoriValue) {
    final tone = _CaseTone(SeyirPalette.of(context));
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _CaseTone.labelWidth,
          child: Text(
            'Kategori: ',
            style: tone.labelStyle(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kategoriValue,
            style: TextStyle(
              fontSize: 12,
              color: tone.dark ? tone.ink : const Color(0xFF424242),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDavaliRow(BuildContext context) {
    final tone = _CaseTone(SeyirPalette.of(context));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: _CaseTone.labelWidth,
              child: Text(
                'Davalı: ',
                style: tone.labelStyle(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: !dava.isOpened
                  ? SizedBox(
                height: 36, // Daha az yer kaplasın
                child: TextField(
                  controller: davaliController,
                  focusNode: davaliFocusNode,
                  // Türkçe karakter desteği - tüm karakterleri kabul et
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
                  ],
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: tone.ink),
                  decoration: InputDecoration(
                    hintText: isWhoboomUser ? 'Üye ara (en az 4 harf)' : 'Bir isim yaz',
                    hintStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: tone.hint,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tone.fieldBorderStrong, width: 1.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: tone.fieldBorderStrong, width: 1.5),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(
                        color: tone.dark ? SeyirTokens.brand : const Color(0xFF1E88E5),
                        width: 2,
                      ),
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    filled: true,
                    fillColor: tone.fieldMuted,
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
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: tone.fieldMuted,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: tone.fieldBorderStrong, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      dava.davali,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: tone.inkMuted,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (showDavaliError && davaliErrorText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: _CaseTone.labelWidth),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: tone.dark ? tone.palette.brandSoft : const Color(0xFFEFFDF4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF16A34A)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_upward,
                        size: 18,
                        color: Color(0xFF16A34A),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          davaliErrorText!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF166534),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
        // Kullanıcı önerileri - sadece checkbox işaretli ve 4+ karakter yazıldığında göster
        // Ayrıca, eğer TextField içeriği zaten listede olan tam bir isme eşitse listeyi gösterme
        if (showUserSuggestions &&
            isWhoboomUser &&
            !dava.isOpened &&
            !filteredUsers.contains(davaliController.text)) ...[
          const SizedBox(height: 8),
          Container(
            margin: const EdgeInsets.only(left: _CaseTone.labelWidth + 8),
            decoration: BoxDecoration(
              color: tone.suggestion,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: tone.fieldBorder, width: 1),
              boxShadow: [
                BoxShadow(
                  color: tone.palette.shadow,
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

  /// Davacı: e-posta ile ayar ve kayıttaki gerçek profil fotoğrafı.
  Future<ImageProvider<Object>?> _loadProfileByEmail(String? email) async {
    final value = email?.trim() ?? '';
    if (value.isEmpty) return null;
    try {
      final settings = HiveDatabaseService.getSettings(value);
      final user = HiveDatabaseService.getRegistrationByEmail(value);
      final raw = _realProfilePhoto(settings?.profileImageUrl, user?.profileImage);
      return _profileImageProvider(raw);
    } catch (_) {
      return null;
    }
  }

  /// Davalı: seçilen üyenin e-posta veya id'sinden aynı fotoğraf yolu.
  /// Seçim yoksa, eşleşme yoksa veya hata olursa silüet gösterilir.
  Future<ImageProvider<Object>?> _loadDavaliProfile(String raw) async {
    try {
      final email = _emailForDavali(raw);
      if (email == null) return null;
      return await _loadProfileByEmail(email);
    } catch (_) {
      return null;
    }
  }

  String? _emailForDavali(String raw) {
    final key = raw.trim();
    if (key.isEmpty) return null;
    if (key.contains('@')) {
      final exact = HiveDatabaseService.getRegistrationByEmail(key);
      if (exact != null) return exact.email;
      final lower = key.toLowerCase();
      for (final RegistrationModel user in HiveDatabaseService.getAllRegistrations()) {
        if (user.email.toLowerCase() == lower) return user.email;
      }
      return key;
    }
    final byName = HiveDatabaseService.getRegistrationByJudgeName(key);
    if (byName != null) return byName.email;
    for (final RegistrationModel user in HiveDatabaseService.getAllRegistrations()) {
      if (user.id == key) return user.email;
    }
    return null;
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

  Widget _buildInfoRow(BuildContext context, String label, String value, bool isEditable) {
    final bool isDavaAdiField = label == 'Dava Adı';
    final tone = _CaseTone(SeyirPalette.of(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: _CaseTone.labelWidth,
              child: Text(
                '$label: ',
                style: tone.labelStyle(),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: isEditable && !dava.isOpened
                  ? SizedBox(
                      height: 36,
                      child: TextField(
                        controller: isDavaAdiField ? davaAdiController : null,
                        maxLength: isDavaAdiField ? 171 : null,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
                        ],
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tone.ink),
                        decoration: InputDecoration(
                          hintText: value,
                          hintStyle: TextStyle(color: tone.hintFaint, fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: tone.dark ? tone.focus : const Color(0xFF81C784)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: tone.fieldBorder),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: tone.focus, width: 2),
                          ),
                          filled: true,
                          fillColor: tone.field,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          counterText: '',
                          isDense: true,
                          suffix: isDavaAdiField
                              ? SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: FittedBox(
                                    fit: BoxFit.contain,
                                    child: CharacterCounterBadge(
                                      current: davaAdiController.text.length,
                                      max: 171,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                      constraints: const BoxConstraints(minHeight: 36),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: tone.dark
                              ? [tone.disabledFill, tone.fieldMuted]
                              : const [Color(0xFFF5F5F5), Color(0xFFFAFAFA)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: tone.fieldBorder),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !dava.isOpened ? tone.ink : tone.inkMuted,
                        ),
                      ),
                    ),
            ),
          ],
        ),
        if (isDavaAdiField && showDavaAdiError && davaAdiErrorText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: _CaseTone.labelWidth),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: tone.dark ? tone.palette.brandSoft : const Color(0xFFEFFDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF16A34A)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.arrow_upward,
                            size: 18,
                            color: Color(0xFF16A34A),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              davaAdiErrorText!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF166534),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Yarıçap 22 daire. Fotoğraf yokken 36px silüet, nötr zemin.
/// [token] değişince (başka davalı seçilince) fotoğraf yeniden okunur.
class _MemberAvatar extends StatefulWidget {
  const _MemberAvatar({required this.token, required this.load});

  final String token;
  final Future<ImageProvider<Object>?> Function() load;

  @override
  State<_MemberAvatar> createState() => _MemberAvatarState();
}

class _MemberAvatarState extends State<_MemberAvatar> {
  late Future<ImageProvider<Object>?> _future;

  @override
  void initState() {
    super.initState();
    _future = widget.load();
  }

  @override
  void didUpdateWidget(_MemberAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.token != widget.token) {
      _future = widget.load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tone = _CaseTone(SeyirPalette.of(context));
    final Color background = tone.dark ? tone.palette.surface : Colors.grey[100]!;
    return FutureBuilder<ImageProvider<Object>?>(
      future: _future,
      builder: (context, snapshot) {
        final image = snapshot.data;
        return CircleAvatar(
          radius: 22,
          backgroundColor: background,
          child: ClipOval(
            child: image == null
                ? const _Silhouette()
                : Image(
                    image: image,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _Silhouette(),
                  ),
          ),
        );
      },
    );
  }
}

class _Silhouette extends StatelessWidget {
  const _Silhouette();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _placeholderProfileAsset,
      width: 36,
      height: 36,
      fit: BoxFit.cover,
    );
  }
}

String? _realProfilePhoto(String? primary, String? fallback) {
  for (final raw in [primary, fallback]) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty || value == _placeholderProfileAsset) continue;
    return value;
  }
  return null;
}

final Map<String, MemoryImage> _memoryImages = {};

ImageProvider<Object>? _profileImageProvider(String? raw) {
  if (raw == null) return null;
  if (raw.startsWith('data:image')) {
    try {
      final cached = _memoryImages[raw];
      if (cached != null) return cached;
      final parts = raw.split(',');
      if (parts.length < 2) return null;
      final bytes = base64Decode(parts[1]);
      if (bytes.isEmpty) return null;
      final image = MemoryImage(bytes);
      _memoryImages[raw] = image;
      return image;
    } catch (_) {
      return null;
    }
  }
  if (raw.startsWith('http://') || raw.startsWith('https://')) {
    return NetworkImage(raw);
  }
  if (raw.startsWith('assets/') || raw.startsWith('lib/')) {
    return AssetImage(raw);
  }
  return null;
}
