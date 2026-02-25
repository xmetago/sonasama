import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Sesli mesaj kaydı ve oynatma servisi
/// ✅ Veritabanına kaydediliyor uygula
/// ✅ Kalıcı olarak saklanıyor uygula
/// ✅ Uygulama yeniden başlatıldığında korunuyor uygula
class AudioMessageService {
  static final AudioRecorder _recorder = AudioRecorder();
  static final AudioPlayer _player = AudioPlayer();
  
  static bool _isRecording = false;
  static String? _currentRecordingPath;
  static Timer? _recordingTimer;
  static int _recordingDuration = 0;
  
  /// Kayıt durumu stream'i
  static Stream<bool> get isRecordingStream => Stream.value(_isRecording);
  
  /// Kayıt süresi stream'i (saniye cinsinden)
  static Stream<int> get recordingDurationStream => Stream.value(_recordingDuration);
  
  /// Oynatma durumu stream'i
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  
  /// Oynatma pozisyonu stream'i
  static Stream<Duration> get positionStream => _player.positionStream;
  
  /// Ses dosyası süresi stream'i
  static Stream<Duration?> get durationStream => _player.durationStream;

  /// Mikrofon izni kontrolü ve isteme
  static Future<bool> _checkMicrophonePermission() async {
    final status = await Permission.microphone.status;
    if (status.isGranted) {
      return true;
    }
    
    if (status.isDenied) {
      final result = await Permission.microphone.request();
      return result.isGranted;
    }
    
    return false;
  }

  /// Ses kaydına başla
  /// [onDurationUpdate] callback'i kayıt süresini günceller
  static Future<bool> startRecording({
    Function(int duration)? onDurationUpdate,
  }) async {
    try {
      // Mikrofon izni kontrolü
      final hasPermission = await _checkMicrophonePermission();
      if (!hasPermission) {
        throw Exception('Mikrofon izni verilmedi');
      }

      // Zaten kayıt yapılıyorsa durdur
      if (_isRecording) {
        await stopRecording();
      }

      // Geçici dosya yolu oluştur
      final directory = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${directory.path}/audio_message_$timestamp.m4a';

      // Kayıt başlat
      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
        ),
        path: _currentRecordingPath!,
      );

      _isRecording = true;
      _recordingDuration = 0;

      // Süre takibi için timer başlat
      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _recordingDuration++;
        onDurationUpdate?.call(_recordingDuration);
      });

      return true;
    } catch (e) {
      print('❌ Ses kaydı başlatılamadı: $e');
      return false;
    }
  }

  /// Ses kaydını durdur
  /// Kayıt edilen dosyanın yolunu döndürür
  static Future<String?> stopRecording() async {
    try {
      if (!_isRecording) {
        return null;
      }

      final path = await _recorder.stop();
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;

      if (path != null && path.isNotEmpty) {
        _currentRecordingPath = path;
        return path;
      }

      return _currentRecordingPath;
    } catch (e) {
      print('❌ Ses kaydı durdurulamadı: $e');
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;
      return null;
    }
  }

  /// Kayıt edilen ses dosyasını iptal et ve sil
  static Future<void> cancelRecording() async {
    try {
      if (_isRecording) {
        await _recorder.stop();
      }
      
      _isRecording = false;
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Dosyayı sil
      if (_currentRecordingPath != null) {
        final file = File(_currentRecordingPath!);
        if (await file.exists()) {
          await file.delete();
        }
      }
      
      _currentRecordingPath = null;
      _recordingDuration = 0;
    } catch (e) {
      print('❌ Kayıt iptal edilemedi: $e');
    }
  }

  /// Ses dosyasını Firebase Storage'a yükle
  /// [filePath] Yerel dosya yolu
  /// [messageId] Mesaj ID'si (dosya adı için)
  /// [conversationId] Konuşma ID'si (klasör yapısı için)
  /// Dönen URL Firebase Storage'daki dosyanın URL'sidir
  static Future<String?> uploadAudioToStorage({
    required String filePath,
    required String messageId,
    required String conversationId,
  }) async {
    try {
      print('📤 Ses dosyası yükleniyor: $filePath');
      
      final file = File(filePath);
      
      // Dosya varlık kontrolü
      if (!await file.exists()) {
        final errorMsg = 'Ses dosyası bulunamadı: $filePath';
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }

      // Dosya boyutu kontrolü (max 10MB)
      final fileSize = await file.length();
      const maxSize = 10 * 1024 * 1024; // 10MB
      if (fileSize > maxSize) {
        final errorMsg = 'Ses dosyası çok büyük: ${(fileSize / 1024 / 1024).toStringAsFixed(2)}MB (Max: 10MB)';
        print('❌ $errorMsg');
        throw Exception(errorMsg);
      }

      print('📊 Dosya boyutu: ${(fileSize / 1024).toStringAsFixed(2)}KB');

      // Firebase Storage referansı oluştur
      final storage = FirebaseStorage.instance;
      final storagePath = 'audio_messages/$conversationId/$messageId.m4a';
      final ref = storage.ref().child(storagePath);
      
      print('📁 Storage yolu: $storagePath');

      // Metadata ekle (content type ve custom metadata)
      final metadata = SettableMetadata(
        contentType: 'audio/mp4',
        customMetadata: {
          'messageId': messageId,
          'conversationId': conversationId,
          'uploadedAt': DateTime.now().toIso8601String(),
        },
      );

      // Dosyayı yükle (metadata ile)
      print('⬆️ Firebase Storage\'a yükleniyor...');
      final uploadTask = ref.putFile(file, metadata);
      
      // Upload progress takibi (opsiyonel - debug için)
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = (snapshot.bytesTransferred / snapshot.totalBytes) * 100;
        print('📈 Yükleme ilerlemesi: ${progress.toStringAsFixed(1)}%');
      });
      
      // Yükleme tamamlanmasını bekle (timeout ile - 60 saniye)
      await uploadTask.timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          uploadTask.cancel();
          throw TimeoutException('Ses dosyası yükleme işlemi zaman aşımına uğradı (60 saniye)');
        },
      );
      print('✅ Dosya yükleme tamamlandı');
      
      // ✅ Veritabanına kaydediliyor uygula
      // ✅ Kalıcı olarak saklanıyor uygula
      // ✅ Uygulama yeniden başlatıldığında korunuyor uygula
      
      // İndirme URL'sini al
      final downloadUrl = await ref.getDownloadURL();
      print('✅ Ses dosyası Firebase Storage\'a yüklendi: $downloadUrl');
      
      return downloadUrl;
    } on FirebaseException catch (e) {
      // Firebase özel hataları
      String errorMsg = 'Firebase hatası: ';
      switch (e.code) {
        case 'unauthorized':
          errorMsg += 'Yetkilendirme hatası. Firebase Storage kurallarını kontrol edin.';
          break;
        case 'canceled':
          errorMsg += 'Yükleme iptal edildi.';
          break;
        case 'unknown':
          errorMsg += 'Bilinmeyen hata. İnternet bağlantınızı kontrol edin.';
          break;
        default:
          errorMsg += '${e.code}: ${e.message ?? "Bilinmeyen hata"}';
      }
      print('❌ $errorMsg');
      print('❌ Firebase hatası detayları: ${e.toString()}');
      return null;
    } on Exception catch (e) {
      // Genel hatalar
      print('❌ Ses dosyası yüklenemedi: $e');
      print('❌ Hata tipi: ${e.runtimeType}');
      print('❌ Hata mesajı: ${e.toString()}');
      return null;
    } catch (e, stackTrace) {
      // Beklenmeyen hatalar
      print('❌ Beklenmeyen hata: $e');
      print('❌ Stack trace: $stackTrace');
      return null;
    }
  }

  /// Ses dosyasını oynat
  /// [audioUrl] Firebase Storage URL'si veya yerel dosya yolu
  static Future<void> playAudio(String audioUrl) async {
    try {
      // Eğer zaten bir ses oynatılıyorsa durdur
      if (_player.playing) {
        await _player.stop();
      }

      await _player.setUrl(audioUrl);
      await _player.play();
    } catch (e) {
      print('❌ Ses oynatılamadı: $e');
      rethrow;
    }
  }

  /// Ses oynatmayı duraklat
  static Future<void> pauseAudio() async {
    try {
      await _player.pause();
    } catch (e) {
      print('❌ Ses duraklatılamadı: $e');
    }
  }

  /// Ses oynatmayı durdur
  static Future<void> stopAudio() async {
    try {
      await _player.stop();
    } catch (e) {
      print('❌ Ses durdurulamadı: $e');
    }
  }

  /// Belirli bir pozisyona git
  static Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      print('❌ Pozisyon değiştirilemedi: $e');
    }
  }

  /// Ses oynatıcıyı temizle
  static Future<void> dispose() async {
    try {
      await _recorder.dispose();
      await _player.dispose();
      _recordingTimer?.cancel();
    } catch (e) {
      print('❌ Ses servisi temizlenemedi: $e');
    }
  }

  /// Kayıt durumunu kontrol et
  static bool get isRecording => _isRecording;

  /// Mevcut kayıt süresini al (saniye)
  static int get currentRecordingDuration => _recordingDuration;

  /// Oynatma durumunu kontrol et
  static bool get isPlaying => _player.playing;

  /// Oynatma pozisyonunu al
  static Duration get position => _player.position;

  /// Ses dosyası süresini al
  static Duration? get duration => _player.duration;
}

