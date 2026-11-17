import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../services/hive_database_service.dart';
import '../models/category_model.dart';
import '../theme/seyir_tokens.dart';
import '../utils/category_icon_utils.dart';
import '../utils/category_lottie_config.dart';
import '../utils/constants.dart';
import '../widgets/category_search_bar.dart';
import '../widgets/delil_surface.dart';
import '../widgets/empty_search_result.dart';
import 'dava_ac_page.dart';

/// Kategori seçim sayfası - Modüler ve performanslı tasarım
class CategoryPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  /// Testlerde yükleme hatasını üretmek için. Üretimde null kalır.
  final Future<List<CategoryModel>> Function()? categoryLoader;

  const CategoryPage({
    super.key,
    this.userEmail,
    this.categoryLoader,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<CategoryModel> _categories = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  List<CategoryModel> get filteredCategories =>
      _filterLoaded(_categories, _searchQuery);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _preloadCategoryLottieAssets();
  }

  /// Kategorileri veri tabanından yükler.
  /// Hata, boş arama gibi gösterilmez; yeniden deneme kartı açılır.
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _loadFailed = false;
    });

    try {
      final loader = widget.categoryLoader;
      _categories = loader != null
          ? await loader()
          : HiveDatabaseService.getActiveCategories();
    } catch (e) {
      _categories = [];
      _loadFailed = true;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _searchQuery = value);
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() => _searchQuery = '');
  }

  void _onSubCategorySelected(String selectedCategory, String selectedSubCategory) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DavaAcPage(
          userEmail: widget.userEmail,
          selectedCategory: selectedCategory,
          selectedSubCategory: selectedSubCategory,
          initialCollapsed: true, // Dava aç sayfası kategori seçilince collapsed açılsın
        ),
      ),
    );
  }

  void _preloadCategoryLottieAssets() {
    for (final assetPath in getAllCategoryLottieAssets()) {
      AssetLottie(assetPath).load();
    }
  }

  /// Hive `filterCategories` ile aynı sıra: boş aramada ve sonuçta İlişkiler üstte.
  static List<CategoryModel> _filterLoaded(
    List<CategoryModel> source,
    String query,
  ) {
    final List<CategoryModel> all = List<CategoryModel>.from(source);
    bool isIliskiler(CategoryModel category) {
      final String name = category.name.toLowerCase();
      return name == 'ilişkiler' || name == 'ilişkiler' || category.name == 'İlişkiler';
    }

    void pinIliskiler(List<CategoryModel> list) {
      final int idx = list.indexWhere(isIliskiler);
      if (idx > 0) {
        final CategoryModel item = list.removeAt(idx);
        list.insert(0, item);
      }
    }

    if (query.trim().isEmpty) {
      pinIliskiler(all);
      return all;
    }
    final String q = query.toLowerCase();
    final List<CategoryModel> filtered = all.where((CategoryModel category) {
      if (category.name.toLowerCase().contains(q)) return true;
      return category.subCategories.any((String sub) => sub.toLowerCase().contains(q));
    }).toList();
    pinIliskiler(filtered);
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color headerInk = palette.onSolid(SeyirTokens.brandDeep);
    return Scaffold(
      backgroundColor: Color.alphaBlend(
        SeyirTokens.brand.withValues(alpha: palette.isDark ? 0.08 : 0.10),
        palette.surface,
      ),
      appBar: AppBar(
        title: Text(
          '📋 Kategoriler',
          style: palette.headline(color: headerInk),
        ),
        backgroundColor: SeyirTokens.brandDeep,
        foregroundColor: headerInk,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: headerInk),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF14956C),
                SeyirTokens.brandDeep,
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, size: 24),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kapat',
            style: IconButton.styleFrom(
              minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
              tapTargetSize: MaterialTapTargetSize.padded,
              foregroundColor: headerInk,
              backgroundColor: headerInk.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CategorySearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _onSearchClear,
            ),
            Expanded(
              child: _isLoading
                  ? _buildShimmerGrid()
                  : _loadFailed
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(SeyirTokens.space4),
                          children: [
                            DelilLoadError(
                              message: 'Kategoriler yüklenemedi.',
                              onRetry: _loadCategories,
                            ),
                          ],
                        )
                      : filteredCategories.isEmpty
                          ? EmptySearchResult(searchQuery: _searchQuery)
                          : GridView.builder(
                              padding: const EdgeInsets.all(SeyirTokens.space4),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                crossAxisSpacing: SeyirTokens.space3,
                                mainAxisSpacing: SeyirTokens.space3,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = filteredCategories[index];
                                return _buildModernCategoryCard(category, index);
                              },
                            ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yüklenirken gösterilen shimmer grid (skeleton)
  Widget _buildShimmerGrid() {
    final SeyirPalette palette = SeyirPalette.of(context);
    return Shimmer.fromColors(
      baseColor: palette.surfaceMuted,
      highlightColor: palette.card,
      child: GridView.builder(
        padding: const EdgeInsets.all(SeyirTokens.space4),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: SeyirTokens.space3,
          mainAxisSpacing: SeyirTokens.space3,
          childAspectRatio: 0.85,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: palette.card,
              borderRadius: SeyirTokens.radiusLgAll,
              border: Border.all(color: palette.border),
            ),
          );
        },
      ),
    );
  }

  /// Grid kartı: tıklanınca haptic + alt kategori seçimi veya doğrudan dava aç
  Widget _buildModernCategoryCard(CategoryModel category, int index) {
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color borderColor = palette.isDark
        ? SeyirTokens.brand.withValues(alpha: 0.85)
        : SeyirTokens.brandDeep.withValues(alpha: 0.45);
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 40)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _onCategoryCardTap(category),
                borderRadius: SeyirTokens.radiusLgAll,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: SeyirTokens.space4,
                    horizontal: SeyirTokens.space3,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        palette.card,
                        palette.brandSoft,
                      ],
                    ),
                    borderRadius: SeyirTokens.radiusLgAll,
                    boxShadow: palette.cardShadow,
                    border: Border.all(
                      color: borderColor,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: palette.tint(SeyirTokens.brand),
                          borderRadius: SeyirTokens.radiusMdAll,
                        ),
                        child: Icon(
                          categoryIconFromPath(category.iconPath),
                          size: 28,
                          color: palette.foreground(SeyirTokens.brandDeep),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: palette.body(weight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Kategori kartına tıklanınca: haptic, gerekirse alt kategori seçim bottom sheet, sonra dava aç
  void _onCategoryCardTap(CategoryModel category) {
    HapticFeedback.lightImpact();
    final subList = category.subCategories.isEmpty
        ? [category.name]
        : category.subCategories;
    if (subList.length == 1) {
      _maybeShowLottieThenNavigate(category.name, subList.first);
      return;
    }
    final SeyirPalette sheet = SeyirPalette.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: sheet.card,
          borderRadius: SeyirTokens.sheetTop,
          border: Border.all(color: sheet.border, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: SeyirTokens.space2),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: sheet.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(SeyirTokens.space4),
                child: Text(
                  category.name,
                  style: sheet.headline(),
                ),
              ),
              ...subList.map((sub) => ListTile(
                    leading: Icon(
                      categoryIconFromPath(category.iconPath),
                      color: SeyirTokens.brandDeep,
                      size: 22,
                    ),
                    title: Text(
                      sub,
                      style: sheet.body(weight: FontWeight.w500),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _maybeShowLottieThenNavigate(category.name, sub);
                    },
                  )),
              const SizedBox(height: SeyirTokens.space4),
            ],
          ),
        ),
      ),
    );
  }

  /// Her kategoride tema ile eşleşen Lottie gösterir, sonra dava aç sayfasına yönlendirir.
  void _maybeShowLottieThenNavigate(String selectedCategory, String subCategory) {
    if (!mounted) return;
    _showCategoryLottieOverlay(
      categoryName: selectedCategory,
      onComplete: () => _onSubCategorySelected(selectedCategory, subCategory),
    );
  }

  /// Lottie overlay: kategoriye göre animasyon + fallback ikon, bitince [onComplete] çağrılır.
  void _showCategoryLottieOverlay({
    required String categoryName,
    required VoidCallback onComplete,
  }) {
    final lottieAssetPath = getLottieAssetForCategory(categoryName);
    final fallbackIcon = getFallbackIconForCategory(categoryName);
    final slogan = getSloganForCategory(categoryName);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _CategoryLottieDialog(
        lottieAssetPath: lottieAssetPath,
        fallbackIcon: fallbackIcon,
        slogan: slogan,
        onComplete: () {
          Navigator.of(context).pop();
          onComplete();
        },
      ),
    );
  }

}

/// Kategori seçiminde gösterilen Lottie dialog; ikon + slogan, sonra dava aç.
class _CategoryLottieDialog extends StatefulWidget {
  final String lottieAssetPath;
  final IconData fallbackIcon;
  final String slogan;
  final VoidCallback onComplete;

  const _CategoryLottieDialog({
    required this.lottieAssetPath,
    required this.fallbackIcon,
    required this.slogan,
    required this.onComplete,
  });

  @override
  State<_CategoryLottieDialog> createState() => _CategoryLottieDialogState();
}

class _CategoryLottieDialogState extends State<_CategoryLottieDialog> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2200), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sıcak turuncu palet – kategori kutlaması
    const dialogPrimaryDark = SeyirTokens.warning;
    const dialogPrimaryLight = Color(0xFFF97316);
    final SeyirPalette palette = SeyirPalette.of(context);
    final Color dialogBorder = palette.isDark
        ? dialogPrimaryLight.withValues(alpha: 0.75)
        : dialogPrimaryDark.withValues(alpha: 0.35);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: SeyirTokens.sheetTop,
              child: Container(
                padding: const EdgeInsets.all(SeyirTokens.space6),
                decoration: BoxDecoration(
                  color: palette.card,
                  borderRadius: SeyirTokens.sheetTop,
                  border: Border.all(color: dialogBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: dialogPrimaryDark.withValues(alpha: 0.22),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 180,
                      height: 180,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Lottie.asset(
                            widget.lottieAssetPath,
                            width: 180,
                            height: 180,
                            fit: BoxFit.contain,
                            repeat: false,
                            onLoaded: (_) {},
                            errorBuilder: (_, __, ___) => Container(
                              width: 180,
                              height: 180,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: palette.tint(dialogPrimaryLight),
                                shape: BoxShape.circle,
                                border: Border.all(color: dialogBorder),
                                boxShadow: [
                                  BoxShadow(
                                    color: dialogPrimaryLight.withValues(alpha: 0.35),
                                    blurRadius: 20,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Container(
                            width: 90,
                            height: 90,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: palette.card.withValues(alpha: 0.92),
                              shape: BoxShape.circle,
                              border: Border.all(color: dialogBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: dialogPrimaryDark.withValues(alpha: 0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.fallbackIcon,
                              size: 46,
                              color: palette.foreground(dialogPrimaryDark),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.slogan.isNotEmpty) ...[
                      const SizedBox(height: SeyirTokens.space4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space2),
                        child: Text(
                          widget.slogan,
                          textAlign: TextAlign.center,
                          style: palette.body(weight: FontWeight.w600).copyWith(height: 1.35),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
