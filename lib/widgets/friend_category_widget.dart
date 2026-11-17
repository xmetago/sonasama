import 'package:flutter/material.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';

/// Arkadaş kategorilendirme widget'ı
/// Kullanıcının arkadaşlarını kategorilere ayırmasını sağlar
class FriendCategoryWidget extends StatefulWidget {
  final String ownerEmail;
  final String friendEmail;
  final String friendName;
  final String? currentCategory;
  final Function(String category)? onCategoryChanged;

  const FriendCategoryWidget({
    super.key,
    required this.ownerEmail,
    required this.friendEmail,
    required this.friendName,
    this.currentCategory,
    this.onCategoryChanged,
  });

  @override
  State<FriendCategoryWidget> createState() => _FriendCategoryWidgetState();
}

class _FriendCategoryWidgetState extends State<FriendCategoryWidget> {
  String? selectedCategory;
  
  // Mevcut kategoriler
  static const List<String> categories = [
    'yakın',
    'iş',
    'okul',
    'diğer',
  ];

  @override
  void initState() {
    super.initState();
    selectedCategory = widget.currentCategory;
  }

  Future<void> _updateCategory(String category) async {
    try {
      await HiveDatabaseService.setFriendCategory(
        ownerEmail: widget.ownerEmail,
        friendEmail: widget.friendEmail,
        category: category,
      );
      
      setState(() {
        selectedCategory = category;
      });
      
      widget.onCategoryChanged?.call(category);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${widget.friendName} "$category" kategorisine eklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Kategori güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Card(
      elevation: 0,
      color: palette.card,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusLgAll,
        side: BorderSide(color: palette.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: palette.tint(SeyirTokens.sectionPeople),
                  child: Text(
                    widget.friendName.isNotEmpty 
                        ? widget.friendName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: palette.foreground(SeyirTokens.sectionPeople),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.friendName,
                        style: palette.title(),
                      ),
                      Text(
                        widget.friendEmail,
                        style: palette.caption(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Kategori Seçin:',
              style: palette.body(weight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: categories.map((category) {
                final isSelected = selectedCategory == category;
                return GestureDetector(
                  onTap: () => _updateCategory(category),
                  child: Container(
                    constraints: const BoxConstraints(
                      minHeight: SeyirTokens.tapTarget,
                    ),
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? SeyirTokens.sectionPeople
                          : palette.surfaceMuted,
                      borderRadius: BorderRadius.circular(SeyirTokens.radiusXl),
                      border: Border.all(
                        color: isSelected
                            ? palette.tintBorder(SeyirTokens.sectionPeople)
                            : palette.border,
                      ),
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: isSelected
                            ? palette.onSolid(SeyirTokens.sectionPeople)
                            : palette.textPrimary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: SeyirTokens.typeCaption,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (selectedCategory != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: palette.brandSoft,
                  borderRadius: SeyirTokens.radiusSmAll,
                  border: Border.all(color: palette.tintBorder(SeyirTokens.brand)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Kategori: ${selectedCategory!.toUpperCase()}',
                      style: palette.caption(
                        color: palette.isDark ? SeyirTokens.brand : SeyirTokens.brandDeep,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Arkadaş kategorilendirme dialog'u
class FriendCategoryDialog extends StatelessWidget {
  final String ownerEmail;
  final String friendEmail;
  final String friendName;
  final String? currentCategory;

  const FriendCategoryDialog({
    super.key,
    required this.ownerEmail,
    required this.friendEmail,
    required this.friendName,
    this.currentCategory,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        '$friendName Kategorisini Belirle',
        style: SeyirPalette.of(context).title(),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: FriendCategoryWidget(
          ownerEmail: ownerEmail,
          friendEmail: friendEmail,
          friendName: friendName,
          currentCategory: currentCategory,
          onCategoryChanged: (category) {
            Navigator.of(context).pop(category);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(
            minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
          ),
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
