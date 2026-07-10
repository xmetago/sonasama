import 'package:flutter/material.dart';

import 'dava_sayilari_card.dart';

/// Açtığım davalar sayfası için daraltılabilir dava sayıları özeti.
class ActigimDavaSayilariSection extends StatefulWidget {
  final int actigim;
  final int hakli;
  final int haksiz;
  final int banaAcilan;

  const ActigimDavaSayilariSection({
    super.key,
    required this.actigim,
    required this.hakli,
    required this.haksiz,
    required this.banaAcilan,
  });

  @override
  State<ActigimDavaSayilariSection> createState() =>
      _ActigimDavaSayilariSectionState();
}

class _ActigimDavaSayilariSectionState extends State<ActigimDavaSayilariSection> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return DavaSayilariCard(
      katildigim: widget.actigim,
      hakli: widget.hakli,
      haksiz: widget.haksiz,
      banaAcilan: widget.banaAcilan,
      expanded: _expanded,
      actigimMode: true,
      onHeaderTap: () => setState(() => _expanded = !_expanded),
    );
  }
}
