import 'package:flutter/material.dart';

/// Metin snack'i. Renk ve süre verilmezse [SnackBar] varsayılanı kullanılır.
///
/// Kuyruk davranışı `ScaffoldMessenger.showSnackBar` ile aynıdır.
void showAppSnack(
  BuildContext context,
  String message, {
  Color? backgroundColor,
  Duration? duration,
}) {
  final SnackBar snackBar = SnackBar(
    content: Text(message),
    backgroundColor: backgroundColor,
    duration: duration ?? const Duration(milliseconds: 4000),
  );
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
