import 'package:flutter/material.dart';

/// Arama sonucu boş olduğunda gösterilecek widget
class EmptySearchResult extends StatelessWidget {
  final String searchQuery;

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
            color: Colors.grey[400],
            semanticLabel: 'Arama sonucu bulunamadı',
          ),
          const SizedBox(height: 16),
          Text(
            'Kategori bulunamadı',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Farklı bir arama terimi deneyin',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Aranan: "$searchQuery"',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[400],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 