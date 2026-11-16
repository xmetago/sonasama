import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../theme/seyir_tokens.dart';
import 'actigim_case_card.dart';

/// Modern Dava Kartı Widget'ı - Açtığım Davalar için
/// 168 saatlik geri sayım, hüküm durumu ve modern UI ile
class InactiveDavaCard extends StatelessWidget {
  final Dava dava;
  
  const InactiveDavaCard({super.key, required this.dava});

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final Color muted = palette.textSecondary;
    final TextStyle onayla = TextStyle(
      fontSize: SeyirTokens.typeCaption,
      fontWeight: FontWeight.bold,
      color: muted,
    );
    final TextStyle field = TextStyle(
      fontSize: SeyirTokens.typeBody,
      fontWeight: FontWeight.bold,
      color: muted,
    );
    return Opacity(
      opacity: 0.5, // Inaktif görünüm için opacity
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: palette.tintBorder(SeyirTokens.reject), width: 2),
        ),
        color: palette.tint(SeyirTokens.reject),
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
                              color: muted,
                            ),
                            Text(
                              'Onayla',
                              style: onayla,
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
                              color: palette.surfaceMuted,
                              child: Icon(Icons.person, color: palette.textMuted),
                            );
                          },
                        ),
                        Row(
                          children: [
                            Icon(
                              MdiIcons.giftOpen,
                              size: 19,
                              color: muted,
                            ),
                            Text(
                              'Onayla',
                              style: onayla,
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
                            Text(
                              'Dava Adı    :',
                              style: field,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.adi,
                                style: field,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Davalı         :',
                              style: field,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    dava.davali,
                                    style: field,
                                  ),
                                  const Spacer(),
                                  Icon(Icons.thumb_down_alt_outlined, size: 25, color: muted),
                                  Icon(Icons.thumb_up_alt_outlined, size: 25, color: muted),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(
                              'Mevkii        :',
                              style: field,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                dava.mevkii,
                                style: field,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(MdiIcons.timerAlertOutline, size: 19, color: muted),
                            Text(
                              'Kalan Süre :',
                              style: field,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              dava.kalanSure,
                              style: field,
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
                  color: SeyirTokens.reject,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: SeyirTokens.reject.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.cancel,
                      color: palette.onSolid(SeyirTokens.reject),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'RED EDİLDİ',
                      style: TextStyle(
                        color: palette.onSolid(SeyirTokens.reject),
                        fontSize: SeyirTokens.typeCaption,
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