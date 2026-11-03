import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/delil_ekle_page.dart';
import '../services/hive_database_service.dart';
import '../utils/app_theme.dart';
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
              // Profil görseli (kompakt)
              Center(
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: Colors.grey[100],
                  child: userEmail != null
                      ? FutureBuilder<String?>(
                    future: _getUserProfileImage(userEmail!),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data != null) {
                        return Image.asset(
                          snapshot.data!,
                          width: 36,
                          height: 36,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'lib/icons/07_profil_picture_davaci.png',
                            width: 36,
                            height: 36,
                            fit: BoxFit.cover,
                          ),
                        );
                      }
                      return Image.asset(
                        'lib/icons/07_profil_picture_davaci.png',
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                      );
                    },
                  )
                      : Image.asset(
                    'lib/icons/07_profil_picture_davaci.png',
                    width: 36,
                    height: 36,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // 1-Davacı, 2-Dava Adı, 3-Davalı, 4-Kategori — alt alta, estetik blok
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[200]!, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Davacı
                    _buildDavaciRow(),
                    const SizedBox(height: 10),
                    // 2. Dava Adı
                    _buildInfoRow('Dava Adı', dava.adi, true),
                    const SizedBox(height: 10),
                    // 3. Davalı
                    _buildDavaliRow(),
                    const SizedBox(height: 10),
                    // 4. Kategori (sadece metin, input değil)
                    if (dava.davaKategorisi.isNotEmpty) ...[
                      _buildKategoriRow(dava.davaKategorisi),
                      const SizedBox(height: 10),
                    ],
                    // Dava Açılış Tarihi — sadece dava açıldıysa
                    if (dava.isOpened) _buildInfoRow('Dava Açılış Tarihi', dava.kalanSure, false),
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
                            color: Colors.grey[800],
                          ),
                        ),
                      ),
                      TextField(
                        controller: davaDetayController,
                        maxLines: 16,
                        maxLength: 77401,
                        enabled: !dava.isOpened,
                        decoration: InputDecoration(
                          hintText: 'Davanızı detaylı anlatın (en az 285, en fazla 77401 karakter)',
                          hintStyle: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          filled: true,
                          fillColor: dava.isOpened ? Colors.grey[100] : Colors.grey[50],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF059669), width: 1.5),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          counterText: '', // 0/6346 göstergesi kaldırıldı, alan daha geniş
                        ),
                        style: const TextStyle(fontSize: 15, height: 1.4),
                        onChanged: (value) {},
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
                        icon: Icon(
                          Icons.save_outlined,
                          size: 24,
                          color: !dava.isOpened ? Colors.blueGrey[700] : Colors.grey[500],
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: !dava.isOpened
                              ? Colors.blueGrey.withOpacity(0.10)
                              : Colors.grey.withOpacity(0.08),
                          padding: const EdgeInsets.all(10),
                          minimumSize: const Size(48, 48),
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
                        icon: Icon(
                          Icons.add_circle_outline_outlined,
                          size: 28,
                          color: !dava.isOpened ? Colors.blue[700] : Colors.grey[400],
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: !dava.isOpened ? Colors.blue.withOpacity(0.1) : null,
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: (canDavala && !dava.isOpened) ? onOpenDava : null,
                        icon: const Icon(Icons.gavel_outlined, size: 19),
                        label: const Text(
                          'DAVALA',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        style: (canDavala && !dava.isOpened)
                            ? AppTheme.accentButtonStyle.copyWith(
                          textStyle: MaterialStateProperty.all(const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                          minimumSize: MaterialStateProperty.all(const Size(120, 48)),
                        )
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

  /// 1. Davacı — alt alta sırada birinci alan (estetik, diğer satırlarla hizalı).
  Widget _buildDavaciRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            'Davacı: ',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
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
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                alignment: Alignment.centerLeft,
                child: Text(
                  snapshot.data ?? 'Bilinmeyen Yargıç',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
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

  /// 4. Kategori — input değil, sadece metin; küçük punto, diğer etiketlerle hizalı.
  Widget _buildKategoriRow(String kategoriValue) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 76,
          child: Text(
            'Kategori: ',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            kategoriValue,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[800],
            ),
          ),
        ),
      ],
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
                height: 36, // Daha az yer kaplasın
                child: TextField(
                  controller: davaliController,
                  focusNode: davaliFocusNode,
                  // Türkçe karakter desteği - tüm karakterleri kabul et
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
                  ],
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
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
                    contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
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
                height: 36,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!, width: 1.5),
                  ),
                  child: Center(
                    child: Text(
                      dava.davali,
                      style: TextStyle(
                        fontSize: 13,
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
        if (showDavaliError && davaliErrorText != null) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const SizedBox(width: 76),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFFDF4),
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
    final bool isDavaAdiField = label == 'Dava Adı';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              width: 76, // Sabit genişlik
              child: Text(
                '$label: ',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
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
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: value,
                          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.green[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: Colors.green, width: 2),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                          counterText: '',
                          isDense: true,
                          suffixIcon: isDavaAdiField
                              ? CharacterCounterBadge(
                                  current: davaAdiController.text.length,
                                  max: 171,
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
                          colors: [Colors.grey[100]!, Colors.grey[50]!],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        value,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: !dava.isOpened ? Colors.black87 : Colors.grey[600],
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
              const SizedBox(width: 76),
              const SizedBox(width: 8),
              Expanded(
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFFDF4),
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
