import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'expandable_comment_text.dart';
import '../models/evidence_comment_model.dart';
import '../models/evidence_model.dart';
import '../services/evidence_comment_service.dart';
import '../services/evidence_service.dart';

String _criticismFromEvidenceVote(String? vote) {
  switch (vote) {
    case 'like':
      return 'positive';
    case 'dislike':
      return 'negative';
    case 'neutral':
      return 'neutral';
    default:
      return 'neutral';
  }
}

String _evidenceVoteFromCriticism(String criticism) {
  switch (criticism) {
    case 'positive':
      return 'like';
    case 'negative':
      return 'dislike';
    default:
      return 'neutral';
  }
}

/// Delil yorumları widget'ı
/// 8 farklı rol için yorum görüntüleme ve yazma
class EvidenceCommentWidget extends StatefulWidget {
  final String evidenceId;
  final String davaId;
  final String? userEmail;
  final String? currentUserRole; // Mevcut kullanıcının rolü
  final bool isEvidenceValid; // Delil geçerliyse true
  /// Oy çubuğu ve senkron için güncel delil (liste/detay ile aynı kaynak)
  final EvidenceModel? evidenceSnapshot;
  final VoidCallback? onEvidenceVoteChanged;
  final bool isVoteLockedByFinalizedHukum;
  final bool forcedValidVote;

  const EvidenceCommentWidget({
    super.key,
    required this.evidenceId,
    required this.davaId,
    this.userEmail,
    this.currentUserRole,
    this.isEvidenceValid = true,
    this.evidenceSnapshot,
    this.onEvidenceVoteChanged,
    this.isVoteLockedByFinalizedHukum = false,
    this.forcedValidVote = false,
  });

  @override
  State<EvidenceCommentWidget> createState() => _EvidenceCommentWidgetState();
}

class _EvidenceCommentWidgetState extends State<EvidenceCommentWidget> {
  final EvidenceCommentService _commentService = EvidenceCommentService();
  List<EvidenceCommentModel> _comments = [];
  Map<String, int> _commentCounts = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  /// Yorumları yükle
  Future<void> _loadComments() async {
    try {
      await _commentService.initialize();
      final comments = _commentService.getCommentsByEvidenceId(widget.evidenceId);
      final counts = _commentService.getCommentCountsByRole(widget.evidenceId);
      
      setState(() {
        _comments = comments;
        _commentCounts = counts;
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Yorumlar yüklenirken hata: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(top: 24),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
              children: [
                Icon(
                  MdiIcons.commentMultiple,
                  color: Colors.blue[700],
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Delili Değerlendirdim : ',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (_isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            if (widget.evidenceSnapshot != null &&
                widget.userEmail != null &&
                widget.userEmail!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: _buildEvidenceAssessmentBar(),
              ),
            
            // 8 Rol için yorum kartları
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRoleCommentsGrid(),
          ],
        ),
      ),
    );
  }

  Future<void> _onAssessmentVoteTap(Future<void> Function() action) async {
    if (widget.isVoteLockedByFinalizedHukum) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.forcedValidVote
                ? 'Hükmünüz kesinleşti: deliller geçerli kabul edildi.'
                : 'Hükmünüz kesinleşti: deliller geçersiz kabul edildi.',
          ),
          backgroundColor: Colors.blueGrey,
        ),
      );
      return;
    }
    await action();
    widget.onEvidenceVoteChanged?.call();
  }

  Widget _buildEvidenceAssessmentBar() {
    final e = widget.evidenceSnapshot!;
    final email = widget.userEmail!.trim();
    final vote = e.getUserVote(email);
    final isLiked = vote == 'like';
    final isNeutral = vote == 'neutral';
    final isDisliked = vote == 'dislike';
    final svc = EvidenceService();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              Expanded(
                child: _buildVoteSegment(
                  icon: Icons.thumb_up_rounded,
                  label: 'Geçerli',
                  count: e.likeCount,
                  color: Colors.blue,
                  active: isLiked,
                  disabled: widget.isVoteLockedByFinalizedHukum,
                  onTap: () => _onAssessmentVoteTap(() async {
                    await svc.initialize();
                    await svc.toggleLike(e.id, email);
                  }),
                ),
              ),
              Container(width: 10, height: 22, color: Colors.grey[300]),
              Expanded(
                child: _buildVoteSegment(
                  icon: Icons.remove,
                  label: 'Nötr',
                  count: e.neutralCount,
                  color: Colors.grey,
                  active: isNeutral,
                  disabled: widget.isVoteLockedByFinalizedHukum,
                  onTap: () => _onAssessmentVoteTap(() async {
                    await svc.initialize();
                    await svc.toggleNeutral(e.id, email);
                  }),
                ),
              ),
              Container(width: 10, height: 22, color: Colors.grey[300]),
              Expanded(
                child: _buildVoteSegment(
                  icon: Icons.thumb_down_rounded,
                  label: 'Geçersiz',
                  count: e.dislikeCount,
                  color: Colors.red,
                  active: isDisliked,
                  disabled: widget.isVoteLockedByFinalizedHukum,
                  onTap: () => _onAssessmentVoteTap(() async {
                    await svc.initialize();
                    await svc.toggleDislike(e.id, email);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVoteSegment({
    required IconData icon,
    required String label,
    required int count,
    required Color color,
    required bool active,
    required bool disabled,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: disabled
              ? Colors.grey[200]
              : active
                  ? color.withValues(alpha: 0.15)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: disabled
                ? Colors.grey[400]!
                : active
                    ? color
                    : color.withValues(alpha: 0.25),
            width: active ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: disabled
                  ? Colors.grey[500]
                  : active
                      ? color
                      : color.withValues(alpha: 0.65),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                      color: disabled
                          ? Colors.grey[600]
                          : active
                              ? color
                              : Colors.grey[700],
                    ),
                  ),
                  Text(
                    '$count',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: disabled ? Colors.grey[600] : color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Rol yorumları grid'i
  Widget _buildRoleCommentsGrid() {
    return Column(
      children: EvidenceCommentRole.allRoles.map((role) {
        final comment = _comments.firstWhere(
          (c) => c.userRole == role.value,
          orElse: () => EvidenceCommentModel(
            id: '',
            evidenceId: widget.evidenceId,
            davaId: widget.davaId,
            userRole: role.value,
            userEmail: '',
            commentText: '',
            createdAt: DateTime.now(),
          ),
        );
        
        final hasComment = comment.id.isNotEmpty;
        final canComment = widget.userEmail != null && 
                          widget.currentUserRole == role.value;
        
        return _buildRoleCommentCard(role, comment, hasComment, canComment);
      }).toList(),
    );
  }

  /// Tek bir rol yorum kartı
  Widget _buildRoleCommentCard(
    EvidenceCommentRole role,
    EvidenceCommentModel comment,
    bool hasComment,
    bool canComment,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: hasComment 
            ? role.color.withValues(alpha: 0.1)
            : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasComment 
              ? role.color.withValues(alpha: 0.3)
              : Colors.grey[300]!,
          width: hasComment ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Rol başlığı
          InkWell(
            onTap: hasComment || canComment
                ? () => _showCommentDialog(role, comment, hasComment, canComment)
                : null,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: [
                  // Rol ikonu
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: role.color.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      role.icon,
                      color: role.color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Rol adı
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: role.color,
                          ),
                        ),
                        if (hasComment)
                          Text(
                            'Yorum yazıldı',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          )
                        else if (canComment)
                          Text(
                            'Yorum yazabilirsiniz',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                            ),
                          )
                        else
                          Text(
                            'Henüz yorum yok',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // Yorum durumu ikonu
                  if (hasComment)
                    Icon(
                      Icons.comment,
                      color: role.color,
                      size: 20,
                    )
                  else if (canComment)
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.green[700],
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.comment_outlined,
                      color: Colors.grey[400],
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          
          // Yorum varsa önizleme
          if (hasComment)
            Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                border: Border(
                  top: BorderSide(
                    color: role.color.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Eleştiri durumu
                  Row(
                    children: [
                      _buildCriticismBadge(comment.criticism),
                      const Spacer(),
                      Text(
                        _formatDate(comment.createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ExpandableCommentText(
                    text: comment.commentText,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Eleştiri rozeti
  Widget _buildCriticismBadge(String criticism) {
    Color color;
    String label;
    IconData icon;
    
    switch (criticism) {
      case 'positive':
        color = Colors.green;
        label = 'Olumlu';
        icon = Icons.thumb_up;
        break;
      case 'negative':
        color = Colors.red;
        label = 'Olumsuz';
        icon = Icons.thumb_down;
        break;
      default:
        color = Colors.grey;
        label = 'Nötr';
        icon = Icons.remove;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Yorum dialog'u göster
  void _showCommentDialog(
    EvidenceCommentRole role,
    EvidenceCommentModel? existingComment,
    bool hasComment,
    bool canComment,
  ) {
    if (!canComment && !hasComment) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bu delil için ${role.label} rolünde yorum yazamazsınız'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final userVote = widget.evidenceSnapshot?.getUserVote(widget.userEmail ?? '');

    showDialog(
      context: context,
      barrierDismissible: true,
      useSafeArea: true,
      builder: (context) => _CommentDialog(
        role: role,
        evidenceId: widget.evidenceId,
        davaId: widget.davaId,
        userEmail: widget.userEmail ?? '',
        userRole: role.value,
        isEvidenceValid: widget.isEvidenceValid,
        existingComment: hasComment ? existingComment : null,
        hasComment: hasComment,
        canComment: canComment,
        userEvidenceVote: userVote,
        onEvidenceVoteChanged: widget.onEvidenceVoteChanged,
        onCommentSaved: () {
          _loadComments();
          Navigator.pop(context);
        },
      ),
    );
  }

  /// Tarih formatlama
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Bugün ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Dün';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} gün önce';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}

/// Yorum yazma dialog'u
class _CommentDialog extends StatefulWidget {
  final EvidenceCommentRole role;
  final String evidenceId;
  final String davaId;
  final String userEmail;
  final String userRole;
  final bool isEvidenceValid;
  final EvidenceCommentModel? existingComment;
  final bool hasComment;
  final bool canComment;
  final String? userEvidenceVote;
  final VoidCallback? onEvidenceVoteChanged;
  final VoidCallback onCommentSaved;

  const _CommentDialog({
    required this.role,
    required this.evidenceId,
    required this.davaId,
    required this.userEmail,
    required this.userRole,
    required this.isEvidenceValid,
    this.existingComment,
    required this.hasComment,
    required this.canComment,
    this.userEvidenceVote,
    this.onEvidenceVoteChanged,
    required this.onCommentSaved,
  });

  @override
  State<_CommentDialog> createState() => _CommentDialogState();
}

class _CommentDialogState extends State<_CommentDialog> {
  final TextEditingController _commentController = TextEditingController();
  final EvidenceCommentService _commentService = EvidenceCommentService();
  String _selectedCriticism = 'neutral';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingComment != null) {
      _commentController.text = widget.existingComment!.commentText;
      _selectedCriticism = widget.existingComment!.criticism;
    } else if (widget.userEvidenceVote != null &&
        widget.userEvidenceVote!.isNotEmpty) {
      _selectedCriticism = _criticismFromEvidenceVote(widget.userEvidenceVote);
    }
    if (!widget.isEvidenceValid && _selectedCriticism == 'positive') {
      _selectedCriticism = 'neutral';
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 12, 0),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.role.color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              widget.role.icon,
              color: widget.role.color,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${widget.role.label} Yorumu',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Eleştiri Türü:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildCriticismOption(
                      'positive',
                      'Olumlu',
                      Icons.thumb_up,
                      Colors.green,
                      widget.isEvidenceValid,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCriticismOption(
                      'neutral',
                      'Nötr',
                      Icons.remove,
                      Colors.grey,
                      true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildCriticismOption(
                      'negative',
                      'Olumsuz',
                      Icons.thumb_down,
                      Colors.red,
                      true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Yorumunuz:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _commentController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Delil hakkındaki yorumunuzu yazın...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveComment,
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.role.color,
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(widget.hasComment ? 'Güncelle' : 'Kaydet'),
        ),
      ],
    );
  }

  /// Eleştiri seçenekleri
  Widget _buildCriticismOption(
    String value,
    String label,
    IconData icon,
    Color color,
    bool enabled,
  ) {
    final isSelected = _selectedCriticism == value;
    return InkWell(
      onTap: !enabled
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Geçersiz delilde olumlu yorum seçilemez'),
                  backgroundColor: Colors.orange,
                ),
              );
            }
          : () => setState(() => _selectedCriticism = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: !enabled
              ? Colors.grey[200]
              : isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: !enabled
                ? Colors.grey[400]!
                : isSelected
                    ? color
                    : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: !enabled
                  ? Colors.grey[500]
                  : isSelected
                      ? color
                      : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              enabled ? label : '$label (pasif)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected && enabled ? FontWeight.bold : FontWeight.normal,
                color: !enabled
                    ? Colors.grey[600]
                    : isSelected
                        ? color
                        : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Yorumu kaydet
  Future<void> _saveComment() async {
    if (_commentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen yorum metni girin'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_commentController.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Yorum en az 10 karakter olmalıdır'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final result = await _commentService.addOrUpdateComment(
        evidenceId: widget.evidenceId,
        davaId: widget.davaId,
        userRole: widget.userRole,
        userEmail: widget.userEmail,
        commentText: _commentController.text.trim(),
        criticism: _selectedCriticism,
        isEvidenceValid: widget.isEvidenceValid,
      );

      if (result['success'] == true) {
        try {
          final evSvc = EvidenceService();
          await evSvc.initialize();
          await evSvc.setUserVote(
            widget.evidenceId,
            widget.userEmail,
            _evidenceVoteFromCriticism(_selectedCriticism),
          );
          widget.onEvidenceVoteChanged?.call();
        } catch (_) {}
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Yorum kaydedildi'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onCommentSaved();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Yorum kaydedilemedi'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }
}

