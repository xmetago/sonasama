import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import '../models/evidence_comment_model.dart';
import '../services/evidence_comment_service.dart';

/// Delil yorumları widget'ı
/// 8 farklı rol için yorum görüntüleme ve yazma
class EvidenceCommentWidget extends StatefulWidget {
  final String evidenceId;
  final String davaId;
  final String? userEmail;
  final String? currentUserRole; // Mevcut kullanıcının rolü

  const EvidenceCommentWidget({
    super.key,
    required this.evidenceId,
    required this.davaId,
    this.userEmail,
    this.currentUserRole,
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
                  'Rol Yorumları',
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
            
            // 8 Rol için yorum kartları
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildRoleCommentsGrid(),
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
                  // Yorum metni (kısaltılmış)
                  Text(
                    comment.commentText,
                    style: const TextStyle(fontSize: 14),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (comment.commentText.length > 100)
                    TextButton(
                      onPressed: () => _showCommentDialog(role, comment, true, canComment),
                      child: const Text('Devamını oku'),
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

    showDialog(
      context: context,
      builder: (context) => _CommentDialog(
        role: role,
        evidenceId: widget.evidenceId,
        davaId: widget.davaId,
        userEmail: widget.userEmail ?? '',
        userRole: role.value,
        existingComment: existingComment,
        hasComment: hasComment,
        canComment: canComment,
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
  final EvidenceCommentModel? existingComment;
  final bool hasComment;
  final bool canComment;
  final VoidCallback onCommentSaved;

  const _CommentDialog({
    required this.role,
    required this.evidenceId,
    required this.davaId,
    required this.userEmail,
    required this.userRole,
    this.existingComment,
    required this.hasComment,
    required this.canComment,
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
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Başlık
            Row(
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
            const SizedBox(height: 20),
            
            // Eleştiri seçimi
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
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCriticismOption(
                    'neutral',
                    'Nötr',
                    Icons.remove,
                    Colors.grey,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCriticismOption(
                    'negative',
                    'Olumsuz',
                    Icons.thumb_down,
                    Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Yorum metni
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
            const SizedBox(height: 20),
            
            // Butonlar
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isSaving ? null : () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                const SizedBox(width: 8),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Eleştiri seçenekleri
  Widget _buildCriticismOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedCriticism == value;
    return InkWell(
      onTap: () => setState(() => _selectedCriticism = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.2)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey, size: 20),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
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
      );

      if (result['success'] == true) {
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

