import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';

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
      print('❌ Ses oynatıcı başlatılamadı: $e');
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
      print('❌ Oynat/Duraklat hatası: $e');
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: widget.isSent ? Colors.blue.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Oynat/Duraklat butonu
          IconButton(
            icon: Icon(
              _isPlaying ? Icons.pause : Icons.play_arrow,
              color: widget.isSent ? Colors.blue : Colors.grey.shade700,
            ),
            onPressed: _togglePlayPause,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          // İlerleme çubuğu
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.isSent ? Colors.blue : Colors.grey.shade600,
                  ),
                  minHeight: 4,
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDuration(_position),
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.isSent ? Colors.blue.shade700 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Toplam süre
          Text(
            _formatDuration(displayDuration),
            style: TextStyle(
              fontSize: 12,
              color: widget.isSent ? Colors.blue.shade700 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

