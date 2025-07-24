import 'package:flutter/material.dart';

/// Alt kategori tile widget'ı - Yeniden kullanılabilir ve test edilebilir
class SubCategoryTile extends StatelessWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;

  const SubCategoryTile(
    this.title, {
    super.key,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12.0),
        padding: const EdgeInsets.symmetric(
          vertical: 12.0,
          horizontal: 16.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red[100] : Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? Colors.red[300]! : Colors.red[200]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.arrow_right,
              size: 16,
              color: Colors.red[600],
              semanticLabel: 'Alt kategori oku',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                  color: Colors.red[700],
                ),
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 16,
              color: Colors.red[400],
              semanticLabel: 'Detay görüntüle',
            ),
          ],
        ),
      ),
    );
  }
} 