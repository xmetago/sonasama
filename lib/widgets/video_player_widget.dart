import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'dart:io';

class CustomVideoPlayer extends StatefulWidget {
  final String videoPath;
  final String title;

  const CustomVideoPlayer({
    super.key,
    required this.videoPath,
    required this.title,
  });

  @override
  State<CustomVideoPlayer> createState() => _CustomVideoPlayerState();
}

class _CustomVideoPlayerState extends State<CustomVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    try {
      print('🎥 Video player başlatılıyor: ${widget.videoPath}');
      
      _controller = VideoPlayerController.file(File(widget.videoPath));
      
      await _controller.initialize();
      
      _controller.addListener(() {
        if (mounted) {
          setState(() {
            _position = _controller.value.position;
            _duration = _controller.value.duration;
            _isPlaying = _controller.value.isPlaying;
          });
        }
      });

      setState(() {
        _isInitialized = true;
      });
      
      print('✅ Video player başarıyla başlatıldı');
    } catch (e) {
      print('❌ Video player başlatılırken hata: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Video yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _playPause() {
    if (_isPlaying) {
      _controller.pause();
    } else {
      _controller.play();
    }
  }

  void _seekTo(Duration position) {
    _controller.seekTo(position);
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    
    if (duration.inHours > 0) {
      return '$hours:$minutes:$seconds';
    } else {
      return '$minutes:$seconds';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: _isInitialized
            ? Column(
                children: [
                  // Video Player - Flexible ile sığdırma
                  Flexible(
                    flex: 3,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: VideoPlayer(_controller),
                      ),
                    ),
                  ),
                  
                  // Kontroller - Flexible ile sığdırma
                  Flexible(
                    flex: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Progress Bar
                          Slider(
                            value: _position.inMilliseconds.toDouble(),
                            min: 0,
                            max: _duration.inMilliseconds.toDouble(),
                            onChanged: (value) {
                              _seekTo(Duration(milliseconds: value.toInt()));
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey[600],
                          ),
                          
                          // Zaman Bilgisi
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatDuration(_position),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                                Text(
                                  _formatDuration(_duration),
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 8),
                          
                          // Play/Pause Butonu - Daha kompakt
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                onPressed: () {
                                  final newPosition = _position - const Duration(seconds: 10);
                                  _seekTo(newPosition.isNegative ? Duration.zero : newPosition);
                                },
                                icon: const Icon(Icons.replay_10, color: Colors.white, size: 28),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              IconButton(
                                onPressed: _playPause,
                                icon: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  color: Colors.white,
                                  size: 40,
                                ),
                              ),
                              
                              const SizedBox(width: 16),
                              
                              IconButton(
                                onPressed: () {
                                  final newPosition = _position + const Duration(seconds: 10);
                                  if (newPosition <= _duration) {
                                    _seekTo(newPosition);
                                  }
                                },
                                icon: const Icon(Icons.forward_10, color: Colors.white, size: 28),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      'Video yükleniyor...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
