import 'package:flutter/material.dart';

/// Arama sonucu boş olduğunda gösterilecek widget
class EmptySearchResult extends StatelessWidget {
  final String searchQuery;

  // Site genelindeki ana renk teması
  static const Color primaryColor = Color(0xFF059669); // Koyu yeşil
  static const Color primaryLightColor = Color(0xFF10B981); // Açık yeşil

  const EmptySearchResult({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: primaryLightColor.withOpacity(0.6),
            semanticLabel: 'Arama sonucu bulunamadı',
          ),
          const SizedBox(height: 16),
          const Text(
            'Kategori bulunamadı',
            style: TextStyle(
              fontSize: 16,
              color: primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir arama terimi deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primaryLightColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryLightColor.withOpacity(0.3)),
              ),
              child: Text(
                'Aranan: "$searchQuery"',
                style: const TextStyle(
                  fontSize: 12,
                  color: primaryColor,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
} 