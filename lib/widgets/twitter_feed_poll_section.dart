import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/dava_provider.dart';
import '../utils/map_safety.dart';
import 'twitter_poll_helpers.dart';

/// Seyir defteri anket alanı: oy sonrası UI güncellemesi, hover, çift tıklama koruması
class TwitterFeedPollSection extends StatefulWidget {
  final Map<String, dynamic> post;
  final Map<String, dynamic> pollData;
  final String postId;

  /// Giriş yapmış kullanıcı e-postası (oy anahtarı). Boşsa yazar e-postası kullanılır.
  final String? viewerEmail;
  final VoidCallback? onVoteSubmitted;

  const TwitterFeedPollSection({
    super.key,
    required this.post,
    required this.pollData,
    required this.postId,
    this.viewerEmail,
    this.onVoteSubmitted,
  });

  @override
  State<TwitterFeedPollSection> createState() => _TwitterFeedPollSectionState();
}

class _TwitterFeedPollSectionState extends State<TwitterFeedPollSection> {
  bool _submitting = false;
  String? _hoveredOption;
  Map<String, dynamic>? _pendingPoll;

  String get _voterKey {
    final v = (widget.viewerEmail ?? '').trim();
    if (v.isNotEmpty) return v;
    final payload = asStringDynamicMap(widget.post['payload']);
    return (payload['userEmail'] ?? '').toString().trim();
  }

  @override
  void didUpdateWidget(TwitterFeedPollSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.pollData, widget.pollData)) {
      _pendingPoll = null;
    }
  }

  Future<void> _submitVote(String option) async {
    final pollData = _pendingPoll ?? widget.pollData;
    final userVotes = asStringDynamicMap(pollData['userVotes']);
    final existing = userVotes[_voterKey]?.toString();
    final alreadyVoted = existing != null && existing.isNotEmpty;
    if (_submitting ||
        alreadyVoted ||
        widget.postId.isEmpty ||
        _voterKey.isEmpty) {
      return;
    }

    setState(() => _submitting = true);
    try {
      final davaProvider = Provider.of<DavaProvider>(context, listen: false);
      final updatedPoll = Map<String, dynamic>.from(pollData);
      final updatedVotes = asStringDynamicMap(updatedPoll['votes']);
      final updatedUserVotes = asStringDynamicMap(updatedPoll['userVotes']);
      final currentCount = pollAsInt(updatedVotes[option]);
      updatedVotes[option] = currentCount + 1;
      updatedUserVotes[_voterKey] = option;
      updatedPoll['votes'] = updatedVotes;
      updatedPoll['userVotes'] = updatedUserVotes;

      final updatedPost = Map<String, dynamic>.from(widget.post);
      final updatedPayload = asStringDynamicMap(updatedPost['payload']);
      updatedPayload['poll'] = updatedPoll;
      updatedPayload['hasPoll'] = true;
      updatedPost['payload'] = updatedPayload;

      await davaProvider.updateHomeFeedPost(widget.postId, updatedPost);
      if (!mounted) return;
      setState(() => _pendingPoll = updatedPoll);
      widget.onVoteSubmitted?.call();
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pollData = _pendingPoll ?? widget.pollData;
    final options = pollData['options'] as List<dynamic>? ?? [];
    final question = pollData['question']?.toString() ?? '';
    final votes = asStringDynamicMap(pollData['votes']);
    final userVotes = asStringDynamicMap(pollData['userVotes']);
    final userVote = userVotes[_voterKey]?.toString();
    final hasVoted = userVote != null && userVote.isNotEmpty;
    final totalVotes =
        votes.values.fold<int>(0, (sum, count) => sum + pollAsInt(count));
    final daysLeft = pollDaysLeftFromData(pollData);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFCFD9DE), width: 1),
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (question.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 2, right: 8),
                    child: pollTypeBadgeIcon(size: 22),
                  ),
                  Expanded(
                    child: Text(
                      question,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: pollTypeBadgeIcon(size: 22),
              ),
            ),
          Padding(
            padding: EdgeInsets.fromLTRB(8, question.isEmpty ? 8 : 0, 8, 8),
            child: Column(
              children: options.map<Widget>((dynamic raw) {
                final option = raw as String;
                final voteCount = pollAsInt(votes[option]);
                final percentage =
                    totalVotes > 0 ? (voteCount / totalVotes * 100) : 0.0;
                final isUserChoice = userVote == option;

                if (!hasVoted) {
                  final hovered = _hoveredOption == option;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: MouseRegion(
                      // InkWell kaldırıldı: Material hover katmanı kutu rengini bastırıyordu.
                      cursor: SystemMouseCursors.click,
                      opaque: true,
                      onEnter: (_) {
                        if (_submitting) return;
                        setState(() => _hoveredOption = option);
                      },
                      onExit: (_) {
                        if (_hoveredOption == option) {
                          setState(() => _hoveredOption = null);
                        }
                      },
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _submitting ? null : () => _submitVote(option),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          curve: Curves.easeOut,
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: hovered
                                  ? kTwitterPollBlue.withValues(alpha: 0.95)
                                  : kTwitterPollBlue.withValues(alpha: 0.65),
                              width: hovered ? 1.5 : 1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            color: hovered
                                ? kTwitterPollBlue.withValues(alpha: 0.16)
                                : Colors.white,
                          ),
                          child: Text(
                            option,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: hovered
                                  ? kTwitterPollBlue
                                  : kTwitterPollBlue.withValues(alpha: 0.92),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        Container(
                          height: 44,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFFCFD9DE),
                              width: 1,
                            ),
                            color: Colors.white,
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: percentage / 100,
                            child: Container(
                              color: kTwitterPollBlue.withValues(
                                alpha: isUserChoice ? 0.28 : 0.14,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 44,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: isUserChoice
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${percentage.round()}%',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey.shade800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFEFF3F4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Text(
                  '$totalVotes oy',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
                Expanded(
                  child: Center(child: pollTypeBadgeIcon(size: 17)),
                ),
                Text(
                  '$daysLeft gün kaldı',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
