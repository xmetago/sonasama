import 'package:flutter/material.dart';
import '../services/hive_database_service.dart';
import '../models/category_model.dart';
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

class _CategoryPageState extends State<CategoryPage>
    with TickerProviderStateMixin {
  int selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _listAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Site genelindeki ana renk teması
  static const Color primaryColor = Color(0xFFDC2626); // Kırmızı
  static const Color primaryLightColor = Color(0xFFEF4444); // Açık kırmızı
  static const Color primaryLighterColor = Color(0xFFFEE2E2); // Çok açık kırmızı
  static const Color primaryDarkColor = Color(0xFFB91C1C); // Daha koyu kırmızı

  List<CategoryModel> _categories = [];
  bool _isLoading = true;

  List<CategoryModel> get filteredCategories => 
      HiveDatabaseService.filterCategories(_searchQuery);

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _listAnimationController,
      curve: Curves.elasticOut,
    ));
    
    _listAnimationController.forward();
    _loadCategories();
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
    _listAnimationController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
      if (filteredCategories.isNotEmpty) {
        selectedCategoryIndex = 0;
      }
    });
  }

  void _onSearchClear() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
      selectedCategoryIndex = 0;
    });
  }

  void _onCategorySelected(int index) {
    setState(() {
      selectedCategoryIndex = index;
    });
  }

  void _onSubCategorySelected(String subCategory) {
    // Seçilen kategori ve alt kategori bilgilerini al
    final selectedCategory = filteredCategories[selectedCategoryIndex].name;
    
    // Dava aç sayfasına yönlendir ve kategori bilgilerini geçir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DavaAcPage(
          userEmail: widget.userEmail,
          selectedCategory: selectedCategory,
          selectedSubCategory: subCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final categoryPanelWidth = screenWidth * 0.32; // Responsive genişlik

    return Scaffold(
      backgroundColor: Colors.grey[50],
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
                primaryColor,
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
            // Arama çubuğu
            CategorySearchBar(
              controller: _searchController,
              onChanged: _onSearchChanged,
              onClear: _onSearchClear,
            ),

            // Kategori seçimi
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withAlpha(1),
                      spreadRadius: 1,
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: filteredCategories.isEmpty
                    ? EmptySearchResult(searchQuery: _searchQuery)
                    : FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Row(
                            children: [
                              // Sol taraf - Ana kategoriler
                              Container(
                                width: categoryPanelWidth,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.grey[50]!,
                                      Colors.white,
                                    ],
                                  ),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    bottomLeft: Radius.circular(16),
                                  ),
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                ),
                                                                 child: _isLoading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          color: primaryColor,
                                        ),
                                      )
                                    : filteredCategories.isEmpty
                                        ? const Center(
                                            child: Text(
                                              'Kategori bulunamadı',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          )
                                        : ListView.builder(
                                            padding: const EdgeInsets.all(6.0),
                                            itemCount: filteredCategories.length,
                                            itemBuilder: (context, index) {
                                              CategoryModel category = filteredCategories[index];
                                              bool isSelected = selectedCategoryIndex == index;

                                    return _buildAnimatedCategoryItem(
                                      category: category,
                                      index: index,
                                      isSelected: isSelected,
                                    );
                                  },
                                ),
                              ),

                              // Sağ taraf - Alt kategoriler
                              Expanded(
                                child: filteredCategories.isEmpty
                                    ? const Center(
                                        child: Text(
                                          'Kategori bulunamadı',
                                          style: TextStyle(
                                            color: Colors.grey,
                                            fontSize: 16,
                                          ),
                                        ),
                                      )
                                    : ListView.builder(
                                        padding: const EdgeInsets.all(16.0),
                                        itemCount: filteredCategories[selectedCategoryIndex].subCategories.length,
                                        itemBuilder: (context, index) {
                                          String subCategory = filteredCategories[selectedCategoryIndex].subCategories[index];

                                    return SubCategoryTile(
                                      subCategory,
                                      onTap: () => _onSubCategorySelected(subCategory),
                                    );
                                  },
                                ),
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
    );
  }

  Widget _buildAnimatedCategoryItem({
    required CategoryModel category,
    required int index,
    required bool isSelected,
  }) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 50)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: GestureDetector(
              onTap: () => _onCategorySelected(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                                 margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 6),
                                 padding: const EdgeInsets.symmetric(
                   vertical: 14.0,
                   horizontal: 12.0,
                 ),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            primaryColor,
                            primaryDarkColor,
                          ],
                        )
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white,
                            Colors.grey[50]!,
                          ],
                        ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected 
                          ? primaryColor.withOpacity(0.3)
                          : Colors.grey.withOpacity(0.1),
                      blurRadius: isSelected ? 8 : 4,
                      offset: Offset(0, isSelected ? 4 : 2),
                    ),
                  ],
                  border: Border.all(
                    color: isSelected ? primaryColor.withOpacity(0.3) : Colors.grey[200]!,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                                 child: Row(
                   children: [
                                         Expanded(
                       child: Text(
                         category.name,
                         style: TextStyle(
                           fontSize: 12,
                           fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                           color: isSelected ? Colors.white : Colors.grey[800],
                           letterSpacing: isSelected ? 0.3 : 0.0,
                         ),
                         overflow: TextOverflow.ellipsis,
                       ),
                     ),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }


} 