import 'package:flutter/material.dart';

/// Sayfa başlığı ve sağda yenile düğmesi.
///
/// Yükleme sürerken düğme devre dışı kalır ve ikon griye döner.
class AppRefreshTitleBar extends StatelessWidget {
  const AppRefreshTitleBar({
    super.key,
    required this.title,
    required this.isLoading,
    required this.onRefresh,
  });

  final String title;
  final bool isLoading;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: isLoading ? Colors.grey : Theme.of(context).primaryColor,
            ),
            onPressed: isLoading ? null : onRefresh,
            tooltip: 'Yenile',
          ),
        ],
      ),
    );
  }
}
