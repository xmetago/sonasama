import 'package:flutter/material.dart';

/// Yardımcı yorum araçları.
class CommentUtils {
  /// Gelen listeyi güvenli biçimde `List<Map<String, dynamic>>`'e dönüştürür.
  static List<Map<String, dynamic>> normalizeComments(dynamic rawComments) {
    if (rawComments == null) return <Map<String, dynamic>>[];
    if (rawComments is List<Map<String, dynamic>>) {
      return rawComments.map(_normalizeCommentMap).toList();
    }
    if (rawComments is List) {
      return rawComments
          .whereType<Map>()
          .map((element) =>
              _normalizeCommentMap(Map<String, dynamic>.from(element)))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  /// Yorum sayısını (yanıtlar dahil) hesaplar.
  static int countAllComments(List<Map<String, dynamic>> comments) {
    var total = 0;
    for (final comment in comments) {
      total += 1;
      final replies = normalizeComments(comment['replies']);
      total += countAllComments(replies);
    }
    return total;
  }

  /// Yeni yorumu listeye ekler. `parentId` varsa ilgili yoruma yanıt olarak eklenir.
  /// Bulunamazsa en üste ekler.
  static List<Map<String, dynamic>> addComment(
    List<Map<String, dynamic>> comments,
    Map<String, dynamic> newComment,
  ) {
    final target = List<Map<String, dynamic>>.from(
      comments.map(_normalizeCommentMap),
    );

    final parentId = newComment['parentId']?.toString();
    if (parentId == null || parentId.isEmpty) {
      target.add(_normalizeCommentMap(newComment));
      return target;
    }

    final added = _addCommentToReplies(target, _normalizeCommentMap(newComment));
    if (!added) {
      // Parent bulunamazsa üst seviyeye ekle
      target.add(_normalizeCommentMap(newComment));
    }
    return target;
  }

  static bool _addCommentToReplies(
    List<Map<String, dynamic>> comments,
    Map<String, dynamic> newComment,
  ) {
    final parentId = newComment['parentId']?.toString();
    for (var i = 0; i < comments.length; i++) {
      final comment = _normalizeCommentMap(comments[i]);
      if (comment['id']?.toString() == parentId) {
        final replies = normalizeComments(comment['replies']);
        replies.add(newComment);
        comment['replies'] = replies;
        comments[i] = comment;
        return true;
      }

      final replies = normalizeComments(comment['replies']);
      final added = _addCommentToReplies(replies, newComment);
      if (added) {
        comment['replies'] = replies;
        comments[i] = comment;
        return true;
      }
    }
    return false;
  }

  static Map<String, dynamic> _normalizeCommentMap(
    Map<String, dynamic> comment,
  ) {
    final normalized = Map<String, dynamic>.from(comment);
    normalized['id'] ??= UniqueKey().hashCode.toString();
    normalized['userName'] ??= 'Bilinmeyen';
    normalized['yorum'] ??= '';
    normalized['tarih'] ??= DateTime.now().toIso8601String();
    normalized['begeniSayisi'] ??= 0;
    normalized['isGizliTanik'] ??= false;
    normalized['replies'] = normalizeComments(normalized['replies']);
    return normalized;
  }
}

