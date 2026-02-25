import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../screens/delil_listesi_ekrani.dart';
import 'comment_section.dart';
import '../utils/comment_utils.dart';

/// ✨ Ultra Modern Dava Davet Kartı Widget'ı
/// 
/// Özellikler:
/// - 🎨 Renkli gradient tasarım
/// - 👥 Davacı ve Davalı bilgileri belirgin
/// - 💬 Sosyal medya benzeri etkileşim butonları
/// - 🎯 Glassmorphism efektleri
/// - 📱 Responsive ve animasyonlu
class ModernInvitationCard extends StatefulWidget {
  final String userEmail;
  final String displayName;
  final String davaAdi;
  final String davaKategori;
  final String davaKonusu;
  final String? davaci;
  final String? davali;
  final String? davaId;
  final bool isOpened;
  final int yorumSayisi;
  final int retweetSayisi;
  final int begeniSayisi;
  final int begenmemeSayisi;
  final bool userLiked;
  final bool userDisliked;
  final bool? userRetweeted;
  final List<Map<String, dynamic>> yorumlar;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onDelilEkle;
  final CommentSubmitCallback? onYorum;
  final VoidCallback? onRetweet;
  final VoidCallback? onBegeni;
  final VoidCallback? onBegenmeme;
  // ✅ HAYKIR desteği için yeni alanlar
  final String? type; // 'haykir' veya null (dava)
  final String? slogan; // HAYKIR sloganı
  final String? direme; // HAYKIR direme
  final String? detaylar; // HAYKIR detayları
  final String? haykirId; // HAYKIR ID'si

  const ModernInvitationCard({
    super.key,
    required this.userEmail,
    required this.displayName,
    required this.davaAdi,
    required this.davaKategori,
    required this.davaKonusu,
    this.davaci,
    this.davali,
    this.davaId,
    required this.isOpened,
    required this.yorumSayisi,
    required this.retweetSayisi,
    required this.begeniSayisi,
    required this.begenmemeSayisi,
    required this.userLiked,
    required this.userDisliked,
    this.userRetweeted,
    required this.yorumlar,
    required this.onSave,
    required this.onOpen,
    required this.onDelilEkle,
    this.onYorum,
    this.onRetweet,
    this.onBegeni,
    this.onBegenmeme,
    // ✅ HAYKIR desteği için yeni parametreler
    this.type,
    this.slogan,
    this.direme,
    this.detaylar,
    this.haykirId,
  });

  @override
  State<ModernInvitationCard> createState() => _ModernInvitationCardState();
}

class _ModernInvitationCardState extends State<ModernInvitationCard> 
    with SingleTickerProviderStateMixin {
  bool isExpanded = false;
  bool isSaved = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool isRetweeted = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  final GlobalKey<CommentSectionState> _commentSectionKey =
      GlobalKey<CommentSectionState>();

  @override
  void initState() {
    super.initState();
    isLiked = widget.userLiked;
    isDisliked = widget.userDisliked;
    isRetweeted = widget.userRetweeted ?? false;
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
  }

  void _focusComments() {
    setState(() => isExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentSectionKey.currentState?.focusInput();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 🎨 Header Section
              _buildGradientHeader(),
              
              // 📋 Content Section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👥 Davacı - Davalı Bilgileri (sadece dava için)
                    if (widget.type != 'haykir') ...[
                      _buildParticipantsInfo(),
                      const SizedBox(height: 12),
                    ],
                    
                    // 📌 Dava Başlığı
                    _buildTitleSection(),
                    
                    // 📝 Expandable Content
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      _buildExpandedContent(),
                    ],
                    
                    const SizedBox(height: 12),
                    
                    // 💬 Engagement Buttons
                    _buildEngagementBar(),
                    
                    // 🎬 Action Buttons (sadece expanded'da)
                    if (isExpanded) ...[
                      const SizedBox(height: 12),
                      _buildActionButtons(),
                      const SizedBox(height: 12),
                      CommentSection(
                        key: _commentSectionKey,
                        comments: widget.yorumlar,
                        onSubmit: widget.onYorum == null
                            ? null
                            : (text,
                                    {parentCommentId, bool isGizliTanik = false}) =>
                                widget.onYorum!(
                                  text,
                                  parentCommentId: parentCommentId,
                                  isGizliTanik: isGizliTanik,
                                ),
                        currentUserName: widget.displayName,
                        type: widget.type,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎨 Gradient Header
  Widget _buildGradientHeader() {
    final isHaykir = widget.type == 'haykir';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isHaykir
              ? [Colors.orange[400]!, Colors.deepOrange[600]!]
              : [Colors.blue[400]!, Colors.purple[600]!],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Text(
                  widget.davaci?.isNotEmpty == true
                      ? widget.davaci!
                      : widget.displayName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Kategori Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isHaykir ? Icons.campaign : Icons.gavel,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.davaKategori,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Expand Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => setState(() => isExpanded = !isExpanded),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 👥 Davacı ve Davalı Bilgileri
  Widget _buildParticipantsInfo() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Davacı
          Expanded(
            child: _buildPersonBadge(
              label: 'Davacı',
              name: widget.davaci?.isNotEmpty == true 
                  ? widget.davaci! 
                  : widget.displayName,
              icon: Icons.person,
              color: Colors.green[600]!,
            ),
          ),
          
          // VS Icon
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: Icon(
              MdiIcons.swordCross,
              size: 18,
              color: Colors.grey[700],
            ),
          ),
          
          // Davalı
          Expanded(
            child: _buildPersonBadge(
              label: 'Davalı',
              name: widget.davali ?? 'Belirtilmemiş',
              icon: Icons.person_outline,
              color: Colors.red[600]!,
            ),
          ),
        ],
      ),
    );
  }

  /// 👤 Person Badge
  Widget _buildPersonBadge({
    required String label,
    required String name,
    required IconData icon,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  /// 📌 Başlık Bölümü
  Widget _buildTitleSection() {
    return Text(
      widget.davaAdi,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
        height: 1.4,
      ),
    );
  }

  /// 📝 Expanded Content (HAYKIR veya Dava için)
  Widget _buildExpandedContent() {
    final isHaykir = widget.type == 'haykir';
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHaykir ? Colors.orange[50] : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHaykir ? Colors.orange[200]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isHaykir) ...[
            // Slogan
            if (widget.slogan != null && widget.slogan!.isNotEmpty) ...[
              _buildContentSection(
                icon: Icons.format_quote,
                title: 'Slogan',
                content: widget.slogan!,
                isHighlighted: true,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
            ],
            // Direme
            if (widget.direme != null && widget.direme!.isNotEmpty) ...[
              _buildContentSection(
                icon: Icons.gavel,
                title: 'Direnme',
                content: widget.direme!,
                color: Colors.orange,
              ),
              const SizedBox(height: 12),
            ],
            // Detaylar
            if (widget.detaylar != null && widget.detaylar!.isNotEmpty) ...[
              _buildContentSection(
                icon: Icons.description,
                title: 'Detaylar',
                content: widget.detaylar!,
                color: Colors.orange,
              ),
            ],
            // Fallback: davaKonusu
            if ((widget.slogan == null || widget.slogan!.isEmpty) &&
                (widget.direme == null || widget.direme!.isEmpty) &&
                (widget.detaylar == null || widget.detaylar!.isEmpty))
              _buildContentSection(
                icon: Icons.article,
                title: 'HAYKIR İçeriği',
                content: widget.davaKonusu,
                color: Colors.orange,
              ),
          ] else ...[
            _buildContentSection(
              icon: Icons.article,
              title: 'Dava Konusu',
              content: widget.davaKonusu,
              color: Colors.blue,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection({
    required IconData icon,
    required String title,
    required String content,
    required Color color,
    bool isHighlighted = false,
  }) {
    Color getColorShade(int shade) {
      if (color == Colors.orange) {
        return Colors.orange[shade]!;
      } else if (color == Colors.blue) {
        return Colors.blue[shade]!;
      }
      return color;
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: getColorShade(700)),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: getColorShade(700),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (isHighlighted)
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: getColorShade(300)),
            ),
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: getColorShade(900),
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          )
        else
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
      ],
    );
  }

  /// 💬 Engagement Bar
  Widget _buildEngagementBar() {
    final totalComments = widget.yorumlar.isNotEmpty
        ? CommentUtils.countAllComments(widget.yorumlar)
        : widget.yorumSayisi;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildEngagementButton(
            icon: Icons.comment_rounded,
            count: totalComments,
            color: Colors.blue,
            onTap: _focusComments,
          ),
          _buildEngagementButton(
            icon: Icons.repeat_rounded,
            count: widget.retweetSayisi,
            color: Colors.green,
            onTap: () {
              setState(() => isRetweeted = !isRetweeted);
              widget.onRetweet?.call();
            },
            isActive: isRetweeted,
          ),
          _buildEngagementButton(
            icon: Icons.thumb_up_rounded,
            count: widget.begeniSayisi,
            color: Colors.orange,
            onTap: () {
              setState(() {
                isLiked = !isLiked;
                if (isLiked && isDisliked) isDisliked = false;
              });
              widget.onBegeni?.call();
            },
            isActive: isLiked,
          ),
          _buildEngagementButton(
            icon: Icons.thumb_down_rounded,
            count: widget.begenmemeSayisi,
            color: Colors.red,
            onTap: () {
              setState(() {
                isDisliked = !isDisliked;
                if (isDisliked && isLiked) isLiked = false;
              });
              widget.onBegenmeme?.call();
            },
            isActive: isDisliked,
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required int count,
    required Color color,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 18,
                color: isActive ? color : color.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  color: isActive ? color : color.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 🎬 Action Buttons
  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                label: isSaved ? 'Arşivlendi' : 'Arşivle',
                icon: isSaved ? Icons.check_circle : Icons.bookmark_add,
                color: isSaved ? Colors.green : Colors.grey,
                onTap: () {
                  setState(() => isSaved = !isSaved);
                  widget.onSave();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildActionButton(
                label: 'İzle',
                icon: Icons.gavel,
                color: Colors.blue,
                onTap: widget.onOpen,
              ),
            ),
          ],
        ),
        if (widget.type != 'haykir') ...[
          const SizedBox(height: 8),
          _buildActionButton(
            label: 'Delil Listesine Gözat',
            icon: Icons.folder_open,
            color: Colors.purple,
            onTap: () {
              if (widget.davaId == null || widget.davaId!.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Dava ID bulunamadı')),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DelilListesiEkrani(
                    davaId: widget.davaId!,
                    userEmail: widget.userEmail,
                  ),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}

