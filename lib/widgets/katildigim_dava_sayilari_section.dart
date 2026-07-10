import 'package:flutter/material.dart';

import 'dava_sayilari_card.dart';

/// Katıldığım davalar sayfası için daraltılabilir dava sayıları özeti.
class KatildigimDavaSayilariSection extends StatefulWidget {
  final int katildigim;
  final int hakli;
  final int haksiz;
  final int banaAcilan;

  const KatildigimDavaSayilariSection({
    super.key,
    required this.katildigim,
    required this.hakli,
    required this.haksiz,
    required this.banaAcilan,
  });

  @override
  State<KatildigimDavaSayilariSection> createState() =>
      _KatildigimDavaSayilariSectionState();
}

class _KatildigimDavaSayilariSectionState
    extends State<KatildigimDavaSayilariSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return DavaSayilariCard(
      katildigim: widget.katildigim,
      hakli: widget.hakli,
      haksiz: widget.haksiz,
      banaAcilan: widget.banaAcilan,
      expanded: _expanded,
      onHeaderTap: () => setState(() => _expanded = !_expanded),
    );
  }
}
