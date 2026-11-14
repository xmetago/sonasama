import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../screens/delil_ekle_page.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';

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
  final String? davalaDisabledReason;

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
    this.davalaDisabledReason,
  });

  static const int _minDetail = 285;
  static const int _maxDetail = 77401;
  static const int _minName = 6;
  static const int _maxName = 171;

  int get _nameLength {
    if (davaAdiController.text.isNotEmpty) return davaAdiController.text.length;
    if (dava.adi.trim().isEmpty || dava.adi == 'Ad  ver ') return 0;
    return dava.adi.length;
  }

  bool get _davaliFilled {
    final text = davaliController.text;
    return text.isNotEmpty && text != 'Davalı  adını gir ';
  }

  bool get _detailFilled => davaDetayController.text.length >= _minDetail;

  int get _filledSections =>
      (_davaliFilled ? 1 : 0) +
      (_nameLength >= _minName ? 1 : 0) +
      (_detailFilled ? 1 : 0);

  bool get _showSelectedChip {
    if (!isWhoboomUser || dava.isOpened || showUserSuggestions) return false;
    final text = davaliController.text;
    if (text.isEmpty || text == 'Davalı  adını gir ') return false;
    return filteredUsers.contains(text);
  }

  String? _disabledReason() {
    if (dava.isOpened) return 'Dava açıldı';
    if (canDavala) return null;
    if (davalaDisabledReason != null && davalaDisabledReason!.isNotEmpty) {
      return davalaDisabledReason;
    }
    if (_nameLength < _minName) {
      return 'Davaya bir başlık vermelisin. Dava adını en az 6 karakter olacak şekilde doldur.';
    }
    if (!_davaliFilled) {
      return 'Davalı bilgisini doldurmalısın. Davalı adını girmeden kaydedemezsin.';
    }
    if (!_detailFilled) {
      return 'Davanızı detaylı anlatın (en az 285, en fazla 77401 karakter)';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        davaliController,
        davaAdiController,
        davaDetayController,
      ]),
      builder: (BuildContext context, Widget? _) {
        return Material(
          color: palette.card,
          elevation: 0,
          shadowColor: palette.shadow,
          shape: RoundedRectangleBorder(
            borderRadius: SeyirTokens.radiusLgAll,
            side: BorderSide(color: palette.border),
          ),
          child: InkWell(
            borderRadius: SeyirTokens.radiusLgAll,
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _progress(palette),
                  const SizedBox(height: SeyirTokens.space4),
                  _section(
                    palette: palette,
                    index: 1,
                    title: 'Davalı seçimi',
                    icon: Icons.person_search,
                    filled: _davaliFilled,
                    child: _davaliSection(context, palette),
                  ),
                  _section(
                    palette: palette,
                    index: 2,
                    title: 'Dava adı & kategori',
                    icon: Icons.edit_outlined,
                    filled: _nameLength >= _minName,
                    child: _nameSection(palette),
                  ),
                  _section(
                    palette: palette,
                    index: 3,
                    title: 'Dava detayı',
                    icon: Icons.notes_outlined,
                    filled: _detailFilled,
                    child: isExpanded
                        ? _detailSection(context, palette)
                        : _detailCounter(palette),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _progress(SeyirPalette palette) {
    final int filled = _filledSections;
    final Color accent =
        palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep;
    return Row(
      children: [
        Text(
          '$filled/3',
          style: palette.title(
            color: filled == 3 ? accent : palette.textSecondary,
          ),
        ),
        const SizedBox(width: SeyirTokens.space3),
        for (int i = 0; i < 3; i++) ...[
          Expanded(
            child: AnimatedContainer(
              duration: SeyirTokens.motion,
              curve: Curves.easeOutCubic,
              height: 4,
              decoration: BoxDecoration(
                color: i < filled ? SeyirTokens.brand : palette.border,
                borderRadius: SeyirTokens.radiusSmAll,
              ),
            ),
          ),
          if (i < 2) const SizedBox(width: SeyirTokens.space2),
        ],
      ],
    );
  }

  Widget _section({
    required SeyirPalette palette,
    required int index,
    required String title,
    required IconData icon,
    required bool filled,
    required Widget child,
  }) {
    final Color accent =
        palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep;
    return Container(
      margin: const EdgeInsets.only(bottom: SeyirTokens.space3),
      padding: const EdgeInsets.all(SeyirTokens.space3),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(
          color: filled
              ? palette.tintBorder(SeyirTokens.brand)
              : palette.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: filled ? palette.brandSoft : palette.card,
                  borderRadius: SeyirTokens.radiusSmAll,
                ),
                child: Text(
                  '$index',
                  style: palette.body(
                    weight: FontWeight.w800,
                    color: filled ? accent : palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(width: SeyirTokens.space2),
              Icon(
                icon,
                size: 18,
                color: filled ? accent : palette.textSecondary,
              ),
              const SizedBox(width: SeyirTokens.space2),
              Expanded(child: Text(title, style: palette.title())),
              if (filled)
                const Icon(
                  Icons.check_circle,
                  size: 18,
                  color: SeyirTokens.brand,
                ),
            ],
          ),
          const SizedBox(height: SeyirTokens.space3),
          child,
        ],
      ),
    );
  }

  Widget _fieldLabel(SeyirPalette palette, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: SeyirTokens.space2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: palette.textSecondary),
          const SizedBox(width: SeyirTokens.space2),
          Text(label, style: palette.body(weight: FontWeight.w700)),
        ],
      ),
    );
  }

  InputDecoration _decoration(
    SeyirPalette palette, {
    required String hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
    BoxConstraints? prefixIconConstraints,
    bool hasError = false,
  }) {
    final Color borderColor = hasError ? SeyirTokens.reject : palette.border;
    final OutlineInputBorder border = OutlineInputBorder(
      borderRadius: SeyirTokens.radiusMdAll,
      borderSide: BorderSide(color: borderColor),
    );
    return InputDecoration(
      hintText: hint,
      hintStyle: palette.body(color: palette.textMuted, weight: FontWeight.w500),
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixIconConstraints,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: dava.isOpened ? palette.surfaceMuted : palette.card,
      isDense: true,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space3,
        vertical: SeyirTokens.space3,
      ),
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: OutlineInputBorder(
        borderRadius: SeyirTokens.radiusMdAll,
        borderSide: BorderSide(
          color: hasError ? SeyirTokens.reject : SeyirTokens.brand,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _readOnlyBox(SeyirPalette palette, String value, {Widget? leading}) {
    return Container(
      constraints: const BoxConstraints(minHeight: SeyirTokens.tapTarget),
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space3,
        vertical: SeyirTokens.space2,
      ),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading,
            const SizedBox(width: SeyirTokens.space2),
          ],
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: palette.body(weight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _davaliSection(BuildContext context, SeyirPalette palette) {
    final bool nameError = showDavaliError && davaliErrorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(palette, 'Davacı', Icons.account_circle_outlined),
        FutureBuilder<String>(
          future: _getDisplayName(userEmail),
          builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
            return _readOnlyBox(
              palette,
              snapshot.data ?? 'Bilinmeyen Yargıç',
              leading: _partyAvatar(palette),
            );
          },
        ),
        const SizedBox(height: SeyirTokens.space3),
        _fieldLabel(palette, 'Davalı', Icons.person_outline),
        if (_showSelectedChip)
          _selectedChip(palette)
        else if (!dava.isOpened)
          TextField(
            controller: davaliController,
            focusNode: davaliFocusNode,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
            ],
            style: palette.body(weight: FontWeight.w700),
            decoration: _decoration(
              palette,
              hint: isWhoboomUser
                  ? 'üye ara... (en az 4 karakter)'
                  : 'Bir isim yaz',
              hasError: nameError,
              prefixIcon: _memberPrefix(palette),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 76, maxWidth: 76),
              suffixIcon: isWhoboomUser
                  ? Icon(
                      Icons.person_add,
                      size: 18,
                      color: palette.isDark
                          ? SeyirTokens.brand
                          : SeyirTokens.brandDeep,
                    )
                  : null,
            ),
          )
        else
          _readOnlyBox(palette, dava.davali),
        _SoftError(message: nameError ? davaliErrorText : null),
        if (showUserSuggestions &&
            isWhoboomUser &&
            !dava.isOpened &&
            !filteredUsers.contains(davaliController.text))
          _suggestions(palette),
      ],
    );
  }

  Widget _memberPrefix(SeyirPalette palette) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: SeyirTokens.space1),
        Checkbox(
          value: isWhoboomUser,
          onChanged: dava.isOpened ? null : onCheckboxChanged,
          activeColor: SeyirTokens.brand,
          checkColor: palette.onSolid(SeyirTokens.brand),
          visualDensity: VisualDensity.compact,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          side: BorderSide(color: palette.border, width: 1.5),
        ),
        Icon(
          isWhoboomUser ? Icons.person_search : Icons.badge_outlined,
          size: 18,
          color: palette.textSecondary,
        ),
      ],
    );
  }

  Widget _selectedChip(SeyirPalette palette) {
    final String name = davaliController.text;
    return Align(
      alignment: Alignment.centerLeft,
      child: InputChip(
        avatar: CircleAvatar(
          backgroundColor: palette.card,
          child: Text(
            _initial(name),
            style: palette.caption(
              weight: FontWeight.w800,
              color: palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep,
            ),
          ),
        ),
        label: Text(name, style: palette.body(weight: FontWeight.w700)),
        backgroundColor: palette.brandSoft,
        side: BorderSide(color: palette.tintBorder(SeyirTokens.brand)),
        deleteIconColor: palette.textSecondary,
        onDeleted: () {
          davaliController.clear();
          davaliFocusNode.requestFocus();
        },
      ),
    );
  }

  Widget _suggestions(SeyirPalette palette) {
    return Padding(
      padding: const EdgeInsets.only(top: SeyirTokens.space2),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: palette.card,
          borderRadius: SeyirTokens.radiusMdAll,
          border: Border.all(color: palette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: SeyirTokens.space3,
                vertical: SeyirTokens.space2,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_search,
                    size: 16,
                    color: palette.textSecondary,
                  ),
                  const SizedBox(width: SeyirTokens.space2),
                  Expanded(
                    child: Text(
                      'Önerilen Üyeler (${filteredUsers.length})',
                      style: palette.caption(weight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            if (filteredUsers.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  SeyirTokens.space3,
                  0,
                  SeyirTokens.space3,
                  SeyirTokens.space3,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: SeyirTokens.warning,
                    ),
                    const SizedBox(width: SeyirTokens.space2),
                    Expanded(
                      child: Text(
                        'Bu isimle eşleşen üye bulunamadı veya dava açılmasına izin vermiyor',
                        style: palette.caption(
                          color: SeyirTokens.warning,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            for (final String userName in filteredUsers)
              InkWell(
                onTap: () => onSelectUser(userName),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeyirTokens.space3,
                    vertical: SeyirTokens.space2,
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: palette.brandSoft,
                        child: Text(
                          _initial(userName),
                          style: palette.caption(
                            weight: FontWeight.w800,
                            color: palette.isDark
                                ? SeyirTokens.brand
                                : SeyirTokens.brandDeep,
                          ),
                        ),
                      ),
                      const SizedBox(width: SeyirTokens.space2),
                      Expanded(
                        child: Text(
                          userName,
                          style: palette.body(weight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _nameSection(SeyirPalette palette) {
    final bool nameError = showDavaAdiError && davaAdiErrorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(palette, 'Dava Adı', Icons.text_fields),
        if (!dava.isOpened)
          TextField(
            controller: davaAdiController,
            maxLength: _maxName,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\s\S]')),
            ],
            style: palette.body(weight: FontWeight.w600),
            decoration: _decoration(
              palette,
              hint: dava.adi,
              hasError: nameError,
              prefixIcon: Icon(
                Icons.gavel_outlined,
                size: 18,
                color: palette.textSecondary,
              ),
            ),
          )
        else
          _readOnlyBox(palette, dava.adi),
        _SoftError(message: nameError ? davaAdiErrorText : null),
        if (dava.davaKategorisi.isNotEmpty) ...[
          const SizedBox(height: SeyirTokens.space3),
          _fieldLabel(palette, 'Kategori', Icons.category_outlined),
          _readOnlyBox(palette, dava.davaKategorisi),
        ],
        if (dava.isOpened) ...[
          const SizedBox(height: SeyirTokens.space3),
          _fieldLabel(palette, 'Dava Açılış Tarihi', Icons.event_outlined),
          _readOnlyBox(palette, dava.kalanSure),
        ],
      ],
    );
  }

  Widget _detailSection(BuildContext context, SeyirPalette palette) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _fieldLabel(palette, 'Dava Konusu', Icons.subject),
        TextField(
          controller: davaDetayController,
          maxLines: 16,
          maxLength: _maxDetail,
          enabled: !dava.isOpened,
          onChanged: (String value) {},
          style: palette.body(),
          decoration: _decoration(
            palette,
            hint: 'Davanızı detaylı anlatın (en az 285, en fazla 77401 karakter)',
          ),
        ),
        const SizedBox(height: SeyirTokens.space2),
        _detailCounter(palette),
        const SizedBox(height: SeyirTokens.space4),
        _actions(context, palette),
      ],
    );
  }

  Widget _detailCounter(SeyirPalette palette) {
    final int length = davaDetayController.text.length;
    final bool reached = length >= _minDetail;
    final double progress = (length / _minDetail).clamp(0.0, 1.0);
    final Color ink =
        reached
            ? (palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep)
            : palette.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$length / $_minDetail',
          style: palette.caption(color: ink, weight: FontWeight.w700),
        ),
        const SizedBox(height: SeyirTokens.space1),
        ClipRRect(
          borderRadius: SeyirTokens.radiusSmAll,
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: palette.border,
            color: reached ? SeyirTokens.brand : palette.textSecondary,
          ),
        ),
      ],
    );
  }

  TextStyle _buttonLabel(BuildContext context, FontWeight weight) {
    return TextStyle(
      fontFamily: Theme.of(context).textTheme.bodyMedium?.fontFamily,
      fontSize: SeyirTokens.typeTitle,
      fontWeight: weight,
      height: 1.2,
    );
  }

  Widget _actions(BuildContext context, SeyirPalette palette) {
    final bool opened = dava.isOpened;
    final bool canOpen = canDavala && !opened;
    final String? reason = _disabledReason();
    final Color onBrand = palette.onSolid(SeyirTokens.brand);
    final Color outline =
        palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: opened ? null : onSaveDava,
                icon: const Icon(Icons.save_outlined, size: 20),
                label: const Text('Kaydet'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: outline,
                  disabledForegroundColor: palette.textMuted,
                  minimumSize: const Size(0, 52),
                  side: BorderSide(color: opened ? palette.border : outline),
                  shape: const RoundedRectangleBorder(
                    borderRadius: SeyirTokens.radiusLgAll,
                  ),
                  textStyle: _buttonLabel(context, FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: SeyirTokens.space3),
            Expanded(
              child: FilledButton.icon(
                onPressed: canOpen ? onOpenDava : null,
                icon: const Icon(Icons.gavel_outlined, size: 20),
                label: const Text('Davayı Aç'),
                style: FilledButton.styleFrom(
                  backgroundColor: SeyirTokens.brand,
                  foregroundColor: onBrand,
                  disabledBackgroundColor: palette.surfaceMuted,
                  disabledForegroundColor: palette.textMuted,
                  minimumSize: const Size(0, 52),
                  shape: const RoundedRectangleBorder(
                    borderRadius: SeyirTokens.radiusLgAll,
                  ),
                  textStyle: _buttonLabel(context, FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
        TextButton.icon(
          onPressed: opened
              ? null
              : () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (BuildContext context) => DelilEklePage(
                        userEmail: userEmail,
                        davaId: dava.id,
                        davaAdi: dava.adi,
                      ),
                    ),
                  );
                },
          icon: const Icon(Icons.add_circle_outline, size: 20),
          label: const Text('Delil Ekle'),
          style: TextButton.styleFrom(
            foregroundColor: palette.textSecondary,
            disabledForegroundColor: palette.textMuted,
            minimumSize: const Size(0, SeyirTokens.tapTarget),
          ),
        ),
        if (reason != null)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline, size: 16, color: palette.textSecondary),
              const SizedBox(width: SeyirTokens.space2),
              Expanded(child: Text(reason, style: palette.caption())),
            ],
          ),
      ],
    );
  }

  Widget _partyAvatar(SeyirPalette palette) {
    const String fallback = 'lib/icons/07_profil_picture_davaci.png';
    Widget imageOf(String path) {
      return Image.asset(
        path,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Icon(
          Icons.person,
          size: 16,
          color: palette.textSecondary,
        ),
      );
    }

    return CircleAvatar(
      radius: 14,
      backgroundColor: palette.brandSoft,
      child: userEmail != null
          ? FutureBuilder<String?>(
              future: _getUserProfileImage(userEmail!),
              builder: (BuildContext context, AsyncSnapshot<String?> snapshot) {
                final String path =
                    (snapshot.hasData && snapshot.data != null)
                        ? snapshot.data!
                        : fallback;
                return ClipOval(child: imageOf(path));
              },
            )
          : ClipOval(child: imageOf(fallback)),
    );
  }

  // Kullanıcının profil resmini al
  Future<String?> _getUserProfileImage(String email) async {
    try {
      HiveDatabaseService.getRegistrationByEmail(email);
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
}

String _initial(String name) {
  final String trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}

class _SoftError extends StatelessWidget {
  const _SoftError({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final bool shown = message != null && message!.isNotEmpty;
    return AnimatedSize(
      duration: SeyirTokens.motion,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedOpacity(
        duration: SeyirTokens.motion,
        curve: Curves.easeOutCubic,
        opacity: shown ? 1 : 0,
        child: shown
            ? Padding(
                padding: const EdgeInsets.only(top: SeyirTokens.space2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 16,
                      color: SeyirTokens.reject,
                    ),
                    const SizedBox(width: SeyirTokens.space2),
                    Expanded(
                      child: Text(
                        message!,
                        style: palette.caption(
                          color: SeyirTokens.reject,
                          weight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              )
            : const SizedBox(width: double.infinity),
      ),
    );
  }
}
