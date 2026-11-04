import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import 'actigim_case_card.dart';

/// Modern Dava Kartı Widget'ı - Açtığım Davalar için
/// 168 saatlik geri sayım, hüküm durumu ve modern UI ile
class InactiveDavaCard extends StatelessWidget {
  final Dava dava;
  
  const InactiveDavaCard({super.key, required this.dava});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.5, // Inaktif görünüm için opacity
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.red.shade200, width: 2),
        ),
        color: Colors.red.shade50,
        child: Stack(
          children: [
            // Orijinal FiveCardCaseInformation içeriği
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sol taraf - Profil ve butonlar
                  Container(
                    width: 80,
                    padding: const EdgeInsets.all(9),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              MdiIcons.homeFlood,
                              size: 19,
                              color: Colors.grey,
                            ),
                            const Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        Image.asset(
                          dava.profilResmi.isNotEmpty 
                            ? dava.profilResmi 
                            : 'lib/icons/07_profil_picture_davaci.png',
                          width: 60,
                          height: 50,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 60,
                              height: 50,
                              color: Colors.grey.shade300,
                              child: Icon(Icons.person, color: Colors.grey.shade600),
                            );
                          },
                        ),
                        Row(
                          children: [
                            Icon(
                              MdiIcons.giftOpen,
                              size: 19,
                              color: Colors.grey,
                            ),
                            const Text(
                              'Onayla',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Sağ taraf - Dava bilgileri
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Dava Adı    :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.adi,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Davalı         :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    dava.davali,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(Icons.thumb_down_alt_outlined, size: 25, color: Colors.grey),
                                  const Icon(Icons.thumb_up_alt_outlined, size: 25, color: Colors.grey),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Text(
                              'Mevkii        :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.mevkii,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(MdiIcons.timerAlertOutline, size: 19, color: Colors.grey),
                            const Text(
                              'Kalan Süre :',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dava.kalanSure,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // "RED EDİLDİ" Etiketi
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.red.shade700,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cancel, color: Colors.white, size: 14),
                    SizedBox(width: 4),
                    Text(
                      'RED EDİLDİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 