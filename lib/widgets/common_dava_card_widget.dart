import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../widgets/countdown_timer_widget.dart';
import '../services/dava_timer_service.dart';
import '../utils/app_theme.dart';

/// Ortak dava kartı widget'ı - Gelen Davalar ve Katıldığım Davalar için
class CommonDavaCardWidget extends StatelessWidget {
  final String davaAdi;
  final String davaci;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String davaKonusu;
  final String? userEmail;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final bool isAccepted;
  final bool isRejected;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const CommonDavaCardWidget({
    super.key,
    required this.davaAdi,
    required this.davaci,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.davaKonusu = '',
    this.userEmail,
    this.createdAt,
    this.acceptedAt,
    this.isAccepted = false,
    this.isRejected = false,
    this.onAccept,
    this.onReject,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white,
              Colors.grey.shade50,
            ],
          ),
        ),
        child: InkWell(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header - Dava Adı ve Durum
                _buildHeader(context),
                const SizedBox(height: 12),
                
                // Dava Bilgileri
                _buildDavaInfo(context),
                const SizedBox(height: 12),
                
                // Süre Bilgisi (Countdown Timer)
                _buildCountdownSection(context),
                const SizedBox(height: 16),
                
                // Action Buttons
                if (!isAccepted && !isRejected) _buildActionButtons(context),
                
                // Status Display
                if (isAccepted || isRejected) _buildStatusDisplay(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        // Profil Resmi
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.primaryLightColor, width: 2),
          ),
          child: ClipOval(
            child: Image.asset(
              profilResmi,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: AppTheme.primaryUltraLight,
                  child: Icon(
                    MdiIcons.gavel,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Dava Adı ve Durum
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                davaAdi,
              style: AppTheme.headline4,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              _buildStatusBadge(context),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusBadge(BuildContext context) {
    if (isAccepted) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.successUltraLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.successLightColor, width: 1),
      ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.checkCircle, size: 14, color: AppTheme.successColor),
            const SizedBox(width: 4),
            Text(
              'Kabul Edildi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.successDarkColor,
              ),
            ),
          ],
        ),
      );
    } else if (isRejected) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.errorUltraLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.errorLightColor, width: 1),
      ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.closeCircle, size: 14, color: AppTheme.errorColor),
            const SizedBox(width: 4),
            Text(
              'Reddedildi',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.errorColor,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.warningUltraLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.warningLightColor, width: 1),
      ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(MdiIcons.clockOutline, size: 14, color: Colors.orange.shade700),
            const SizedBox(width: 4),
            Text(
              'Beklemede',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDavaInfo(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.textBackgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.dividerColor, width: 1),
      ),
      child: Column(
        children: [
          _buildInfoRow('Davacı', davaci, MdiIcons.account),
          const SizedBox(height: 8),
          _buildInfoRow('Davalı', davali, MdiIcons.accountOutline),
          const SizedBox(height: 8),
          _buildInfoRow('Görev', mevkii, MdiIcons.badgeAccount),
          if (davaKonusu.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildInfoRow('Konu', davaKonusu, MdiIcons.text),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.iconPrimary),
        const SizedBox(width: 8),
        SizedBox(
          width: 60,
          child: Text(
            '$label:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownSection(BuildContext context) {
    final DateTime startTime = acceptedAt ?? createdAt ?? DateTime.now();
    final Duration totalDuration = acceptedAt != null
        ? DavaTimerService.acceptedHukumWindow
        : DavaTimerService.incomingAcceptanceWindow;

    DavaIncomingCountdownSegment? phaseSeg;
    if (!isAccepted && createdAt != null) {
      phaseSeg =
          DavaTimerService.buildIncomingListCountdown(openedAt: createdAt!);
    }

    final timerStart = phaseSeg?.segmentStart ?? startTime;
    final timerDuration = phaseSeg?.totalDuration ?? totalDuration;
    final accent = phaseSeg?.accentColor;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.infoUltraLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.infoLightColor, width: 1),
      ),
      child: Row(
        children: [
          Icon(MdiIcons.timerSand, color: AppTheme.infoColor, size: 20),
          const SizedBox(width: 8),
          Text(
            phaseSeg != null ? '${phaseSeg.phaseLabel}:' : 'Kalan Süre:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.infoColor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: CountdownTimerWidget(
              startTime: timerStart,
              totalDuration: timerDuration,
              accentColor: accent,
              showHourglass: true,
              onTimeUp: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('⏰ Dava süresi doldu!'),
                    backgroundColor: AppTheme.errorColor,
                    duration: Duration(seconds: 3),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        // Kabul Et Butonu
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onAccept,
            icon: Icon(MdiIcons.checkCircle, size: 18),
            label: const Text('Kabul Et'),
            style: AppTheme.successButtonStyle,
          ),
        ),
        const SizedBox(width: 12),
        
        // Reddet Butonu
        Expanded(
          child: ElevatedButton.icon(
            onPressed: onReject,
            icon: Icon(MdiIcons.closeCircle, size: 18),
            label: const Text('Reddet'),
            style: AppTheme.errorButtonStyle,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDisplay(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isAccepted ? AppTheme.successUltraLight : AppTheme.errorUltraLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAccepted ? AppTheme.successLightColor : AppTheme.errorLightColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAccepted ? MdiIcons.checkCircle : MdiIcons.closeCircle,
            color: isAccepted ? AppTheme.successColor : AppTheme.errorColor,
            size: 20,
          ),
          const SizedBox(width: 8),
          Text(
            isAccepted ? 'Dava kabul edildi' : 'Dava reddedildi',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isAccepted ? AppTheme.successDarkColor : AppTheme.errorColor,
            ),
          ),
        ],
      ),
    );
  }
}

/// Basit dava kartı (animasyon olmadan)
class SimpleDavaCardWidget extends StatelessWidget {
  final String davaAdi;
  final String davaci;
  final String davali;
  final String mevkii;
  final String kalanSure;
  final String profilResmi;
  final String? userEmail;
  final bool isAccepted;
  final bool isRejected;
  final VoidCallback? onTap;

  const SimpleDavaCardWidget({
    super.key,
    required this.davaAdi,
    required this.davaci,
    required this.davali,
    required this.mevkii,
    required this.kalanSure,
    required this.profilResmi,
    this.userEmail,
    this.isAccepted = false,
    this.isRejected = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Profil Resmi
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.blue.shade300, width: 1),
                ),
                child: ClipOval(
                  child: Image.asset(
                    profilResmi,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.blue.shade100,
                        child: Icon(
                          MdiIcons.gavel,
                          color: Colors.blue.shade600,
                          size: 20,
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              
              // Dava Bilgileri
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      davaAdi,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Davacı: $davaci',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      'Davalı: $davali',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Durum İkonu
              Icon(
                isAccepted ? MdiIcons.checkCircle : MdiIcons.closeCircle,
                color: isAccepted ? Colors.green.shade600 : Colors.red.shade600,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
