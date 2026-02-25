import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:math' as math;

/// Animasyonlu Buton Widget'ı
/// 
/// Gradient, glow, scale ve pulse animasyonları ile sofistike buton
class AnimatedGradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final VoidCallback onPressed;
  final double? width;

  const AnimatedGradientButton({
    super.key,
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.onPressed,
    this.width,
  });

  @override
  State<AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _iconRotationAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _glowAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _iconRotationAnimation = Tween<double>(begin: 0.0, end: 0.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return AnimatedScale(
          scale: _isPressed ? 0.95 : _scaleAnimation.value,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: Container(
            width: widget.width,
            height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: widget.gradientColors,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: widget.gradientColors[0].withOpacity(_glowAnimation.value * 0.6),
                  blurRadius: 20 * _glowAnimation.value,
                  spreadRadius: 5 * _glowAnimation.value,
                ),
                BoxShadow(
                  color: widget.gradientColors.last.withOpacity(_glowAnimation.value * 0.4),
                  blurRadius: 15 * _glowAnimation.value,
                  spreadRadius: 3 * _glowAnimation.value,
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTapDown: (_) {
                  setState(() => _isPressed = true);
                },
                onTapUp: (_) {
                  setState(() => _isPressed = false);
                  widget.onPressed();
                },
                onTapCancel: () {
                  setState(() => _isPressed = false);
                },
                borderRadius: BorderRadius.circular(16),
                splashColor: Colors.white.withOpacity(0.3),
                highlightColor: Colors.white.withOpacity(0.1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Transform.rotate(
                        angle: _iconRotationAnimation.value * 2 * math.pi,
                        child: Transform.scale(
                          scale: 1.0 + (_glowAnimation.value * 0.1),
                          child: Icon(
                            widget.icon,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Flexible(
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Hüküm Verildi Dialog'u
/// 
/// Bu dialog, hüküm verildiğinde ceza ve masraf bilgilerini seçmek için kullanılır
class HukumCezaMasrafDialog extends StatefulWidget {
  final String davaAdi;
  final String rolAdi;

  const HukumCezaMasrafDialog({
    super.key,
    required this.davaAdi,
    required this.rolAdi,
  });

  @override
  State<HukumCezaMasrafDialog> createState() => _HukumCezaMasrafDialogState();

  /// Dialog'u gösterir ve seçilen ceza ve masraf bilgilerini döndürür
  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String davaAdi,
    required String rolAdi,
  }) async {
    return await showDialog<Map<String, String>>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return HukumCezaMasrafDialog(
          davaAdi: davaAdi,
          rolAdi: rolAdi,
        );
      },
    );
  }
}

class _HukumCezaMasrafDialogState extends State<HukumCezaMasrafDialog>
    with SingleTickerProviderStateMixin {
  AnimationController? _dialogAnimationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;
  Animation<double>? _scaleAnimation;
  bool _animationsInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    if (_animationsInitialized) return;
    
    _dialogAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogAnimationController!,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _dialogAnimationController!,
        curve: Curves.easeOutCubic,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(
        parent: _dialogAnimationController!,
        curve: Curves.easeOutBack,
      ),
    );

    _animationsInitialized = true;
    _dialogAnimationController!.forward();
  }

  @override
  void dispose() {
    _dialogAnimationController?.dispose();
    super.dispose();
  }

  void _handleCezaButton() {
    _dialogAnimationController?.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(<String, String>{
          'ceza': 'Ceza Veriniz',
          'masraf': 'Masraf Belirleyiniz',
        });
      }
    });
  }

  void _handleMasrafButton() {
    _dialogAnimationController?.reverse().then((_) {
      if (mounted) {
        Navigator.of(context).pop(<String, String>{
          'ceza': 'Ceza Veriniz',
          'masraf': 'Masraf Belirleyiniz',
        });
      }
    });
  }

  Widget _buildDialogContent() {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.green.shade50,
              Colors.blue.shade50,
              Colors.purple.shade50,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Başlık bölümü - Animasyonlu
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.green.shade700,
                    Colors.blueGrey.shade700,
                    Colors.purple.shade700,
                  ],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      MdiIcons.gavel,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Hüküm Verilmeden Önce Zorunludur',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          widget.rolAdi,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.95),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.close,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Butonlar bölümü - Animasyonlu butonlar
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Ceza butonu
                  AnimatedGradientButton(
                    label: 'Ceza Veriniz',
                    icon: MdiIcons.handcuffs,
                    gradientColors: [
                      Colors.orange.shade600,
                      Colors.red.shade600,
                      Colors.orange.shade800,
                    ],
                    onPressed: _handleCezaButton,
                  ),
                  const SizedBox(height: 16),
                  // Masraf butonu
                  AnimatedGradientButton(
                    label: 'Masraf Belirleyiniz',
                    icon: MdiIcons.cashMultiple,
                    gradientColors: [
                      Colors.blue.shade600,
                      Colors.indigo.shade600,
                      Colors.blue.shade800,
                    ],
                    onPressed: _handleMasrafButton,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Hot reload durumunda animasyonlar başlatılmamış olabilir
    if (!_animationsInitialized || 
        _fadeAnimation == null || 
        _slideAnimation == null || 
        _scaleAnimation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_animationsInitialized) {
          _initializeAnimations();
          setState(() {});
        }
      });
    }

    // Animasyonlar hala null ise, animasyon olmadan göster
    if (_fadeAnimation == null || _slideAnimation == null || _scaleAnimation == null) {
      return _buildDialogContent();
    }

    // Animasyonlu versiyon
    return FadeTransition(
      opacity: _fadeAnimation!,
      child: SlideTransition(
        position: _slideAnimation!,
        child: ScaleTransition(
          scale: _scaleAnimation!,
          child: _buildDialogContent(),
        ),
      ),
    );
  }
}

