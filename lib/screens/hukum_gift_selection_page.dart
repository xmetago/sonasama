import 'dart:async';
import 'dart:math' show min;
import 'dart:ui';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:provider/provider.dart';

import '../data/hukum_gift_categories.dart';
import '../data/hukum_gift_data.dart';
import '../models/gift_models.dart';
import '../providers/dava_provider.dart';
import '../services/offline_gift_queue.dart';
import '../services/play_billing_service.dart';
import '../services/user_star_balance_store.dart';
import '../theme/hukum_gift_colors.dart';
import '../utils/dialog_utils.dart';
import '../widgets/common_header_widgets.dart';
import '../widgets/cezalar_page_layout_rails.dart';
import '../widgets/hukum_gift_short_name_text.dart';
import '../widgets/hukum_gift_star_strip.dart';
import '../widgets/hukum_gift_tile_motion.dart';

/// untitled projesindeki hediye (gift) akışının Provider tabanlı uyarlaması.
/// Onayda seçilen hediye tek satır masraf olarak Hive / [DavaProvider] ile kaydedilir.
class HukumGiftSelectionPage extends StatefulWidget {
  const HukumGiftSelectionPage({
    super.key,
    this.userEmail,
    this.davaId,
    this.davaAdi,
  });

  final String? userEmail;
  final String? davaId;
  final String? davaAdi;

  @override
  State<HukumGiftSelectionPage> createState() => _HukumGiftSelectionPageState();
}

class _HukumGiftSelectionPageState extends State<HukumGiftSelectionPage> {
  static const Color _border = Color(0xFFDDE9E2);
  static const Duration _masrafCongratsDisplay = Duration(seconds: 4);

  bool _isHeaderCollapsed = true;
  bool _showLeftIcons = false;

  bool _billingReady = false;
  int _yellowStars = 0;

  late int _activeCatId;
  String? _activeSub;
  Gift? _selectedGift;
  final List<Gift> _favorites = <Gift>[];
  int? _selectedFavoriteIndex;
  List<Gift> _gridGifts = const <Gift>[];

  /// Masraflat sonrası tebrik katmanı (birkaç saniye sonra kapanır).
  bool _showMasrafCongrats = false;

  /// Masraf satırı varsayılanı: DİĞER › İbadet Malzemeleri › Seccade (Premium).
  static Gift? _defaultMasrafSeccadePremium() {
    const int digerId = 22;
    const String ibadetSub = 'İbadet Malzemeleri';
    Category? diger;
    for (final Category c in hukumGiftCategories) {
      if (c.id == digerId) {
        diger = c;
        break;
      }
    }
    if (diger == null || !diger.subs.contains(ibadetSub)) {
      return null;
    }
    final List<Gift> gifts = generateGiftsForSub(diger, ibadetSub);
    if (gifts.isEmpty) {
      return null;
    }
    return gifts.firstWhere(
      (Gift g) => g.name == 'Seccade (Premium)',
      orElse: () => gifts.first,
    );
  }

  @override
  void initState() {
    super.initState();
    // İlk gösterim: OTOMOTİV (+ ilk alt başlık); seçili masraf yine Seccade (Premium).
    const int firstViewCategoryId = 1;
    final Category otomotivCat = hukumGiftCategories.firstWhere(
      (Category c) => c.id == firstViewCategoryId,
      orElse: () => hukumGiftCategories.first,
    );
    _activeCatId = otomotivCat.id;
    _activeSub =
        otomotivCat.subs.isEmpty ? null : otomotivCat.subs.first;
    _syncGridGifts();
    _selectedGift = _defaultMasrafSeccadePremium();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_bootstrapStarsAndBilling());
      unawaited(_drainOfflineMasrafQueue());
    });
  }

  Future<void> _drainOfflineMasrafQueue() async {
    if (!mounted) return;
    final DavaProvider davaProvider =
        Provider.of<DavaProvider>(context, listen: false);
    await OfflineGiftQueue.processPending(
      onAnyApplied: davaProvider.notifyMasrafDataChanged,
    );
    if (mounted) {
      await _reloadYellowBalance();
    }
  }

  Future<void> _reloadYellowBalance() async {
    final String? email = widget.userEmail;
    final int n = await UserStarBalanceStore.getYellowStars(email);
    if (!mounted) return;
    setState(() => _yellowStars = n);
  }

  Future<void> _bootstrapStarsAndBilling() async {
    await _reloadYellowBalance();
    if (!mounted) return;

    if (kIsWeb) {
      setState(() => _billingReady = false);
      return;
    }

    final bool ok = await globalPlayBilling.init((int stars) async {
      final String? email = widget.userEmail;
      if (email != null && email.isNotEmpty) {
        await UserStarBalanceStore.addYellowStars(email, stars);
      }
      if (!mounted) return;
      await _reloadYellowBalance();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$stars yıldız satın alındı.'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    });
    if (!mounted) return;
    setState(() => _billingReady = ok);
  }

  Future<void> _onBuyStarPack(int amount) async {
    final String? email = widget.userEmail;
    if (email == null || email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              const Text('Yıldız yüklemek için oturumdaki kullanıcı e-postası gerekir.'),
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    if (_billingReady) {
      final String? productId =
          PlayBillingService.productIdForStarAmount(amount);
      if (productId != null) {
        bool started = false;
        try {
          started = await globalPlayBilling.buyConsumable(productId);
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Ödeme başlatılamadı: $e')),
            );
          }
          return;
        }
        if (started && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Ödeme ekranı açılıyor…'),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 2),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        if (started) return;
      }
    }

    await UserStarBalanceStore.addYellowStars(email, amount);
    await _reloadYellowBalance();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$amount yıldız hesaba eklendi (yerel / test).'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Category _categoryById(int id) =>
      hukumGiftCategories.firstWhere((Category c) => c.id == id);

  void _syncGridGifts() {
    if (_activeCatId == 0) {
      _gridGifts = const <Gift>[];
      return;
    }
    if (_activeSub == null) {
      _gridGifts = const <Gift>[];
      return;
    }
    _gridGifts = generateGiftsForSub(_categoryById(_activeCatId), _activeSub!);
  }

  void _selectCategory(int catId) {
    final Category cat = _categoryById(catId);
    setState(() {
      _activeCatId = catId;
      _activeSub = cat.subs.isEmpty ? null : cat.subs.first;
      _selectedGift = null;
      _selectedFavoriteIndex = null;
      _syncGridGifts();
    });
  }

  void _selectSub(String sub) {
    setState(() {
      _activeSub = sub;
      _selectedGift = null;
      _selectedFavoriteIndex = null;
      _syncGridGifts();
    });
  }

  void _selectGift(Gift gift) {
    setState(() {
      _selectedGift = gift;
      _selectedFavoriteIndex = null;
    });
  }

  void _selectFavoriteAt(int index) {
    if (index < 0 || index >= _favorites.length) return;
    setState(() {
      _selectedGift = _favorites[index];
      _selectedFavoriteIndex = index;
    });
  }

  void _addFavorite(Gift gift) {
    setState(() {
      _favorites.add(gift);
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Favorilere eklendi: ${gift.shortName.split('\n').first}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _persistAndPop() async {
    final Gift? gift = _selectedGift;
    if (gift == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Lütfen bir hediye seçin.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    bool showCongratsThenPop = false;
    final String? davaId = widget.davaId;
    final String? email = widget.userEmail;
    if (davaId != null &&
        davaId.isNotEmpty &&
        email != null &&
        email.isNotEmpty) {
      if (!mounted) return;
      try {
        final DavaProvider davaProvider =
            Provider.of<DavaProvider>(context, listen: false);
        final String line = OfflineGiftQueue.masrafLineForGift(gift);
        final bool saved = await davaProvider.updateMasrafForDava(
          davaId: davaId,
          userEmail: email,
          masraflar: <String>[line],
        );
        if (!saved) {
          await OfflineGiftQueue.enqueue(
            gift: gift,
            davaId: davaId,
            email: email,
          );
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  davaProvider.error ??
                      'Masraf kaydedilemedi; sıraya alındı, uygulama açıldığında yeniden denenecek.',
                ),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 4),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
          return;
        }

        showCongratsThenPop = true;
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kayıt hatası: $e'),
              backgroundColor: Colors.red.shade700,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
        return;
      }
    }

    if (showCongratsThenPop) {
      if (mounted) {
        setState(() => _showMasrafCongrats = true);
      }
      await Future<void>.delayed(_masrafCongratsDisplay);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }

    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  BoxDecoration _glassCard({bool strong = false}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: strong
          ? Colors.white.withValues(alpha: 0.92)
          : Colors.white.withValues(alpha: 0.72),
      border: Border.all(color: _border, width: 1.4),
      boxShadow: <BoxShadow>[
        BoxShadow(
          color: const Color(0xFF101815).withValues(alpha: 0.07),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Category activeCat = _categoryById(_activeCatId);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isHeaderCollapsed ? 40 : null,
              child: _isHeaderCollapsed
                  ? CollapsedWbHeaderRow(
                      title: 'MASRAF — HEDİYE ',
                      onExpandHeader: () =>
                          setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                      onToggleLeftNav: () =>
                          setState(() => _showLeftIcons = !_showLeftIcons),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        ZeroWhoboomSearchMessage(userEmail: widget.userEmail),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: OneFriendPhoneBellMenu(userEmail: widget.userEmail),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: SecondProfileJudgenameIconknifeEnergyPicturePokeSueChant(
                            userEmail: widget.userEmail,
                            onShowSavedDavalar: () {
                              if (widget.userEmail != null) {
                                showSavedDavalarDialog(context, widget.userEmail!);
                              }
                            },
                          ),
                        ),
                        CezalarMenuTitleRow(
                          onToggleLeftNav: () =>
                              setState(() => _showLeftIcons = !_showLeftIcons),
                          title: ' Masraf Seçimi',
                          isHeaderCollapsed: _isHeaderCollapsed,
                          onToggleCollapse: () =>
                              setState(() => _isHeaderCollapsed = !_isHeaderCollapsed),
                        ),
                      ],
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: _showLeftIcons ? 60 : 0,
                      child: _showLeftIcons
                          ? SingleChildScrollView(
                              child: CezalarLeftIconScrollColumn(
                                userEmail: widget.userEmail,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              const Color(0xFFF5FBF7),
                              Colors.white,
                              const Color(0xFFE8F5E9).withValues(alpha: 0.45),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            HukumGiftStarStrip(
                              davaBaslik: widget.davaAdi ?? '',
                              yellowStars: _yellowStars,
                              billingReady: _billingReady,
                              dense: true,
                              onBuyPack: (int amount) {
                                unawaited(_onBuyStarPack(amount));
                              },
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: SizedBox(
                                height: 46,
                                child: ListView.separated(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: hukumGiftCategories.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(width: 8),
                                  itemBuilder: (BuildContext context, int i) {
                                    final Category c = hukumGiftCategories[i];
                                    final bool selected = c.id == _activeCatId;
                                    return FilterChip(
                                      label: Text(
                                          '${c.icon} ${c.name.split('&').first.trim()}'),
                                      selected: selected,
                                      onSelected: (_) => _selectCategory(c.id),
                                      showCheckmark: false,
                                      selectedColor: const Color(0xFFC8E6C9),
                                      backgroundColor:
                                          Colors.white.withValues(alpha: 0.75),
                                      side: BorderSide(
                                        color: selected
                                            ? const Color(0xFF4CAF50)
                                            : _border,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            if (_activeCatId != 0 && activeCat.subs.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                                child: SizedBox(
                                  height: 40,
                                  child: ListView.separated(
                                    scrollDirection: Axis.horizontal,
                                    itemCount: activeCat.subs.length,
                                    separatorBuilder: (_, __) =>
                                        const SizedBox(width: 8),
                                    itemBuilder: (BuildContext context, int i) {
                                      final String sub = activeCat.subs[i];
                                      final bool sel = sub == _activeSub;
                                      return ChoiceChip(
                                        label: Text(
                                          sub,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: sel
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                          ),
                                        ),
                                        selected: sel,
                                        onSelected: (_) => _selectSub(sub),
                                        selectedColor: const Color(0xFFA5D6A7),
                                        backgroundColor:
                                            Colors.white.withValues(alpha: 0.8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(16),
                                          side: BorderSide(
                                            color: sel
                                                ? const Color(0xFF2E7D32)
                                                : _border,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            Expanded(child: _buildGiftGrid(context, theme)),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                                  child: Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: _glassCard(strong: true),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Row(
                                          children: <Widget>[
                                            Icon(MdiIcons.giftOutline,
                                                color: Colors.purple.shade700,
                                                size: 22),
                                            const SizedBox(width: 8),
                                            Text(
                                              'SEÇİLEN MASRAF',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.6,
                                                color: const Color(0xFF1B2A23),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        if (_selectedGift == null)
                                          Padding(
                                            padding: const EdgeInsets.symmetric(
                                                vertical: 12),
                                            child: Center(
                                              child: Text(
                                                'Izgara üzerinden bir hediye seçin\n(çift tık: favorilere ekler)',
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.grey.shade600,
                                                  height: 1.35,
                                                ),
                                              ),
                                            ),
                                          )
                                        else
                                          _SelectedGiftPreview(gift: _selectedGift!),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: FilledButton.tonal(
                                                onPressed: () =>
                                                    Navigator.of(context).pop(false),
                                                style: FilledButton.styleFrom(
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: const Text('İptal'),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FilledButton(
                                                onPressed: _persistAndPop,
                                                style: FilledButton.styleFrom(
                                                  backgroundColor:
                                                      const Color(0xFF6A1B9A),
                                                  foregroundColor: Colors.white,
                                                  padding: const EdgeInsets.symmetric(
                                                      vertical: 14),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(16),
                                                  ),
                                                ),
                                                child: const Text('Masraflat'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
              ],
            ),
          ),
          if (_showMasrafCongrats) _MasrafCongratsOverlay(theme: theme),
        ],
      ),
    );
  }

  Widget _buildGiftGrid(BuildContext context, ThemeData theme) {
    final double gridWidth = MediaQuery.sizeOf(context).width;
    final int giftCrossAxisCount = gridWidth < 400 ? 2 : 3;
    if (_activeCatId == 0) {
      if (_favorites.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: _glassCard(),
              child: Text(
                'Henüz favori yok.\nBaşka kategoride hediyeye çift tıklayarak ekleyin.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.grey.shade700,
                  height: 1.4,
                ),
              ),
            ),
          ),
        );
      }
      return GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: giftCrossAxisCount,
          childAspectRatio: 0.8,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _favorites.length,
        itemBuilder: (BuildContext context, int index) {
          final Gift gift = _favorites[index];
          return _HukumGiftTile(
            gridIndex: index,
            gift: gift,
            isSelected: _selectedFavoriteIndex == index,
            priceColor:
                HukumGiftColors.priceColorForValue(context, gift.price),
            onSingleTap: () => _selectFavoriteAt(index),
            onFavoriteDoubleTap: () => _addFavorite(gift),
            glassDecoration: _glassCard(),
          );
        },
      );
    }

    if (_activeSub == null || _gridGifts.isEmpty) {
      return Center(
        child: Text(
          'Bu görünüm için alt kategori yok.',
          style: theme.textTheme.bodyLarge?.copyWith(color: Colors.grey.shade600),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: giftCrossAxisCount,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _gridGifts.length,
      itemBuilder: (BuildContext context, int index) {
        final Gift gift = _gridGifts[index];
        return _HukumGiftTile(
          gridIndex: index,
          gift: gift,
          isSelected: _selectedGift?.id == gift.id,
          priceColor: HukumGiftColors.priceColorForValue(context, gift.price),
          onSingleTap: () => _selectGift(gift),
          onFavoriteDoubleTap: () => _addFavorite(gift),
          glassDecoration: _glassCard(),
        );
      },
    );
  }
}

class _MasrafCongratsOverlay extends StatelessWidget {
  const _MasrafCongratsOverlay({required this.theme});

  final ThemeData theme;

  static const Color _slabBlueTop = Color(0xFF7EC5FF);
  static const Color _slabBlueBottom = Color(0xFF4A9EFF);
  static const Color _tabBlueLight = Color(0xFF6BB8FF);
  static const Color _tabBlue = Color(0xFF3D8AE6);

  static const String _message =
      '"HAKSIZ" tarafın bütçesine uygun bir Ürünü -> Hediye olarak '
      '"HAKLI" tarafa almasına yardımcı oldunuz, TEBRİKLER.';

  @override
  Widget build(BuildContext context) {
    final double maxW = min(360.0, MediaQuery.sizeOf(context).width - 40);

    return Positioned.fill(
      child: AbsorbPointer(
        child: Material(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: maxW,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Positioned(
                      left: 14,
                      right: -2,
                      top: 30,
                      bottom: 6,
                      child: Transform.rotate(
                        angle: 0.052,
                        alignment: Alignment.center,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: <Color>[
                                _slabBlueTop,
                                _slabBlueBottom,
                              ],
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: _slabBlueBottom.withValues(alpha: 0.42),
                                blurRadius: 22,
                                offset: const Offset(8, 14),
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.35),
                                blurRadius: 0,
                                offset: const Offset(-2, -2),
                              ),
                            ],
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.fromLTRB(8, 42, 16, 20),
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 28,
                            offset: const Offset(0, 14),
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Text(
                        _message,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleSmall?.copyWith(
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: const Color(0xFF1B2A23),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      top: 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: <Color>[
                              _tabBlueLight,
                              _tabBlue,
                            ],
                          ),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: _tabBlue.withValues(alpha: 0.55),
                              blurRadius: 14,
                              offset: const Offset(3, 7),
                            ),
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.45),
                              blurRadius: 0,
                              offset: const Offset(-1.5, -1.5),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Icon(
                            MdiIcons.giftOutline,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedGiftPreview extends StatelessWidget {
  const _SelectedGiftPreview({required this.gift});

  final Gift gift;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: HukumGiftColors.selectedAreaBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCE8DF)),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(gift.emoji, style: const TextStyle(fontSize: 36)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                HukumGiftShortNameText(
                  shortName: gift.shortName,
                  primaryStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B2A23),
                  ),
                  secondaryStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.start,
                  maxLines: 3,
                ),
                const SizedBox(height: 4),
                Text(
                  '${gift.catName} → ${gift.subName}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Text(
            '⭐ ${gift.price}',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: HukumGiftColors.priceColorForValue(context, gift.price),
            ),
          ),
        ],
      ),
    );
  }
}

class _HukumGiftTile extends StatelessWidget {
  const _HukumGiftTile({
    required this.gridIndex,
    required this.gift,
    required this.isSelected,
    required this.priceColor,
    required this.onSingleTap,
    required this.onFavoriteDoubleTap,
    required this.glassDecoration,
  });

  final int gridIndex;
  final Gift gift;
  final bool isSelected;
  final Color priceColor;
  final VoidCallback onSingleTap;
  final VoidCallback onFavoriteDoubleTap;
  final BoxDecoration glassDecoration;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: isSelected ? 3 : 0,
      shadowColor: Colors.black26,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onSingleTap,
        onDoubleTap: onFavoriteDoubleTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedScale(
          scale: isSelected ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              color: glassDecoration.color,
              border: Border.all(
                color: isSelected
                    ? HukumGiftColors.accentGold
                    : const Color(0xFFDDE9E2),
                width: isSelected ? 2.2 : 1.4,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: (isSelected
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFF101815))
                      .withValues(alpha: isSelected ? 0.12 : 0.06),
                  blurRadius: isSelected ? 16 : 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: HukumGiftTileEntrance(
              gridIndex: gridIndex,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    HukumGiftEmojiMotion(emoji: gift.emoji, fontSize: 38),
                    const SizedBox(height: 6),
                    HukumGiftShortNameText(
                      shortName: gift.shortName,
                      primaryStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B2A23),
                      ),
                      secondaryStyle: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade700,
                        height: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: priceColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '⭐ ${gift.price}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: priceColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
