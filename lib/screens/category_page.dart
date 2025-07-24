import 'package:flutter/material.dart';
import '../data/category_data.dart';
import '../widgets/sub_category_tile.dart';
import '../widgets/category_search_bar.dart';
import '../widgets/empty_search_result.dart';
import 'dava_ac_page.dart';

/// Kategori seçim sayfası - Modüler ve performanslı tasarım
class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int selectedCategoryIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> get filteredCategories => 
      CategoryData.filterCategories(_searchQuery);

  @override
  void dispose() {
    _searchController.dispose();
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
    // Dava aç sayfasına yönlendir
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const DavaAcPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final categoryPanelWidth = screenWidth * 0.35; // Responsive genişlik

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Kategoriler',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red[600],
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kapat',
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
                    : Row(
                        children: [
                          // Sol taraf - Ana kategoriler
                          Container(
                            width: categoryPanelWidth,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(16),
                                bottomLeft: Radius.circular(16),
                              ),
                            ),
                            child: ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                String category = filteredCategories[index];
                                bool isSelected = selectedCategoryIndex == index;

                                return GestureDetector(
                                  onTap: () => _onCategorySelected(index),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16.0,
                                      horizontal: 12.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.red[50] : Colors.transparent,
                                      border: Border(
                                        right: BorderSide(
                                          color: isSelected ? Colors.red[300]! : Colors.grey[300]!,
                                          width: isSelected ? 3 : 1,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.circle,
                                          size: 8,
                                          color: isSelected ? Colors.red[600] : Colors.grey[400],
                                          semanticLabel: isSelected ? 'Seçili kategori' : 'Kategori',
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            category,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                              color: isSelected ? Colors.red[700] : Colors.grey[700],
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // Sağ taraf - Alt kategoriler
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16.0),
                              itemCount: CategoryData.getSubCategories(
                                  filteredCategories[selectedCategoryIndex]).length,
                              itemBuilder: (context, index) {
                                String subCategory = CategoryData.getSubCategories(
                                    filteredCategories[selectedCategoryIndex])[index];

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

            // Alt bilgi alanı
            Container(
              margin: const EdgeInsets.all(16.0),
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.red[600],
                    size: 20,
                    semanticLabel: 'Bilgi ikonu',
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Katagorini seç, dava aç, kitlelere ulaş',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
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
      ),
    );
  }
} 