import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';

class DavetCard extends StatelessWidget {
  final Map<String, dynamic> davet;
  final VoidCallback onMarkAsRead;

  const DavetCard({
    super.key,
    required this.davet,
    required this.onMarkAsRead,
  });

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final isRead = davet['isRead'] ?? false;
    const accent = SeyirTokens.sectionPeople;
    
    return Card(
      elevation: 0,
      color: palette.card,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: SeyirTokens.radiusLgAll,
        side: BorderSide(
          color: isRead ? palette.border : palette.tintBorder(accent),
          width: isRead ? 1 : 1.5,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: SeyirTokens.radiusLgAll,
          color: isRead ? palette.card : palette.tint(accent),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      davet['groupName'] ?? 'Davet',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: SeyirTokens.typeCaption,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (!isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Dava Bilgileri
              Text(
                davet['davaAdi'] ?? 'Dava Adı Belirtilmemiş',
                style: palette.headline(),
              ),
              const SizedBox(height: 8),
              
              if (davet['kategori'] != null && davet['kategori'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    Icon(Icons.category, size: 16, color: palette.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Kategori: ${davet['kategori']}',
                      style: palette.body(color: palette.textSecondary, weight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              if (davet['davaKonusu'] != null && davet['davaKonusu'].toString().isNotEmpty) ...[
                Text(
                  'Dava Konusu:',
                  style: palette.body(color: palette.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  davet['davaKonusu'],
                  style: palette.body(weight: FontWeight.w400),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
              ],
              
              // Davacı ve Davalı
              if (davet['davaci'] != null && davet['davaci'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person, size: 16, color: Colors.green),
                    const SizedBox(width: 4),
                    Text(
                      'Davacı: ${davet['davaci']}',
                      style: palette.body(weight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              if (davet['davali'] != null && davet['davali'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: SeyirTokens.reject),
                    const SizedBox(width: 4),
                    Text(
                      'Davalı: ${davet['davali']}',
                      style: palette.body(weight: FontWeight.w400),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Tarih
              Row(
                children: [
                  Icon(Icons.access_time, size: 16, color: palette.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(davet['invitedAt']),
                    style: palette.caption(),
                  ),
                  const Spacer(),
                  if (!isRead)
                    TextButton(
                      onPressed: onMarkAsRead,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(
                          SeyirTokens.tapTarget,
                          SeyirTokens.tapTarget,
                        ),
                      ),
                      child: const Text('Okundu İşaretle'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return 'Tarih belirtilmemiş';
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}.${date.month}.${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Geçersiz tarih';
    }
  }
}
