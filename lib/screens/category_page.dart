import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import '../services/hive_database_service.dart';
import '../models/category_model.dart';
import '../utils/category_icon_utils.dart';
import '../utils/category_lottie_config.dart';
import '../utils/constants.dart';
import '../widgets/sub_category_tile.dart';
import '../widgets/category_search_bar.dart';
import '../widgets/empty_search_result.dart';
import 'dava_ac_page.dart';

/// Kategori seçim sayfası - Modüler ve performanslı tasarım
class CategoryPage extends StatefulWidget {
  final String? userEmail; // Kullanıcı e-posta adresi

  const CategoryPage({super.key, this.userEmail});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Ferah yeşil tonlar – Kategoriler sayfası
  static const Color primaryColor = Color(0xFF169371); // Ana yeşil (#169371)
  static const Color primaryLightColor = Color(0xFF22B48E); // Biraz daha açık yeşil
  static const Color primaryLighterColor = Color(0xFFE0F5EF); // Çok açık mint/yeşil arka plan
  static const Color primaryDarkColor = Color(0xFF0F6B52); // Daha koyu yeşil

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  List<CategoryModel> get filteredCategories =>
      HiveDatabaseService.filterCategories(_searchQuery);

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _preloadCategoryLottieAssets();
  }

  /// Kategorileri veri tabanından yükler
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _categories = HiveDatabaseService.getActiveCategories();
    } catch (e) {
      // Hata durumunda boş liste kullan
      _categories = [];
    }
    
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryLighterColor, // Ferah, yumuşak açık yeşil arka plan
      appBar: AppBar(
        title: const Text(
          '📋 Kategoriler',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryLightColor,
                primaryDarkColor,
              ],
            ),
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 24),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Kapat',
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
                  : filteredCategories.isEmpty
                      ? EmptySearchResult(searchQuery: _searchQuery)
                      : GridView.builder(
                          padding: const EdgeInsets.all(16),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
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
    return Shimmer.fromColors(
      baseColor: primaryLighterColor,
      highlightColor: Colors.white.withOpacity(0.9),
      child: GridView.builder(
        padding: const EdgeInsets.all(16),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: 12,
        itemBuilder: (context, index) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Grid kartı: tıklanınca haptic + alt kategori seçimi veya doğrudan dava aç
  Widget _buildModernCategoryCard(CategoryModel category, int index) {
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
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        primaryLighterColor.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryDarkColor.withOpacity(0.18),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                    border: Border.all(
                      color: primaryLightColor.withOpacity(0.6),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryLightColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          categoryIconFromPath(category.iconPath),
                          size: 28,
                          color: primaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        category.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
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
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: primaryLighterColor, width: 1),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: primaryDarkColor.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              ...subList.map((sub) => ListTile(
                    leading: Icon(categoryIconFromPath(category.iconPath), color: primaryColor, size: 22),
                    title: Text(sub, style: const TextStyle(fontWeight: FontWeight.w500)),
                    onTap: () {
                      Navigator.pop(context);
                      _maybeShowLottieThenNavigate(category.name, sub);
                    },
                  )),
              const SizedBox(height: 16),
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
    // Sıcak turuncu palet – CategoryPage ile uyumlu
    const dialogPrimaryDark = Color(0xFFC2410C);
    const dialogPrimaryLight = Color(0xFFF97316);
    const dialogPrimaryLighter = Color(0xFFFFEDD5);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: dialogPrimaryDark.withOpacity(0.22),
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
                                color: dialogPrimaryLighter,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: dialogPrimaryLight.withOpacity(0.35),
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
                              color: Colors.white.withOpacity(0.92),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: dialogPrimaryDark.withOpacity(0.18),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              widget.fallbackIcon,
                              size: 46,
                              color: dialogPrimaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.slogan.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          widget.slogan,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                            height: 1.35,
                          ),
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
