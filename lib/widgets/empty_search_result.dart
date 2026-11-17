import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'delil_surface.dart';

/// Arama sonucu boş olduğunda gösterilecek yumuşak kart.
class EmptySearchResult extends StatelessWidget {
  final String searchQuery;

  const EmptySearchResult({
    super.key,
    required this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    final String query = searchQuery.trim();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: SeyirTokens.space4),
        child: DelilSoftEmpty(
          title: 'Kategori bulunamadı',
          message: query.isEmpty
              ? 'Farklı bir arama terimi deneyin'
              : '"$query" için eşleşme yok',
          icon: Icons.search_off,
        ),
      ),
    );
  }
}
