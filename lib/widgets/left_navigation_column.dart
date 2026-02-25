import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../screens/actigim_davalar_page.dart';
import '../screens/gelen_davalar_page.dart';
import '../screens/katildigim_davalar_page.dart';
import '../screens/cezalar_page.dart';

/// Sol tarafta yer alan standart gezinme ikonlarını gösterir.
class LeftNavigationColumn extends StatelessWidget {
  final String? userEmail;

  const LeftNavigationColumn({
    super.key,
    required this.userEmail,
  });

  void _navigateTo(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 60,
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () {
              _navigateTo(
                context,
                GelenDavalarPage(userEmail: userEmail),
              );
            },
            child: const Padding(
              padding: EdgeInsets.fromLTRB(8, 18, 8, 8),
              child: Icon(
                Icons.gavel_outlined,
                size: 24,
                color: Colors.black54,
              ),
            ),
          ),

          GestureDetector(
            onTap: () {
              _navigateTo(
                context,
                KatildigimDavalarPage(userEmail: userEmail),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
              child: IconButton(
                icon: Icon(
                  MdiIcons.briefcaseEditOutline,
                  size: 24,
                  color: Colors.black54,
                ),
                onPressed: () {
                  _navigateTo(
                    context,
                    CezalarPage(userEmail: userEmail),
                  );
                },
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              _navigateTo(
                context,
                ActigimDavalarPage(userEmail: userEmail),
              );
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 8),
              child: IconButton(
                icon: Icon(
                  MdiIcons.handcuffs,
                  size: 24,
                  color: Colors.black54,
                ),
                onPressed: () {
                  _navigateTo(
                    context,
                    CezalarPage(userEmail: userEmail),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}


