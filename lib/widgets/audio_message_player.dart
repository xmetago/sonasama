import 'dart:async';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../theme/seyir_tokens.dart';
import 'delil_surface.dart';
import 'package:its19/utils/app_logger.dart';

/// Sesli mesaj oynatıcı widget'ı
/// Sesli mesajları oynatmak için kullanılır
class AudioMessagePlayer extends StatefulWidget {
  final String audioUrl;
  final int? duration; // Saniye cinsinden süre
  final bool isSent; // Mesaj gönderen tarafından mı gönderildi

  const AudioMessagePlayer({
    super.key,
    required this.audioUrl,
    this.duration,
    this.isSent = false,
  });

  @override
  State<AudioMessagePlayer> createState() => _AudioMessagePlayerState();
}

class _AudioMessagePlayerState extends State<AudioMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration? _duration;
  StreamSubscription? _positionSubscription;
  StreamSubscription? _playerStateSubscription;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      // Ses dosyasını yükle
      await _player.setUrl(widget.audioUrl);
      
      // Süre bilgisini al
      _duration = _player.duration;
      
      // Pozisyon ve durum stream'lerini dinle
      _positionSubscription = _player.positionStream.listen((position) {
        if (mounted) {
          setState(() {
            _position = position;
          });
        }
      });

      _playerStateSubscription = _player.playerStateStream.listen((state) {
        if (mounted) {
          setState(() {
            _isPlaying = state.playing;
            if (state.processingState == ProcessingState.completed) {
              _isPlaying = false;
              _position = Duration.zero;
            }
          });
        }
      });
    } catch (e) {
      appLog('❌ Ses oynatıcı başlatılamadı: $e');
    }
  }

  Future<void> _togglePlayPause() async {
    try {
      if (_isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } catch (e) {
      appLog('❌ Oynat/Duraklat hatası: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ses oynatılamadı: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _playerStateSubscription?.cancel();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayDuration = _duration ?? (widget.duration != null ? Duration(seconds: widget.duration!) : Duration.zero);
    final progress = displayDuration.inMilliseconds > 0
        ? _position.inMilliseconds / displayDuration.inMilliseconds
        : 0.0;

    final palette = SeyirPalette.of(context);
    const sentBlue = Color(0xFF1976D2);
    final accent = widget.isSent ? sentBlue : palette.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SeyirTokens.space2,
        vertical: SeyirTokens.space1,
      ),
      decoration: BoxDecoration(
        color: widget.isSent ? palette.tint(sentBlue) : palette.surfaceMuted,
        borderRadius: SeyirTokens.radiusLgAll,
        border: Border.all(color: palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: _isPlaying ? 'Duraklat' : 'Oynat',
            style: delilIconButtonStyle(foreground: accent),
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: accent,
            ),
            onPressed: _togglePlayPause,
          ),
          const SizedBox(width: SeyirTokens.space2),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: palette.border,
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                  minHeight: 4,
                ),
                const SizedBox(height: SeyirTokens.space1),
                Text(
                  _formatDuration(_position),
                  style: palette.caption(color: accent),
                ),
              ],
            ),
          ),
          const SizedBox(width: SeyirTokens.space2),
          Text(
            _formatDuration(displayDuration),
            style: palette.caption(color: accent),
          ),
        ],
      ),
    );
  }
}

