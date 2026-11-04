import 'package:flutter/material.dart';

/// Gelen arkadaşlık isteklerinin listesi. Satırlar [itemBuilder] ile kurulur.
class FriendshipIncomingRequestsDialog extends StatelessWidget {
  const FriendshipIncomingRequestsDialog({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
  });

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      title: const Text(
        'Gelen Arkadaşlık İstekleri',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: itemCount,
          itemBuilder: itemBuilder,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Kapat',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ],
    );
  }
}
