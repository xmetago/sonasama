import 'package:flutter/material.dart';

/// Alt kategori tile widget'ı - Yeniden kullanılabilir ve test edilebilir
class SubCategoryTile extends StatefulWidget {
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;

  // Site genelindeki ana renk teması
  static const Color primaryColor = Color(0xFF059669); // Koyu yeşil
  static const Color primaryLightColor = Color(0xFF10B981); // Açık yeşil
  static const Color primaryLighterColor = Color(0xFFD1FAE5); // Çok açık yeşil
  static const Color primaryDarkColor = Color(0xFF047857); // Daha koyu yeşil

  const SubCategoryTile(
    this.title, {
    super.key,
    this.onTap,
    this.isSelected = false,
  });

  @override
  State<SubCategoryTile> createState() => _SubCategoryTileState();
}

class _SubCategoryTileState extends State<SubCategoryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.02,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: widget.onTap,
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                onTapCancel: _onTapCancel,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12.0),
                  padding: const EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 20.0,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isSelected
                          ? [
                              SubCategoryTile.primaryLightColor,
                              SubCategoryTile.primaryColor,
                            ]
                          : [
                              SubCategoryTile.primaryLighterColor,
                              SubCategoryTile.primaryLighterColor.withOpacity(0.7),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSelected
                          ? SubCategoryTile.primaryColor
                          : SubCategoryTile.primaryLightColor.withOpacity(0.5),
                      width: widget.isSelected ? 3 : 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.isSelected
                            ? SubCategoryTile.primaryColor.withOpacity(0.4)
                            : SubCategoryTile.primaryColor.withOpacity(0.1),
                        blurRadius: _isHovered ? 12 : 8,
                        offset: Offset(0, _isHovered ? 6 : 4),
                        spreadRadius: _isHovered ? 2 : 1,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Animasyonlu ikon
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _getIconForCategory(widget.title),
                          size: 20,
                          color: widget.isSelected ? Colors.white : SubCategoryTile.primaryColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: widget.isSelected ? FontWeight.w700 : FontWeight.w600,
                                color: widget.isSelected ? Colors.white : SubCategoryTile.primaryDarkColor,
                                letterSpacing: 0.5,
                              ),
                            ),
                            if (_isHovered) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Tıkla ve dava aç!',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isSelected 
                                      ? Colors.white.withOpacity(0.8)
                                      : SubCategoryTile.primaryColor.withOpacity(0.7),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Animasyonlu ok ikonu
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: widget.isSelected ? Colors.white : SubCategoryTile.primaryColor,
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

  IconData _getIconForCategory(String category) {
    // Kategoriye göre özel ikonlar
    if (category.contains('Sevgili') || category.contains('Eş')) {
      return Icons.favorite;
    } else if (category.contains('Aile')) {
      return Icons.family_restroom;
    } else if (category.contains('Arkadaş')) {
      return Icons.people;
    } else if (category.contains('Vefa')) {
      return Icons.heart_broken;
    } else if (category.contains('Zalim')) {
      return Icons.gavel;
    } else if (category.contains('Kadın')) {
      return Icons.woman;
    } else if (category.contains('Erkek')) {
      return Icons.man;
    } else if (category.contains('Kıskanç')) {
      return Icons.visibility;
    } else if (category.contains('Futbol')) {
      return Icons.sports_soccer;
    } else if (category.contains('Takım')) {
      return Icons.groups;
    } else if (category.contains('Hakem')) {
      return Icons.sports;
    } else if (category.contains('Politika')) {
      return Icons.policy;
    } else if (category.contains('Belediye')) {
      return Icons.location_city;
    } else if (category.contains('Banka')) {
      return Icons.account_balance;
    } else if (category.contains('Tanrı')) {
      return Icons.church;
    } else if (category.contains('Şeytan')) {
      return Icons.whatshot;
    } else if (category.contains('Patron')) {
      return Icons.work;
    } else if (category.contains('Öğretmen')) {
      return Icons.school;
    } else if (category.contains('Market')) {
      return Icons.shopping_cart;
    } else if (category.contains('Hayat')) {
      return Icons.favorite_border;
    } else if (category.contains('Ölüm')) {
      return Icons.celebration;
    } else if (category.contains('Kaygı')) {
      return Icons.psychology;
    } else if (category.contains('Teknoloji')) {
      return Icons.computer;
    } else if (category.contains('Sosyal')) {
      return Icons.share;
    } else if (category.contains('Dizi') || category.contains('Film')) {
      return Icons.movie;
    } else if (category.contains('Araba')) {
      return Icons.directions_car;
    } else if (category.contains('Sağlık')) {
      return Icons.local_hospital;
    } else if (category.contains('Hukuk')) {
      return Icons.balance;
    } else if (category.contains('Saçma')) {
      return Icons.sentiment_very_dissatisfied;
    } else if (category.contains('Belirsiz')) {
      return Icons.help_outline;
    } else {
      return Icons.category;
    }
  }
} 