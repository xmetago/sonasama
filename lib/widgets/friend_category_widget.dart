import 'package:flutter/material.dart';
import '../services/hive_database_service.dart';

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
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    widget.friendName.isNotEmpty 
                        ? widget.friendName[0].toUpperCase()
                        : '?',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        widget.friendEmail,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Kategori Seçin:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue[600] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected 
                          ? Border.all(color: Colors.blue[800]!, width: 2)
                          : null,
                    ),
                    child: Text(
                      category.toUpperCase(),
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 12,
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
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[600], size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Kategori: ${selectedCategory!.toUpperCase()}',
                      style: TextStyle(
                        color: Colors.green[800],
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
      title: Text('$friendName Kategorisini Belirle'),
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
          child: const Text('Kapat'),
        ),
      ],
    );
  }
}
