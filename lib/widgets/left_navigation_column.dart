import 'package:flutter/material.dart';

import 'cezalar_page_layout_rails.dart';

/// [CezalarPage] ile aynı sol kaydırılabilir ikon sütunu ([CezalarLeftIconScrollColumn]).
class LeftNavigationColumn extends StatelessWidget {
  final String? userEmail;

  const LeftNavigationColumn({
    super.key,
    required this.userEmail,
  });

  @override
  Widget build(BuildContext context) {
    return CezalarLeftIconScrollColumn(userEmail: userEmail);
  }
}
