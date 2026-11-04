import 'package:flutter/material.dart';

import '../screens/delil_listesi_ekrani.dart';
import '../services/hive_database_service.dart';
import 'comment_section.dart';
import 'shared/app_snack.dart';

class ModernDavaCard extends StatefulWidget {
  final String userEmail;
  final String displayName;
  final String davaAdi;
  final String davaKategori;
  final String davaKonusu;
  final String? davaci; // Davacı alanı eklendi
  final String? davali;
  final String? davaId;
  final bool isOpened;
  final int yorumSayisi;
  final int retweetSayisi;
  final int begeniSayisi;
  final int begenmemeSayisi;
  final bool userLiked;
  final bool userDisliked;
  final bool? userRetweeted; // Retweet state eklendi
  final List<Map<String, dynamic>> yorumlar;
  final VoidCallback onSave;
  final VoidCallback onOpen;
  final VoidCallback onDelilEkle;
  final CommentSubmitCallback? onYorum;
  final VoidCallback? onRetweet;
  final VoidCallback? onBegeni;
  final VoidCallback? onBegenmeme;

  const ModernDavaCard({
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
  });

  @override
  State<ModernDavaCard> createState() => _ModernDavaCardState();
}

class _ModernDavaCardState extends State<ModernDavaCard> {
  bool isExpanded = false;
  bool isSaved = false;
  bool isLiked = false;
  bool isDisliked = false;
  bool isRetweeted = false;
  final GlobalKey<CommentSectionState> _commentSectionKey =
      GlobalKey<CommentSectionState>();

  @override
  void initState() {
    super.initState();
    // Widget'tan gelen state'leri local state'e kopyala
    isLiked = widget.userLiked;
    isDisliked = widget.userDisliked;
    isRetweeted = widget.userRetweeted ?? false;
  }

  void _focusComments() {
    setState(() => isExpanded = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _commentSectionKey.currentState?.focusInput();
    });
  }

  Widget _buildInfoRow(String label, String value, {bool bold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$label: ",
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEngagementButton({
    required IconData icon,
    required String count,
    required Color color,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: isActive ? Border.all(color: color, width: 1) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive ? color : color.withOpacity(0.7),
            ),
            const SizedBox(width: 4),
            Text(
              count,
              style: TextStyle(
                fontSize: 13,
                color: isActive ? color : color.withOpacity(0.7),
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showCommentDialog() {
    final TextEditingController commentController = TextEditingController();
    bool isGizliTanik = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Builder(
                    builder: (context) {
                      // Kullanıcının profil resmi URL'sini Hive'dan al
                      final settings = HiveDatabaseService.getSettings(widget.userEmail);
                      final profileImageUrl = settings?.profileImageUrl;
                      
                      return CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                            : const AssetImage('lib/icons/07_profil_picture_davaci.png') as ImageProvider<Object>,
                        onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? (exception, stackTrace) {
                                // Resim yüklenemezse varsayılan ikonu göster
                              }
                            : null,
                        child: profileImageUrl != null && profileImageUrl.isNotEmpty
                            ? null
                            : const Icon(Icons.account_circle, size: 32, color: Colors.grey),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yorum Yap',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Dava: ${widget.davaAdi}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey[100],
                      shape: const CircleBorder(),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: TextField(
                      controller: commentController,
                      maxLines: 4,
                      maxLength: 280,
                      onChanged: (value) {
                        setDialogState(() {});
                      },
                      decoration: const InputDecoration(
                        hintText: 'Davanız hakkında yorumunuzu yazın...',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(16),
                        counterText: '',
                      ),
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${commentController.text.length}/280',
                        style: TextStyle(
                          fontSize: 12,
                          color: commentController.text.length > 250
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            onPressed: () {
                              showAppSnack(context, '📷 Fotoğraf ekleme özelliği yakında!', duration: Duration(seconds: 2));
                            },
                            icon: Icon(Icons.photo_camera, color: Colors.green[600]),
                            tooltip: 'Fotoğraf Ekle',
                          ),
                        ],
                      ),
                    ],
                    ),
                    const SizedBox(height: 16),
                    // Gizli Tanık checkbox'ı
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Checkbox(
                            value: isGizliTanik,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                isGizliTanik = value ?? false;
                              });
                            },
                            activeColor: Colors.green,
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  isGizliTanik = !isGizliTanik;
                                });
                              },
                              child: const Text(
                                'Gizli Tanık olarak yorum yap',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isGizliTanik) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Yorumunuz "${HiveDatabaseService.gizliTanikDisplayName}" adıyla görünecektir.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text(
                    'İptal',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  onPressed: commentController.text.trim().isEmpty ? null : () async {
                    if (commentController.text.trim().isNotEmpty) {
                      final yorumMetni = commentController.text.trim();
                      
                      // Gizli tanık seçildiyse, yorumu HiveDatabaseService ile kaydet
                      if (widget.davaId != null && widget.userEmail.isNotEmpty && isGizliTanik) {
                        await HiveDatabaseService.addDavaComment(
                          widget.davaId!,
                          widget.userEmail,
                          yorumMetni: yorumMetni,
                          isGizliTanik: true,
                        );
                      }
                      
                      widget.onYorum?.call(yorumMetni);
                      Navigator.of(context).pop();
                      showAppSnack(context, '💬 Yorum eklendi: "$yorumMetni"${isGizliTanik ? ' (Gizli Tanık olarak)' : ''}', backgroundColor: Colors.green[600], duration: const Duration(seconds: 3));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('OK'),
                ),
              ],
              actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            );
          },
        );
      },
    );
  }

  Widget _buildActionButton({
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(text),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Builder(
                  builder: (context) {
                    // Kullanıcının profil resmi URL'sini Hive'dan al
                    final settings = HiveDatabaseService.getSettings(widget.userEmail);
                    final profileImageUrl = settings?.profileImageUrl;
                    
                    return CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? NetworkImage(profileImageUrl) as ImageProvider<Object>
                          : const AssetImage('lib/icons/07_profil_picture_davaci.png') as ImageProvider<Object>,
                      onBackgroundImageError: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? (exception, stackTrace) {
                              // Resim yüklenemezse varsayılan ikonu göster
                            }
                          : null,
                      child: profileImageUrl != null && profileImageUrl.isNotEmpty
                          ? null
                          : const Icon(Icons.account_circle, size: 40, color: Colors.grey),
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Davacı: ${widget.davaci?.isNotEmpty == true ? widget.davaci : widget.displayName}",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.grey[600],
                  ),
                  onPressed: () {
                    setState(() => isExpanded = !isExpanded);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Dava Bilgileri
            _buildInfoRow("Dava Adı", widget.davaAdi, bold: true),
            if (widget.davaKategori.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow("Kategori", widget.davaKategori),
            ],
            if (widget.davali != null && widget.davali!.isNotEmpty) ...[
              const SizedBox(height: 6),
              _buildInfoRow("Davalı", widget.davali!),
            ],

            if (isExpanded) ...[
              const SizedBox(height: 12),
              _buildInfoRow("Dava Konusu", widget.davaKonusu),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  _buildActionButton(
                    text: "Arşivle",
                    icon: isSaved ? Icons.check_circle : Icons.check_circle_outline,
                    onPressed: () {
                      setState(() {
                        isSaved = !isSaved;
                      });
                      widget.onSave();
                    },
                    color: isSaved ? Colors.green : Colors.grey[600]!,
                  ),
                  const SizedBox(width: 8),
                  _buildActionButton(
                    text: "İzle",
                    icon: Icons.open_in_new,
                    onPressed: widget.onOpen,
                    color: Colors.green[600]!,
                  ),


                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const SizedBox(width: 8),
                  _buildActionButton(
                    text: "Delil Listesine Gözat",
                    icon: Icons.account_tree_outlined,
                    onPressed: () {
                      final id = widget.davaId;
                      if (id == null || id.isEmpty) {
                        showAppSnack(context, 'Bu dava için davaId bulunamadı.');
                        return;
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DelilListesiEkrani(davaId: id),
                        ),
                      );
                    },
                    color: Colors.grey[600]!,
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Engagement buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildEngagementButton(
                  icon: Icons.comment_outlined,
                  count: widget.yorumSayisi.toString(),
                  color: Colors.blue,
                  onPressed: _focusComments,
                ),
                _buildEngagementButton(
                  icon: Icons.repeat,
                  count: widget.retweetSayisi.toString(),
                  color: Colors.green,
                  onPressed: () {
                    setState(() {
                      isRetweeted = !isRetweeted;
                    });
                    widget.onRetweet?.call();
                  },
                  isActive: isRetweeted || (widget.userRetweeted ?? false),
                ),
                _buildEngagementButton(
                  icon: Icons.thumb_up_outlined,
                  count: widget.begeniSayisi.toString(),
                  color: Colors.orange,
                  onPressed: () {
                    setState(() {
                      isLiked = !isLiked;
                      if (isLiked && isDisliked) {
                        isDisliked = false;
                      }
                    });
                    widget.onBegeni?.call();
                  },
                  isActive: isLiked,
                ),
                _buildEngagementButton(
                  icon: Icons.thumb_down_outlined,
                  count: widget.begenmemeSayisi.toString(),
                  color: Colors.red,
                  onPressed: () {
                    setState(() {
                      isDisliked = !isDisliked;
                      if (isDisliked && isLiked) {
                        isLiked = false;
                      }
                    });
                    widget.onBegenmeme?.call();
                  },
                  isActive: isDisliked,
                ),
              ],
            ),

            const SizedBox(height: 16),
            CommentSection(
              key: _commentSectionKey,
              comments: widget.yorumlar,
              onSubmit: widget.onYorum == null
                  ? null
                  : (text, {parentCommentId, bool isGizliTanik = false}) async {
                      await widget.onYorum!(
                        text,
                        parentCommentId: parentCommentId,
                        isGizliTanik: isGizliTanik,
                      );
                    },
              currentUserName: widget.displayName,
            ),
          ],
        ),
      ),
    );
  }
}

