import 'package:flutter/material.dart';

/// Liste boşken veya arama eşleşmediğinde gösterilen kart.
///
/// Sorgu doluysa başlık her zaman "Arama sonucuna ulaşılamadı" olur ve
/// altında `"sorgu" için eşleşme yok` yazılır. Sorgu boşsa [emptyMessage] gösterilir.
class AppEmptyResultCard extends StatelessWidget {
  const AppEmptyResultCard({
    super.key,
    required this.query,
    required this.emptyMessage,
    required this.icon,
  });

  final String query;
  final String emptyMessage;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasQuery = query.isNotEmpty;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              icon,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            hasQuery ? 'Arama sonucuna ulaşılamadı' : emptyMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[800],
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (hasQuery) ...[
            const SizedBox(height: 8),
            Text(
              '"$query" için eşleşme yok',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
