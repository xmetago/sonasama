import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/app_theme.dart';
import '../utils/hashtag_text_helper.dart';

/// Dava Konusu Görüntüleme Widget'ı
/// Metin okuma odaklı, yüksek okunabilirlik için optimize edilmiş
class DavaKonusuDisplay extends StatelessWidget {
  final String davaKonusu;
  final String? title;
  final bool showCopyButton;
  
  const DavaKonusuDisplay({
    super.key,
    required this.davaKonusu,
    this.title,
    this.showCopyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Kopyala Butonu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: AppTheme.headline4.copyWith(
                    color: AppTheme.primaryColor,
                  ),
                ),
              if (showCopyButton && davaKonusu.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.copy, size: 20, color: AppTheme.iconSecondary),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: davaKonusu));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('Metin kopyalandı'),
                        backgroundColor: AppTheme.successColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  tooltip: 'Kopyala',
                ),
            ],
          ),
          if (title != null) const SizedBox(height: 16),
          // İçerik - Seçilebilir metin
          if (davaKonusu.isEmpty)
            Text(
              'Dava konusu henüz eklenmemiş.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SelectableText.rich(
              TextSpan(
                style: AppTheme.davaContent,
                children: buildHashtagAwareSpans(
                  davaKonusu,
                  baseStyle: AppTheme.davaContent,
                ),
              ),
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }
}

/// Haykırış İçeriği Görüntüleme Widget'ı
/// Vurgulu görünüm ile eğlenceli ama profesyonel
class HaykirContentDisplay extends StatelessWidget {
  final String content;
  final String? title;
  final bool showCopyButton;
  
  const HaykirContentDisplay({
    super.key,
    required this.content,
    this.title,
    this.showCopyButton = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.textBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(
            color: AppTheme.accentColor,
            width: 4,
          ),
          top: BorderSide(color: AppTheme.dividerColor, width: 1),
          right: BorderSide(color: AppTheme.dividerColor, width: 1),
          bottom: BorderSide(color: AppTheme.dividerColor, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.accentColor.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Kopyala Butonu
          if (title != null || showCopyButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTheme.headline4.copyWith(
                      color: AppTheme.accentColor,
                    ),
                  ),
                if (showCopyButton && content.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, size: 20, color: AppTheme.iconAccent),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Metin kopyalandı'),
                          backgroundColor: AppTheme.successColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Kopyala',
                  ),
              ],
            ),
          if (title != null) const SizedBox(height: 16),
          // İçerik
          if (content.isEmpty)
            Text(
              'İçerik henüz eklenmemiş.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SelectableText.rich(
              TextSpan(
                style: AppTheme.haykirContent,
                children: buildHashtagAwareSpans(
                  content,
                  baseStyle: AppTheme.haykirContent,
                ),
              ),
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }
}

/// Uzun Metin Görüntüleme Widget'ı (Genel Amaçlı)
/// Her türlü uzun metin için kullanılabilir
class LongTextDisplay extends StatelessWidget {
  final String text;
  final String? title;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool showCopyButton;
  final EdgeInsets? padding;
  
  const LongTextDisplay({
    super.key,
    required this.text,
    this.title,
    this.textStyle,
    this.backgroundColor,
    this.borderColor,
    this.showCopyButton = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.cardBackgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor ?? AppTheme.dividerColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık ve Kopyala Butonu
          if (title != null || showCopyButton)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (title != null)
                  Text(
                    title!,
                    style: AppTheme.headline4,
                  ),
                if (showCopyButton && text.isNotEmpty)
                  IconButton(
                    icon: Icon(Icons.copy, size: 20, color: AppTheme.iconSecondary),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Metin kopyalandı'),
                          backgroundColor: AppTheme.successColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    tooltip: 'Kopyala',
                  ),
              ],
            ),
          if (title != null) const SizedBox(height: 16),
          // İçerik
          if (text.isEmpty)
            Text(
              'İçerik henüz eklenmemiş.',
              style: AppTheme.bodyMedium.copyWith(
                color: AppTheme.textMuted,
                fontStyle: FontStyle.italic,
              ),
            )
          else
            SelectableText.rich(
              TextSpan(
                style: textStyle ?? AppTheme.davaContent,
                children: buildHashtagAwareSpans(
                  text,
                  baseStyle: textStyle ?? AppTheme.davaContent,
                ),
              ),
              textAlign: TextAlign.left,
            ),
        ],
      ),
    );
  }
}

