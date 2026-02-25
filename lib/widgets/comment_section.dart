import 'package:flutter/material.dart';

import '../utils/comment_utils.dart';

typedef CommentSubmitCallback = Future<void> Function(
  String yorumMetni, {
  String? parentCommentId,
  bool isGizliTanik,
});

class CommentSection extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final CommentSubmitCallback? onSubmit;
  final String? currentUserName;
  final bool isReadOnly;
  final String? type; // 'haykir' veya null (dava)

  const CommentSection({
    super.key,
    required this.comments,
    this.onSubmit,
    this.currentUserName,
    this.isReadOnly = false,
    this.type,
  });

  @override
  CommentSectionState createState() => CommentSectionState();
}

class CommentSectionState extends State<CommentSection> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  bool _isSending = false;
  bool _isGizliTanik = false;

  @override
  void dispose() {
    _commentController.dispose();
    _composerFocusNode.dispose();
    super.dispose();
  }

  void focusInput() {
    if (widget.isReadOnly) return;
    _composerFocusNode.requestFocus();
  }

  Future<void> _handleSubmit({
    String? parentCommentId,
    bool isGizliTanik = false,
    String? presetText,
    VoidCallback? onSuccess,
  }) async {
    if (widget.onSubmit == null) return;

    final text = presetText ?? _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSending = parentCommentId == null);
    try {
      await widget.onSubmit!.call(
        text,
        parentCommentId: parentCommentId,
        isGizliTanik: isGizliTanik,
      );
      onSuccess?.call();
      if (parentCommentId == null) {
        _commentController.clear();
        setState(() => _isGizliTanik = false);
        _composerFocusNode.unfocus();
      }
    } finally {
      if (parentCommentId == null) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedComments = CommentUtils.normalizeComments(widget.comments);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[700]),
            const SizedBox(width: 8),
            Text(
              'Yorumlar (${CommentUtils.countAllComments(normalizedComments)})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (!widget.isReadOnly) ...[
          _buildComposer(),
          const SizedBox(height: 16),
        ],
        if (normalizedComments.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              'İlk yorumu yazan sen ol!',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
              ),
            ),
          )
          else
          Column(
            children: normalizedComments
                .map(
                  (comment) => CommentCard(
                    comment: comment,
                    depth: 0,
                    type: widget.type,
                    onReply: widget.onSubmit == null
                        ? null
                        : ({
                            required String text,
                            required bool isGizliTanik,
                          }) =>
                            _handleSubmit(
                              parentCommentId: comment['id']?.toString(),
                              isGizliTanik: isGizliTanik,
                              presetText: text,
                            ),
                  ),
                )
                .toList(),
          ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _commentController,
            focusNode: _composerFocusNode,
            decoration: const InputDecoration(
              hintText: 'Yorumunu yaz...',
              border: InputBorder.none,
            ),
            maxLines: null,
            minLines: 1,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Checkbox(
                value: _isGizliTanik,
                onChanged: (value) {
                  setState(() => _isGizliTanik = value ?? false);
                },
                activeColor: Colors.green,
              ),
              Text(
                widget.type == 'haykir'
                    ? 'Bir Dost olarak yorum yap'
                    : 'Gizli Tanık olarak yorum yap',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _isSending
                    ? null
                    : () => _handleSubmit(isGizliTanik: _isGizliTanik),
                icon: _isSending
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(_isSending ? 'Gönderiliyor...' : 'Gönder'),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class CommentCard extends StatefulWidget {
  final Map<String, dynamic> comment;
  final int depth;
  final String? type; // 'haykir' veya null (dava)
  final Future<void> Function({
    required String text,
    required bool isGizliTanik,
  })? onReply;

  const CommentCard({
    super.key,
    required this.comment,
    required this.depth,
    this.type,
    this.onReply,
  });

  @override
  State<CommentCard> createState() => _CommentCardState();
}

class _CommentCardState extends State<CommentCard> {
  bool _showReplyInput = false;
  final TextEditingController _replyController = TextEditingController();
  bool _replyAsGizliTanik = false;
  bool _isSendingReply = false;

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _handleReply() async {
    if (widget.onReply == null || _replyController.text.trim().isEmpty) return;
    setState(() => _isSendingReply = true);
    await widget.onReply!(
      text: _replyController.text.trim(),
      isGizliTanik: _replyAsGizliTanik,
    );
    if (!mounted) return;
    setState(() {
      _replyController.clear();
      _replyAsGizliTanik = false;
      _isSendingReply = false;
      _showReplyInput = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final replies = CommentUtils.normalizeComments(comment['replies']);
    final initials = comment['userName']
        .toString()
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return Container(
      margin: EdgeInsets.only(
        left: (widget.depth * 16).toDouble(),
        bottom: 12,
      ),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blueGrey[100],
                child: Text(
                  initials.isEmpty ? '?' : initials,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comment['userName']?.toString() ?? 'Bilinmeyen',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      comment['tarih']?.toString() ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              if (comment['isGizliTanik'] == true)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    widget.type == 'haykir' ? 'Bir Dost' : 'Gizli Tanık',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment['yorum']?.toString() ?? '',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              TextButton(
                onPressed: widget.onReply == null
                    ? null
                    : () {
                        setState(() => _showReplyInput = !_showReplyInput);
                      },
                child: Text(
                  _showReplyInput ? 'Vazgeç' : 'Yanıtla',
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          if (_showReplyInput) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    decoration: const InputDecoration(
                      hintText: 'Yanıt yaz...',
                      border: InputBorder.none,
                    ),
                    maxLines: null,
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: _replyAsGizliTanik,
                        onChanged: (value) {
                          setState(() => _replyAsGizliTanik = value ?? false);
                        },
                        activeColor: Colors.green,
                      ),
                      Expanded(
                        child: Text(
                          widget.type == 'haykir'
                              ? 'Bir Dost olarak yanıtla'
                              : 'Gizli Tanık olarak yanıtla',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isSendingReply ? null : _handleReply,
                        child: _isSendingReply
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Gönder'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (replies.isNotEmpty) ...[
            const SizedBox(height: 12),
            Column(
              children: replies
                  .map(
                    (reply) => CommentCard(
                      comment: reply,
                      depth: widget.depth + 1,
                      type: widget.type,
                      onReply: widget.onReply,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

