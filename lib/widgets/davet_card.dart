import 'package:flutter/material.dart';

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
    final isRead = davet['isRead'] ?? false;
    
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isRead ? Colors.grey[50] : Colors.blue[50],
          border: isRead ? null : Border.all(color: Colors.blue[200]!, width: 2),
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
                        fontSize: 12,
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              
              if (davet['kategori'] != null && davet['kategori'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.category, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Kategori: ${davet['kategori']}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              if (davet['davaKonusu'] != null && davet['davaKonusu'].toString().isNotEmpty) ...[
                const Text(
                  'Dava Konusu:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  davet['davaKonusu'],
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
              ],
              
              if (davet['davali'] != null && davet['davali'].toString().isNotEmpty) ...[
                Row(
                  children: [
                    const Icon(Icons.person_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 4),
                    Text(
                      'Davalı: ${davet['davali']}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // Tarih
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(davet['invitedAt']),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (!isRead)
                    TextButton(
                      onPressed: onMarkAsRead,
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
