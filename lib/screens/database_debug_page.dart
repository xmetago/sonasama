import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/registration_model.dart';
import '../services/hive_database_service.dart';
import '../theme/seyir_tokens.dart';
import '../widgets/delil_surface.dart';

class DatabaseDebugPage extends StatefulWidget {
  const DatabaseDebugPage({super.key, this.userEmail});

  final String? userEmail;

  @override
  State<DatabaseDebugPage> createState() => _DatabaseDebugPageState();
}

class _DatabaseDebugPageState extends State<DatabaseDebugPage> {
  List<RegistrationModel> users = [];
  Map<String, int> stats = {};

  static const Map<String, String> _statLabels = {
    'davalar': 'Davalar',
    'acilan_davalar': 'Açılan davalar',
    'kaydedilen_davalar': 'Kaydedilen davalar',
    'gelen_davalar': 'Gelen davalar',
    'kullanicilar': 'Kullanıcılar',
    'kayitlar': 'Kayıtlar',
    'yorumlar': 'Yorumlar',
    'kategoriler': 'Kategoriler',
    'aktif_kategoriler': 'Aktif kategoriler',
  };

  bool get _authorized =>
      kDebugMode && HiveDatabaseService.isAdmin(widget.userEmail);

  @override
  void initState() {
    super.initState();
    if (_authorized) {
      _loadData();
    }
  }

  void _loadData() {
    if (!_authorized) return;
    setState(() {
      users = HiveDatabaseService.getAllRegistrations();
      stats = HiveDatabaseService.getDatabaseStats();
    });
  }

  String _statLabel(String key) => _statLabels[key] ?? key;

  ButtonStyle _iconTap(SeyirPalette palette) {
    return IconButton.styleFrom(
      minimumSize: const Size(SeyirTokens.tapTarget, SeyirTokens.tapTarget),
      tapTargetSize: MaterialTapTargetSize.padded,
      foregroundColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    final accent = palette.isDark ? SeyirTokens.brand : const Color(0xFF059669);
    return Scaffold(
      backgroundColor: palette.surface,
      appBar: AppBar(
        title: Text('Veritabanı Debug', style: palette.headline(color: Colors.white)),
        backgroundColor: const Color(0xFF059669),
        foregroundColor: Colors.white,
        actions: [
          if (_authorized)
            IconButton(
              style: _iconTap(palette),
              tooltip: 'Yenile',
              icon: const Icon(Icons.refresh),
              onPressed: _loadData,
            ),
        ],
      ),
      body: !_authorized
          ? const Padding(
              padding: EdgeInsets.all(SeyirTokens.space4),
              child: DelilSoftEmpty(
                title: 'Yetkiniz yok',
                message: 'Bu sayfayı yalnızca yöneticiler kullanabilir.',
                icon: Icons.lock_outline,
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: palette.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                      side: BorderSide(color: palette.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(SeyirTokens.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '📊 Veritabanı İstatistikleri',
                            style: palette.headline(),
                          ),
                          const SizedBox(height: SeyirTokens.space3),
                          ...stats.entries.map((entry) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: SeyirTokens.space1,
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_statLabel(entry.key)}:',
                                      style: palette.body(),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: SeyirTokens.space2,
                                        vertical: SeyirTokens.space1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: accent,
                                        borderRadius: SeyirTokens.radiusMdAll,
                                      ),
                                      child: Text(
                                        '${entry.value}',
                                        style: palette.body(
                                          color: palette.onSolid(accent),
                                          weight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: SeyirTokens.space6),
                  Card(
                    color: palette.card,
                    shape: RoundedRectangleBorder(
                      borderRadius: SeyirTokens.radiusMdAll,
                      side: BorderSide(color: palette.border),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(SeyirTokens.space4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '👥 Kayıtlı Kullanıcılar (${users.length})',
                                  style: palette.headline(),
                                ),
                              ),
                              IconButton(
                                style: IconButton.styleFrom(
                                  minimumSize: const Size(
                                    SeyirTokens.tapTarget,
                                    SeyirTokens.tapTarget,
                                  ),
                                  tapTargetSize: MaterialTapTargetSize.padded,
                                  foregroundColor: accent,
                                ),
                                tooltip: 'Yenile',
                                icon: const Icon(Icons.refresh),
                                onPressed: _loadData,
                              ),
                            ],
                          ),
                          const SizedBox(height: SeyirTokens.space3),
                          if (users.isEmpty)
                            const DelilSoftEmpty(
                              title: 'Henüz kayıtlı kullanıcı yok',
                              message: 'Kayıtlı kullanıcı listesi boş.',
                              icon: Icons.people_outline,
                            )
                          else
                            ...users.map((user) => _buildUserCard(user, palette)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserCard(RegistrationModel user, SeyirPalette palette) {
    final adminColor = palette.isDark ? const Color(0xFFF87171) : SeyirTokens.reject;
    return Container(
      margin: const EdgeInsets.only(bottom: SeyirTokens.space3),
      padding: const EdgeInsets.all(SeyirTokens.space4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(
          color: user.isAdmin ? adminColor : palette.border,
          width: user.isAdmin ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                user.isAdmin ? Icons.admin_panel_settings : Icons.person,
                color: user.isAdmin ? adminColor : palette.textSecondary,
                size: 20,
              ),
              const SizedBox(width: SeyirTokens.space2),
              Expanded(
                child: Text(
                  user.judgeName,
                  style: palette.title(
                    color: user.isAdmin ? adminColor : palette.textPrimary,
                  ),
                ),
              ),
              if (user.isAdmin)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: SeyirTokens.space2,
                    vertical: SeyirTokens.space1,
                  ),
                  decoration: BoxDecoration(
                    color: adminColor,
                    borderRadius: SeyirTokens.radiusSmAll,
                  ),
                  child: Text(
                    'ADMİN',
                    style: palette.caption(
                      color: palette.onSolid(adminColor),
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: SeyirTokens.space2),
          Row(
            children: [
              Icon(Icons.email, size: 16, color: palette.textMuted),
              const SizedBox(width: SeyirTokens.space2),
              Expanded(
                child: Text(user.email, style: palette.body()),
              ),
            ],
          ),
          const SizedBox(height: SeyirTokens.space1),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: palette.textMuted),
              const SizedBox(width: SeyirTokens.space2),
              Text(user.country, style: palette.body()),
            ],
          ),
          const SizedBox(height: SeyirTokens.space2),
          Wrap(
            spacing: SeyirTokens.space2,
            runSpacing: SeyirTokens.space1,
            children: [
              _buildStatusChip(
                'Aktif',
                user.isActive ? SeyirTokens.accept : SeyirTokens.reject,
                user.isActive,
                palette,
              ),
              _buildStatusChip(
                'E-posta Doğrulandı',
                user.isEmailVerified ? const Color(0xFF2563EB) : SeyirTokens.warning,
                user.isEmailVerified,
                palette,
              ),
              _buildStatusChip(
                'Giriş Yapabilir',
                user.canLogin ? SeyirTokens.accept : SeyirTokens.reject,
                user.canLogin,
                palette,
              ),
              if (user.isLocked)
                _buildStatusChip('Kilitli', SeyirTokens.reject, true, palette),
            ],
          ),
          const SizedBox(height: SeyirTokens.space2),
          Text(
            'Kayıt Tarihi: ${_formatDateTime(user.createdAt)}',
            style: palette.caption(),
          ),
          Text(
            'Son Giriş: ${_formatDateTime(user.lastLoginAt)}',
            style: palette.caption(),
          ),
          if (user.lastDavaAcTime != null)
            Text(
              'Son Dava Açma: ${_formatDateTime(user.lastDavaAcTime!)}',
              style: palette.caption(),
            ),
          if (user.lastHaykirTime != null)
            Text(
              'Son Haykırma: ${_formatDateTime(user.lastHaykirTime!)}',
              style: palette.caption(),
            ),
          if (user.loginAttempts > 0)
            Text(
              'Giriş Denemeleri: ${user.loginAttempts}',
              style: palette.caption(
                color: palette.foreground(SeyirTokens.warning),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(
    String label,
    Color color,
    bool isActive,
    SeyirPalette palette,
  ) {
    final foreground = isActive ? palette.foreground(color) : palette.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: isActive ? palette.tint(color) : palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusMdAll,
        border: Border.all(
          color: isActive ? palette.tintBorder(color) : palette.border,
        ),
      ),
      child: Text(
        label,
        style: palette.caption(color: foreground),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')}.${dateTime.year} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}
