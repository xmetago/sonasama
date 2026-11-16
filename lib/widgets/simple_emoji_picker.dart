import 'package:flutter/material.dart';

import '../theme/seyir_tokens.dart';
import 'delil_surface.dart';

/// Basit emoji picker widget'ı
/// Popüler emojileri gösterir
class SimpleEmojiPicker extends StatelessWidget {
  final Function(String emoji) onEmojiSelected;

  const SimpleEmojiPicker({
    super.key,
    required this.onEmojiSelected,
  });

  // Popüler emojiler listesi
  static const List<String> _emojis = [
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
    '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',
    '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
    '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
    '😌', '😔', '😪', '🤤', '😴', '😷', '🤒', '🤕', '🤢', '🤮',
    '🤧', '🥵', '🥶', '😵', '🤯', '🤠', '🥳', '😎', '🤓', '🧐',
    '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘',
    '👌', '🤏', '👈', '👉', '👆', '👇', '☝️', '👋', '🤚', '🖐',
    '✋', '🖖', '👏', '🙌', '🤲', '🤝', '🙏', '✍️', '💪', '🦾',
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '☮️',
    '✝️', '☪️', '🕉', '☸️', '✡️', '🔯', '🕎', '☯️', '☦️', '🛐',
    '⛎', '♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐',
    '♑', '♒', '♓', '🆔', '⚛️', '🉑', '☢️', '☣️', '📴', '📳',
    '🈶', '🈚', '🈸', '🈺', '🈷️', '✴️', '🆚', '💮', '🉐', '㊙️',
    '㊗️', '🈴', '🈵', '🈹', '🈲', '🅰️', '🅱️', '🆎', '🆑', '🅾️',
    '🆘', '❌', '⭕', '🛑', '⛔', '📛', '🚫', '💯', '💢', '♨️',
    '🚷', '🚯', '🚳', '🚱', '🔞', '📵', '🚭', '❗', '❓', '❕',
    '❔', '‼️', '⁉️', '🔅', '🔆', '〽️', '⚠️', '🚸', '🔱', '⚜️',
    '🔰', '♻️', '✅', '🈯', '💹', '❇️', '✳️', '❎', '🌐', '💠',
    'Ⓜ️', '🌀', '💤', '🏧', '🚾', '♿', '🅿️', '🈳', '🈂️', '🛂',
    '🛃', '🛄', '🛅', '🚹', '🚺', '🚼', '🚻', '🚮', '🎦', '📶',
    '🈁', '🔣', 'ℹ️', '🔤', '🔡', '🔠', '🔢', '🔟', '🔢', '🔢',
  ];

  @override
  Widget build(BuildContext context) {
    final palette = SeyirPalette.of(context);
    return Container(
      height: 300,
      color: palette.card,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: SeyirTokens.space4,
              vertical: SeyirTokens.space2,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: palette.border),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Emoji Seç', style: palette.headline()),
                IconButton(
                  tooltip: 'Kapat',
                  style: delilIconButtonStyle(foreground: palette.textPrimary),
                  icon: Icon(Icons.close, color: palette.textPrimary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(SeyirTokens.space4),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                crossAxisSpacing: SeyirTokens.space2,
                mainAxisSpacing: SeyirTokens.space2,
              ),
              itemCount: _emojis.length,
              itemBuilder: (context, index) {
                return InkWell(
                  onTap: () {
                    onEmojiSelected(_emojis[index]);
                    Navigator.pop(context);
                  },
                  borderRadius: SeyirTokens.radiusSmAll,
                  child: Container(
                    decoration: BoxDecoration(
                      color: palette.surfaceMuted,
                      borderRadius: SeyirTokens.radiusSmAll,
                      border: Border.all(color: palette.border),
                    ),
                    child: Center(
                      child: Text(
                        _emojis[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

