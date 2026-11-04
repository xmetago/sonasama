import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'countdown_timer_widget.dart';

// Model class for Dava (unchanged)
class Dava {
  final String id;
  final String adi;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu;
  final String davaci;
  final String userRole;

  Dava({
    required this.id,
    required this.adi,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.davaKonusu = '',
    this.davaci = '',
    this.userRole = '',
  });
}

// Reused Widgets from GelenDavalarPage (unchanged)
class FiveCardCaseInformation extends StatelessWidget {
  final Dava dava;
  final VoidCallback? onTap;

  const FiveCardCaseInformation({super.key, required this.dava, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.grey[200],
                    child: Image.asset(
                      dava.profilResmi,
                      width: 40,
                      height: 40,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(MdiIcons.checkCircle, size: 24, color: Colors.green),
                            const SizedBox(width: 4),
                            const Text('Haklı', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(MdiIcons.closeCircle, size: 24, color: Colors.red),
                            const SizedBox(width: 4),
                            const Text('Haksız', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Dava Information
              _buildInfoRow('Dava Adı', dava.adi, true),
              const SizedBox(height: 8),
              _buildInfoRow('Davalı', dava.davali, true),
              const SizedBox(height: 8),
              _buildInfoRow('Görev', dava.mevkii, false),
              const SizedBox(height: 8),
              buildYargilaCountdownRow(
                context: context,
              ),
              const SizedBox(height: 16),
              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Hüküm yazmak için Göreviniz rozetine dokunun.')),
                      );
                    },
                    icon: const Icon(Icons.gavel, size: 16),
                    label: const Text('8-HÜKÜM', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, bool isEditable, {IconData? icon}) {
    return Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: Colors.green),
          const SizedBox(width: 8),
        ],
        Text(
          '$label:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: isEditable
              ? TextField(
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            decoration: InputDecoration(
              hintText: value,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          )
              : Text(
            value,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

/// Geriye doğru sayan sayaç satırı
Widget buildYargilaCountdownRow({
  required BuildContext context,
  DateTime? acceptedAt,
}) {
  final DateTime startTime =
      acceptedAt ?? DateTime.now().subtract(const Duration(hours: 1));
  const Duration totalDuration = Duration(hours: 168);

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(
          'Kalan Süre :',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade700,
          ),
        ),
      ),
      Expanded(
        child: CountdownTimerWidget(
          startTime: startTime,
          totalDuration: totalDuration,
          showHourglass: true,
          onTimeUp: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⏰ Yargılama süresi doldu!'),
                backgroundColor: Colors.red,
                duration: Duration(seconds: 3),
              ),
            );
          },
        ),
      ),
    ],
  );
}