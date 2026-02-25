import 'package:flutter/material.dart';
import 'confetti_animation_widget.dart';
import 'lottie_animation_overlay.dart';

/// Komik ve modern sokak eylemi kartı; Haykır deneyimini oyuncu bir şekilde yönetir.
class StreetActionHaykirCard extends StatefulWidget {
  final String haykirAdi;
  final String slogan;
  final String direme;
  final String kalanSure;
  final String profilResmi;
  final bool isExpanded;
  final VoidCallback? onTap;
  final VoidCallback? onSave;
  final VoidCallback? onHaykir;
  final double iconSize;

  const StreetActionHaykirCard({
    super.key,
    required this.haykirAdi,
    required this.slogan,
    required this.direme,
    required this.kalanSure,
    required this.profilResmi,
    required this.isExpanded,
    this.onTap,
    this.onSave,
    this.onHaykir,
    this.iconSize = 48.0,
  });

  @override
  State<StreetActionHaykirCard> createState() => _StreetActionHaykirCardState();
}

class _StreetActionHaykirCardState extends State<StreetActionHaykirCard> {
  late final TextEditingController _haykirAdiController;
  late final TextEditingController _sloganController;
  String? _selectedDiren;
  bool _hasUnsavedChanges = false;
  final bool _canHaykir = true; // Haykırma durumunu kontrol eder
  bool _showConfetti = false; // Konfeti animasyonunu göster/gizle
  bool _showLottieAnimation = false; // Lottie animasyonunu göster/gizle

  final List<String> _direnOpsiyonlari = [
    'Tava Tencere Lobisi',
    'MegaFon Lordları',
    'Sessiz Çığlık Koalisyonu',
    'Konfetili Dayanışma',
  ];

  final List<String> _fikirKiviltilari = [
    'Simit fiyatına uzay programı istiyoruz!',
    'Her mahalleye ücretsiz neşe kotası!',
    'Şemsiyelerimizi geri verin, yağmura sözümüz var!',
    'Kedi maması vergisi düşsün!',
  ];

  @override
  void initState() {
    super.initState();
    _haykirAdiController = TextEditingController(text: widget.haykirAdi);
    _sloganController = TextEditingController(text: widget.slogan);
    _selectedDiren = widget.direme.isNotEmpty ? widget.direme : null;
  }

  @override
  void didUpdateWidget(covariant StreetActionHaykirCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isExpanded && _hasUnsavedChanges) {
      // Kart kapandığında uyarıyı gizle.
      setState(() => _hasUnsavedChanges = false);
    }
  }

  @override
  void dispose() {
    _haykirAdiController.dispose();
    _sloganController.dispose();
    super.dispose();
  }

  void _markUnsaved() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _handleSave() {
    widget.onSave?.call();
    if (mounted) {
      setState(() => _hasUnsavedChanges = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Haykırış taslağı kaydedildi. MegaFon hazır!'),
        ),
      );
    }
  }

  void _handleHaykir() {
    widget.onHaykir?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sokak hoparlörleri açıldı, haykırış yayında!'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showDetails = widget.isExpanded;

    return Stack(
      children: [
        Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 350),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer,
                    theme.colorScheme.surface,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 20),
                  _buildPlayfulStats(theme),
                  if (_hasUnsavedChanges) ...[
                    const SizedBox(height: 16),
                    _buildUnsavedWarning(theme),
                  ],
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState: showDetails
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    firstChild: _buildCollapsedFooter(theme),
                    secondChild: _buildExpandedContent(theme),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_showLottieAnimation)
          Positioned.fill(
            child: LottieAnimationOverlay(
              onAnimationComplete: () {
                if (mounted) {
                  setState(() {
                    _showLottieAnimation = false;
                  });
                }
              },
              // Lottie JSON dosyası assets'e eklendiğinde buraya path verilebilir
              // lottieAssetPath: 'assets/animations/haykir_animation.json',
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor:
              theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.08),
          child: Image.asset(
            'lib/icons/03_haykir_ana_icon.png',
            width: widget.iconSize,
            height: widget.iconSize,
            color: _canHaykir ? null : Colors.grey.shade400,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Text(
                widget.haykirAdi,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),

            ],
          ),
        ),
        Icon(
          widget.isExpanded ? Icons.expand_less : Icons.expand_more,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  Widget _buildPlayfulStats(ThemeData theme) {
    final items = [
      (Icons.celebration, 'Konfeti', () {
        setState(() {
          _showConfetti = true;
        });
        // 3 saniye sonra konfeti animasyonunu gizle
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _showConfetti = false;
            });
          }
        });
      }),
      (Icons.front_hand, 'Direniş', null),
      (Icons.music_note, 'Ritim', null),
      (Icons.auto_awesome, 'Mizah', null),
    ];
    return Stack(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items
              .map(
                (item) => Column(
                  children: [
                    GestureDetector(
                      onTap: item.$3,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.$1, color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.$2,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
        if (_showConfetti)
          Positioned.fill(
            child: IgnorePointer(
              child: ConfettiAnimationWidget(
                onAnimationComplete: () {
                  if (mounted) {
                    setState(() {
                      _showConfetti = false;
                    });
                  }
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUnsavedWarning(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: theme.colorScheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'HAYKIR\'ı yeniden düzenlediniz, kaydetmeden çıkarsanız değişiklikler uygulanmayacak!',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onErrorContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsedFooter(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Haykırı açmak için dokun',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        Icon(Icons.touch_app, color: theme.colorScheme.primary),
      ],
    );
  }

  Widget _buildExpandedContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        _buildTextField(
          controller: _haykirAdiController,
          label:
              '"HAYKIR ADI"?',
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _sloganController,
          label: 'SLOGAN yaz?',
          maxLines: 2,
        ),
        const SizedBox(height: 20),
        Text(
          'Diren seç',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _direnOpsiyonlari
              .map(
                (option) => FilterChip(
                  label: Text(option),
                  avatar: const Icon(Icons.campaign, size: 18),
                  selected: _selectedDiren == option,
                  onSelected: (_) {
                    setState(() => _selectedDiren = option);
                    _markUnsaved();
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Text(
          'Fikir kıvılcımları',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _fikirKiviltilari
              .map(
                (idea) => ActionChip(
                  avatar: const Icon(Icons.flash_on, size: 18),
                  label: Text(idea),
                  onPressed: () {
                    _sloganController.text = idea;
                    _markUnsaved();
                  },
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _handleSave,
                icon: const Icon(Icons.save_alt),
                label: const Text('Kaydet'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: FilledButton.tonalIcon(
                onPressed: _handleHaykir,
                icon: const Icon(Icons.graphic_eq),
                label: const Text('Hemen Haykır'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => _markUnsaved(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
