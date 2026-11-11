import 'package:flutter/material.dart';
import 'package:flutter_material_design_icons/flutter_material_design_icons.dart';

import '../models/sekiz_hukum_arguments.dart';
import '../screens/delilleri_incele_page.dart' hide Dava, FiveCardCaseInformation;
import '../screens/sekiz_hukum_page.dart';
import 'yargila_case_card.dart';

// Modern Yargıla Card — Dava Künyesi: collapsing (expand/collapse) başlık + içerik
class ModernYargilaCard extends StatefulWidget {
  final Dava dava;
  final String? userEmail;
  final VoidCallback? onTap;
  final DateTime? acceptedAt;

  const ModernYargilaCard({
    super.key,
    required this.dava,
    this.userEmail,
    this.onTap,
    this.acceptedAt,
  });

  @override
  State<ModernYargilaCard> createState() => _ModernYargilaCardState();
}

class _ModernYargilaCardState extends State<ModernYargilaCard> {
  bool _kunyeExpanded = true;

  @override
  Widget build(BuildContext context) {
    final dava = widget.dava;
    final acceptedAt = widget.acceptedAt;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE9E2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101815).withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                // Dava Künyesi — collapsing toolbar benzeri: sabit başlık çubuğu, içerik açılır/kapanır
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFDCE7E1)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() => _kunyeExpanded = !_kunyeExpanded);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Center(
                                        child: Text(
                                          ' || Dava Künyesi ||',
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            color: const Color(0xFF1B2A23),
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
                                ),
                                AnimatedRotation(
                                  turns: _kunyeExpanded ? 0.5 : 0,
                                  duration: const Duration(milliseconds: 220),
                                  curve: Curves.easeOutCubic,
                                  child: Icon(
                                    Icons.expand_more,
                                    color: Colors.grey.shade600,
                                    size: 26,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      AnimatedCrossFade(
                        firstCurve: Curves.easeOutCubic,
                        secondCurve: Curves.easeInCubic,
                        sizeCurve: Curves.easeInOutCubic,
                        duration: const Duration(milliseconds: 280),
                        crossFadeState: _kunyeExpanded
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                        firstChild: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildInfoRow('Göreviniz', dava.mevkii, Icons.gavel_outlined),
                              const SizedBox(height: 3),
                              _buildDashedLine(const Color(0xFFD8E5DE)),
                              const SizedBox(height: 3),
                              _buildInfoRow('Dava Adı', dava.adi, Icons.description),
                              const SizedBox(height: 3),
                              _buildDashedLine(const Color(0xFFD8E5DE)),
                              const SizedBox(height: 3),
                              _buildInfoRow('Davacı', dava.davaci, Icons.person),
                              const SizedBox(height: 3),
                              _buildDashedLine(const Color(0xFFD8E5DE)),
                              const SizedBox(height: 3),
                              _buildInfoRow('Davalı', dava.davali, Icons.person_outline),
                              const SizedBox(height: 3),
                              _buildDashedLine(const Color(0xFFD8E5DE)),
                              const SizedBox(height: 1),
                              buildYargilaCountdownRow(
                                context: context,
                                acceptedAt: acceptedAt,
                              ),
                            ],
                          ),
                        ),
                        secondChild: const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: widget.onTap,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                // Dava Konusu
                dava.davaKonusu.isNotEmpty
                    ? Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6FBF8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFDCE7E1)),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.article, color: Colors.green.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dava Konusu:',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  dava.davaKonusu,
                                  textAlign: TextAlign.justify,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black87,
                                    height: 1.5,
                                  ),
                                )
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      )
                    : const SizedBox.shrink(),
                // Action Buttons Row
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DelilleriIncelePage(
                                userEmail: widget.userEmail,
                                davaId: dava.id, // Seçili davanın ID'sini geç
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          Icons.content_paste_search,
                          size: 24,
                          color: Colors.blue.shade700,
                        ),
                        label: Text(
                          'Deliller',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.withOpacity(0.10),
                          foregroundColor: Colors.blue.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: Colors.blue.withOpacity(0.20),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 34),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          final SekizHukumArguments arguments = SekizHukumArguments(
                            davaId: dava.id.isNotEmpty ? dava.id : null,
                            davaAdi: dava.adi.isNotEmpty ? dava.adi : 'Dava adı belirtilmedi',
                            davaDavali: dava.davali.isNotEmpty ? dava.davali : 'Davalı bilgisi yok',
                            davaDavaci: dava.davaci.isNotEmpty ? dava.davaci : 'Davacı bilgisi yok',
                            davaGorev: dava.mevkii.isNotEmpty ? dava.mevkii : 'Görev bilgisi yok',
                            kalanSure: dava.kalanSure.isNotEmpty ? dava.kalanSure : 'Süre bilgisi yok',
                            openedAt: acceptedAt,
                          );

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SekizHukumPage(
                                userEmail: widget.userEmail,
                                arguments: arguments,
                              ),
                            ),
                          );
                        },
                        icon: Icon(
                          MdiIcons.accountDetails,
                          size: 24,
                          color: Colors.green.shade700,
                        ),
                        label: Text(
                          '8-HÜKÜM',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.withOpacity(0.10),
                          foregroundColor: Colors.green.shade800,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                            side: BorderSide(
                              color: Colors.green.withOpacity(0.20),
                              width: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ),

                  ],
                ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return SizedBox(
      height: 10,
      child: CustomPaint(
        size: const Size(double.infinity, 10),
        painter: DashedLinePainter(color: color, strokeWidth: 1.6),
      ),
    );

  }

  Widget _buildInfoRow(String label, String value, IconData icon, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlight ? Colors.red.shade600 : Colors.green.shade700,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isHighlight ? Colors.red.shade700 : Colors.grey.shade900,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Placeholder for DashedLinePainter (ensure it's implemented in your codebase)
class DashedLinePainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  DashedLinePainter({required this.color, required this.strokeWidth});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    const dashWidth = 5;
    const dashSpace = 6;
    final y = size.height / 2;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, y),
        Offset(startX + dashWidth, y),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

