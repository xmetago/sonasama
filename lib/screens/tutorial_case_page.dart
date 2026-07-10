import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TutorialCasePage extends StatefulWidget {
  const TutorialCasePage({
    super.key,
    required this.isAuthenticated,
    required this.userEmail,
    this.onRequestLogin,
  });

  final bool isAuthenticated;
  final String? userEmail;
  final VoidCallback? onRequestLogin;

  /// v2: Güncel içerik; tamamlanma bayrağı önceki sürümden bağımsızdır.
  static const String caseId = 'tutorial_devil_case_v2';

  static const String tutorialDavaAdi = 'Şeytanın hileleri';
  static const String tutorialKategori = 'Dini Dava';
  static const String tutorialDavaci = 'Edip YÜKSEL';
  static const String tutorialDavali = 'Şeytan ve Müritleri';
  static const String rolDavaciAvukati = 'Davacı Avukatı';
  static const String rolDavaliAvukati = 'Davalı Avukatı';

  static const String verdictSeytanHakliKey = 'seytan_hakli';
  static const String verdictSeytanHaksizKey = 'seytan_haksiz';

  static String tutorialAcilisTarihiDisplay() {
    const int d = 19;
    const int m = 7;
    const int y = 1974;
    return '${d.toString().padLeft(2, '0')}.${m.toString().padLeft(2, '0')}.$y';
  }

  static String verdictDisplayLabel(String storedKey) {
    if (storedKey == verdictSeytanHakliKey) return 'Şeytan haklı';
    if (storedKey == verdictSeytanHaksizKey) return 'Şeytan Haksız';
    return storedKey;
  }

  static String _completedKey(String email) => 'tutorial_${caseId}_completed_$email';
  static String _verdictKey(String email) => 'tutorial_${caseId}_verdict_$email';
  static String _attorneyRoleKey(String email) =>
      'tutorial_${caseId}_attorney_role_$email';

  static Future<bool> isCompletedForUser(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_completedKey(email)) ?? false;
  }

  static Future<void> saveVerdict({
    required String email,
    required String verdictKey,
    required String attorneyRoleLabel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_verdictKey(email), verdictKey);
    await prefs.setString(_attorneyRoleKey(email), attorneyRoleLabel);
    await prefs.setBool(_completedKey(email), true);
  }

  @override
  State<TutorialCasePage> createState() => _TutorialCasePageState();
}

class _TutorialCasePageState extends State<TutorialCasePage> {
  bool _davaciAvukati = true;

  String get _gorev =>
      _davaciAvukati ? TutorialCasePage.rolDavaciAvukati : TutorialCasePage.rolDavaliAvukati;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Günün Davası'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _CaseHeader(gorev: _gorev),
            const SizedBox(height: 16),
            const _SectionTitle('📝 DAVA ÖZETİ'),
            const SizedBox(height: 8),
            _InfoCard(
              title: 'Kategori: ${TutorialCasePage.tutorialKategori}',
              body:
                  'Dava adı: ${TutorialCasePage.tutorialDavaAdi}\n'
                  'Davacı: ${TutorialCasePage.tutorialDavaci}\n'
                  'Davalı: ${TutorialCasePage.tutorialDavali}\n\n'
                  'Konu: İnsanlığı saptırmak, hile ile kandırmak ve yaratıcıya isyan.\n\n'
                  'İddianame özeti: "Ey Şeytan! Sen 70 yıl ibadet edenleri bile saptıran, şükürden alıkoyan, kötülük fısıltılarıyla dünyayı kirleten bir müstebitsin. Ademi cennetten kovduran, zincire vurulması gereken en büyük suçlu sensin!"\n\n'
                  'Dava açılış tarihi: ${TutorialCasePage.tutorialAcilisTarihiDisplay()}',
              backgroundColor: _parchmentColor,
            ),
            const SizedBox(height: 16),
            const _SectionTitle('🛡️ SAVUNMA MAKAMI'),
            const SizedBox(height: 8),
            _EvidenceCard(
              title: 'Davacı Avukatı (siz — müvekkil: ${TutorialCasePage.tutorialDavaci})',
              body:
                  '“Müvekkilim davacı sıfatıyla haklılığını arıyor. İnsanın yaptığı kötülüklerde suçu dışarıda araması vicdan muhasebesidir; ancak ${TutorialCasePage.tutorialDavali} tarafının insan üzerindeki vesvese ve aldatma rolü de kayıt altındadır.”',
            ),
            const SizedBox(height: 8),
            const _EvidenceCard(
              title: 'Şahit ihsan ELİAÇIK',
              body:
                  '“Şeytan hiçbir olaya fiili olarak karışmaz. Ücret talep etmeden kötülüğün nasıl \'profesyonelce\' yapılacağını gösterir. Eğer insan meleği değil de onu dinliyorsa, bu insanın irade zayıflığıdır.”',
            ),
            const SizedBox(height: 8),
            const _EvidenceCard(
              title: '2. Jüri (Mustafa İSLAMOĞLU)',
              body:
                  '“İnsan, nefsini terbiye edemediği için Şeytan’ı günah keçisi ilan ediyor. Şeytan en azından Rabbinden korktuğunu beyan eder, oysa insan hem kan döker hem de inkâr eder. Şeytan suçsuzdur.”',
            ),
            const SizedBox(height: 16),
            const _SectionTitle('⚔️ İDDİA MAKAMI'),
            const SizedBox(height: 8),
            const _EvidenceCard(
              title: 'Avukat Reşad HALİFE',
              body:
                  '“Her şey Şeytan\'ın kibriyle başladı. \'Ben ondan hayırlıyım\' diyerek huzurdan kovuldu. İnsanları saptırmak için ant içti. Hz. Adem ve eşini yalan yere yemin ederek kandırdı. İnsanın dünya sürgününün tek sebebi onun hileleridir. Şeytan suçludur!”',
            ),
            const SizedBox(height: 8),
            const _EvidenceCard(
              title: 'Şahit Ali ŞERİATİ',
              body:
                  '“O bir faşisttir; kendi ırkını üstün görür. Rahip Barsisa gibi 70 yıllık abidleri bile katil ve kâfir yapana kadar uğraşır. Peygamberimizin sunduğu tevbe fırsatını bile kibri yüzünden reddetmiştir. O, kötülüğün kaynağıdır.”',
            ),
            const SizedBox(height: 8),
            const _EvidenceCard(
              title: '1. Jüri (Nasrullah Keskin)',
              body:
                  '“Şeytan olmasaydı insan kötülüğü düşünmezdi. O, iyiyi kötü, kötüyü iyi gösteren bir illüzyonisttir. Yeryüzünde fesat çıkarıp \'biz ıslah edicileriz\' diyenlerin akıl hocasıdır. Suçludur!”',
            ),
            const SizedBox(height: 16),
            const _SectionTitle('Deliller'),
            const SizedBox(height: 12),
            const _EvidenceCard(
              title: 'Delil 1: İsyan ve Kibir',
              body:
                  'Şeytanın ilk suçu, yaratıcının emrine doğrudan karşı gelmektir. "Ben ondan hayırlıyım, beni ateşten yarattın onu çamurdan yarattın" diyerek büyüklük taslamış ve secde etmemiştir. Kibir, işlenen ilk günahtır ve şeytan bu günahın mimarıdır.',
            ),
            const SizedBox(height: 12),
            const _EvidenceCard(
              title: 'Delil 2: Yeminli Düşmanlık',
              body:
                  'Kovulduğunda pişmanlık duymamış, aksine yaratıcıya meydan okuyarak "beni azdırmana karşılık, and içerim ki insanları saptıracağım" demiştir. Düşmanlığını yeminle pekiştiren şeytan, artık insanlığın ebedi düşmanıdır.',
            ),
            const SizedBox(height: 12),
            const _EvidenceCard(
              title: 'Delil 3: Aldatma ve Yalan',
              body:
                  'Adem ve Havva\'yı kandırmak için yaratıcı adına yalan yemin etmiş, "Rabbiniz sizi ancak melek olursunuz diye men etti" diyerek onları aldatmıştır. Yalan, şeytanın en temel silahıdır.',
            ),
            const SizedBox(height: 12),
            const _EvidenceCard(
              title: 'Delil 4: Rahip Barsisa Faciası',
              body:
                  '70 yıl ibadet eden bir rahibi bile saptırmış; önce zinaya, ardından cinayete ve sonunda küfre sürüklemiştir. En dindar insanı bile düşürebilecek güçtedir.',
            ),
            const SizedBox(height: 16),

            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Masraf',
              body: '@xmetago instagram hesabını takip et',
            ),
            const SizedBox(height: 12),
            const _InfoCard(
              title: 'Ceza',
              body: '19 kere dua oku. Tövbe et ve Tanrının seni af etmesi için Haykır.',
            ),
            const SizedBox(height: 20),

            const SizedBox(height: 12),
            _ClosingText(gorev: _gorev),
            const SizedBox(height: 16),
            _DecisionArea(
              isAuthenticated: widget.isAuthenticated,
              userEmail: widget.userEmail,
              onRequestLogin: widget.onRequestLogin,
              currentAttorneyRole: _gorev,
              davaciAvukatiMode: _davaciAvukati,
              onDavaciHaksiz: () => setState(() => _davaciAvukati = false),
              onDonDavaciAvukati: () => setState(() => _davaciAvukati = true),
            ),
          ],
        ),
      ),
    );
  }
}

class _CaseHeader extends StatelessWidget {
  const _CaseHeader({required this.gorev});

  final String gorev;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚖️ WHOBOOM ADALET SARAYI',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'İLK DAVA: ${TutorialCasePage.tutorialDavaAdi.toUpperCase()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Kategori: ${TutorialCasePage.tutorialKategori}\n'
              'Dava açılışı: ${TutorialCasePage.tutorialAcilisTarihiDisplay()}',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade800, height: 1.35),
            ),
            const SizedBox(height: 8),
            Text(
              'Benim görevim: $gorev',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
    );
  }
}

class _EvidenceCard extends StatelessWidget {
  const _EvidenceCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text(body, style: const TextStyle(height: 1.45)),
          ],
        ),
      ),
    );
  }
}

/// Eski parşömen rengi (Old Lace) - Dava özeti kartı için
const Color _parchmentColor = Color(0xFFFDF5E6);

/// CTA renkleri - Hüküm butonları (reklamcılık / call-to-action uyumlu)
const Color _ctaHakliColor = Color(0xFF047857); // Şeytan haklı
const Color _ctaHaksizColor = Color(0xFFB91C1C); // Şeytan Haksız
const Color _ctaPrimaryColor = Color(0xFF059669); // Ana CTA (giriş yap)

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.body,
    this.backgroundColor,
  });

  final String title;
  final String body;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        color: backgroundColor ?? Colors.grey.shade50,
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    );
  }
}

class _ClosingText extends StatelessWidget {
  const _ClosingText({required this.gorev});

  final String gorev;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        '🏛️ HÜKÜM ZAMANI\n\n'
        'Göreviniz: $gorev.\n\n'
        'Bu ilk davada davalı taraf (${TutorialCasePage.tutorialDavali}) için kararınızı seçin:\n'
        '• Şeytan haklı\n'
        '• Şeytan Haksız\n\n'
        'İpucu: Varsayılan olarak ${TutorialCasePage.rolDavaciAvukati} olarak görünürsünüz. '
        '"Davacı Haksız" ile ${TutorialCasePage.rolDavaliAvukati} rolüne geçebilirsiniz.',
        style: const TextStyle(height: 1.5),
      ),
    );
  }
}

class _DecisionArea extends StatelessWidget {
  const _DecisionArea({
    required this.isAuthenticated,
    required this.userEmail,
    required this.onRequestLogin,
    required this.currentAttorneyRole,
    required this.davaciAvukatiMode,
    required this.onDavaciHaksiz,
    required this.onDonDavaciAvukati,
  });

  final bool isAuthenticated;
  final String? userEmail;
  final VoidCallback? onRequestLogin;
  final String currentAttorneyRole;
  final bool davaciAvukatiMode;
  final VoidCallback onDavaciHaksiz;
  final VoidCallback onDonDavaciAvukati;

  static const double _ctaElevation = 4.0;
  static const double _ctaPaddingVertical = 20.0;
  static const double _ctaBorderRadius = 16.0;
  static const double _ctaFontSize = 17.0;

  Widget _buildVerdictButton({
    required String label,
    required Color color,
    required VoidCallback? onPressed,
    bool enabled = true,
  }) {
    final bgColor = enabled ? color : Colors.grey.shade400;
    return Material(
      elevation: enabled ? _ctaElevation : 0,
      shadowColor: color.withOpacity(0.5),
      borderRadius: BorderRadius.circular(_ctaBorderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_ctaBorderRadius),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: _ctaPaddingVertical),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_ctaBorderRadius),
            ),
            textStyle: const TextStyle(
              fontSize: _ctaFontSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          child: Text(label),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isAuthenticated) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _buildVerdictButton(
                  label: 'Şeytan haklı',
                  color: _ctaHakliColor,
                  onPressed: null,
                  enabled: false,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildVerdictButton(
                  label: 'Şeytan Haksız',
                  color: _ctaHaksizColor,
                  onPressed: null,
                  enabled: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Material(
            elevation: _ctaElevation,
            shadowColor: _ctaPrimaryColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(_ctaBorderRadius),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_ctaBorderRadius),
                gradient: const LinearGradient(
                  colors: [_ctaPrimaryColor, Color(0xFF047857)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ctaPrimaryColor.withOpacity(0.4),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  if (onRequestLogin != null) {
                    onRequestLogin!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(_ctaBorderRadius),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                child: const Text('GİRİŞ YAP VE HÜKMÜNÜ VER'),
              ),
            ),
          ),
        ],
      );
    }

    final email = (userEmail ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Şu anki göreviniz: $currentAttorneyRole',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        if (davaciAvukatiMode)
          TextButton.icon(
            onPressed: onDavaciHaksiz,
            icon: const Icon(Icons.swap_horiz),
            label: const Text('Davacı Haksız — Davalı Avukatı olarak yaz'),
          )
        else
          TextButton.icon(
            onPressed: onDonDavaciAvukati,
            icon: const Icon(Icons.undo),
            label: const Text('Davacı Avukatına dön'),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildVerdictButton(
                label: 'Şeytan haklı',
                color: _ctaHakliColor,
                onPressed: email.isEmpty
                    ? null
                    : () async {
                        await TutorialCasePage.saveVerdict(
                          email: email,
                          verdictKey: TutorialCasePage.verdictSeytanHakliKey,
                          attorneyRoleLabel: currentAttorneyRole,
                        );
                        if (!context.mounted) return;
                        final lbl = TutorialCasePage.verdictDisplayLabel(
                          TutorialCasePage.verdictSeytanHakliKey,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hükmünüz: $lbl ($currentAttorneyRole)'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        Navigator.of(context).maybePop();
                      },
                enabled: email.isNotEmpty,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildVerdictButton(
                label: 'Şeytan Haksız',
                color: _ctaHaksizColor,
                onPressed: email.isEmpty
                    ? null
                    : () async {
                        await TutorialCasePage.saveVerdict(
                          email: email,
                          verdictKey: TutorialCasePage.verdictSeytanHaksizKey,
                          attorneyRoleLabel: currentAttorneyRole,
                        );
                        if (!context.mounted) return;
                        final lbl = TutorialCasePage.verdictDisplayLabel(
                          TutorialCasePage.verdictSeytanHaksizKey,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Hükmünüz: $lbl ($currentAttorneyRole)'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                        Navigator.of(context).maybePop();
                      },
                enabled: email.isNotEmpty,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
