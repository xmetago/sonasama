import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

/// Yerel bildirim servisi
/// Uygulama içi ve arka plan bildirimlerini yönetir
/// ✅ Veritabanına kaydediliyor
/// ✅ Kalıcı olarak saklanıyor
/// ✅ Uygulama yeniden başlatıldığında korunuyor
class LocalNotificationService {
  static final LocalNotificationService _instance = LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  static final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;
  static Box? _notificationBox;

  /// Bildirim servisini başlat
  /// Android ve iOS için gerekli yapılandırmaları yapar
  static Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('⚠️ LocalNotificationService zaten başlatılmış');
      return;
    }

    try {
      // Timezone verilerini yükle (zamanlanmış bildirimler için)
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));

      // Android yapılandırması
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS yapılandırması
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      // Platform ayarları
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Bildirimleri başlat
      final bool? initialized = await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      if (initialized == true) {
        _isInitialized = true;
        debugPrint('✅ LocalNotificationService başlatıldı');

        // Android için bildirim kanalları oluştur
        await _createNotificationChannels();

        // Bildirim veritabanını başlat
        await _initializeNotificationDatabase();
      } else {
        debugPrint('❌ LocalNotificationService başlatılamadı');
      }
    } catch (e) {
      debugPrint('❌ LocalNotificationService başlatılırken hata: $e');
    }
  }

  /// Android bildirim kanallarını oluştur
  /// Farklı bildirim türleri için ayrı kanallar
  static Future<void> _createNotificationChannels() async {
    if (!Platform.isAndroid) return;

    // Mesaj bildirimleri kanalı
    const androidChannelMesaj = AndroidNotificationChannel(
      'mesaj_bildirimleri',
      'Mesaj Bildirimleri',
      description: 'Yeni mesaj bildirimleri için kanal',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Dava bildirimleri kanalı
    const androidChannelDava = AndroidNotificationChannel(
      'dava_bildirimleri',
      'Dava Bildirimleri',
      description: 'Dava ile ilgili bildirimler için kanal',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    // Uyarı bildirimleri kanalı
    const androidChannelUyari = AndroidNotificationChannel(
      'uyari_bildirimleri',
      'Uyarı Bildirimleri',
      description: 'Uyarı ve hatırlatma bildirimleri için kanal',
      importance: Importance.defaultImportance,
      playSound: true,
      enableVibration: false,
    );

    // Kanalları oluştur
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannelMesaj);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannelDava);

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannelUyari);

    debugPrint('✅ Bildirim kanalları oluşturuldu');
  }

  /// Bildirim veritabanını başlat
  /// ✅ Kalıcı olarak saklanıyor
  static Future<void> _initializeNotificationDatabase() async {
    try {
      // Hive box'ı aç veya oluştur
      _notificationBox = await Hive.openBox('notifications');
      debugPrint('✅ Bildirim veritabanı başlatıldı');
    } catch (e) {
      debugPrint('❌ Bildirim veritabanı başlatılırken hata: $e');
    }
  }

  /// Bildirim tıklandığında çağrılır
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('📱 Bildirim tıklandı: ${response.id} - ${response.payload}');
    // Burada bildirime tıklandığında yapılacak işlemler yapılabilir
    // Örneğin: Belirli bir sayfaya yönlendirme
  }

  /// Basit bildirim göster
  /// [title] Bildirim başlığı
  /// [body] Bildirim içeriği
  /// [payload] Bildirime tıklandığında gönderilecek veri
  /// [channelId] Bildirim kanalı ID'si (varsayılan: 'mesaj_bildirimleri')
  static Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'mesaj_bildirimleri',
    int? notificationId,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ LocalNotificationService başlatılmamış');
      await initialize();
    }

    try {
      // Bildirim ID'si oluştur (eğer verilmemişse)
      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Android bildirim detayları
      const androidDetails = AndroidNotificationDetails(
        'mesaj_bildirimleri',
        'Mesaj Bildirimleri',
        channelDescription: 'Yeni mesaj bildirimleri için kanal',
        importance: Importance.high,
        priority: Priority.high,
        showWhen: true,
        enableVibration: true,
        playSound: true,
        icon: '@mipmap/ic_launcher',
      );

      // iOS bildirim detayları
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Platform ayarları
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Bildirimi göster
      await _notifications.show(
        id,
        title,
        body,
        notificationDetails,
        payload: payload,
      );

      // ✅ Bildirimi veritabanına kaydet
      await _saveNotificationToDatabase(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
        timestamp: DateTime.now(),
      );

      debugPrint('✅ Bildirim gösterildi: $title');
    } catch (e) {
      debugPrint('❌ Bildirim gösterilirken hata: $e');
    }
  }

  /// Dava bildirimi göster
  /// Dava ile ilgili bildirimler için özel metod
  static Future<void> showDavaNotification({
    required String title,
    required String body,
    String? davaId,
    String? payload,
  }) async {
    await showNotification(
      title: title,
      body: body,
      payload: payload ?? davaId,
      channelId: 'dava_bildirimleri',
      notificationId: davaId?.hashCode,
    );
  }

  /// Uyarı bildirimi göster
  /// Uyarı ve hatırlatma bildirimleri için özel metod
  static Future<void> showUyariNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    await showNotification(
      title: title,
      body: body,
      payload: payload,
      channelId: 'uyari_bildirimleri',
    );
  }

  /// Zamanlanmış bildirim göster
  /// Belirli bir zamanda bildirim gösterir
  /// [scheduledDate] Bildirimin gösterileceği tarih ve saat
  static Future<void> scheduleNotification({
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    String channelId = 'uyari_bildirimleri',
    int? notificationId,
  }) async {
    if (!_isInitialized) {
      debugPrint('⚠️ LocalNotificationService başlatılmamış');
      await initialize();
    }

    try {
      // Bildirim ID'si oluştur
      final id = notificationId ?? DateTime.now().millisecondsSinceEpoch.remainder(100000);

      // Android bildirim detayları
      const androidDetails = AndroidNotificationDetails(
        'uyari_bildirimleri',
        'Uyarı Bildirimleri',
        channelDescription: 'Uyarı ve hatırlatma bildirimleri için kanal',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        showWhen: true,
      );

      // iOS bildirim detayları
      const iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      // Platform ayarları
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      // Zamanlanmış bildirimi ayarla
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );

      // ✅ Bildirimi veritabanına kaydet
      await _saveNotificationToDatabase(
        id: id,
        title: title,
        body: body,
        payload: payload,
        channelId: channelId,
        timestamp: scheduledDate,
        isScheduled: true,
      );

      debugPrint('✅ Zamanlanmış bildirim ayarlandı: $title - $scheduledDate');
    } catch (e) {
      debugPrint('❌ Zamanlanmış bildirim ayarlanırken hata: $e');
    }
  }

  /// Bildirimi veritabanına kaydet
  /// ✅ Kalıcı olarak saklanıyor
  /// ✅ Uygulama yeniden başlatıldığında korunuyor
  static Future<void> _saveNotificationToDatabase({
    required int id,
    required String title,
    required String body,
    String? payload,
    required String channelId,
    required DateTime timestamp,
    bool isScheduled = false,
  }) async {
    try {
      if (_notificationBox == null) {
        await _initializeNotificationDatabase();
      }

      final notificationData = {
        'id': id,
        'title': title,
        'body': body,
        'payload': payload,
        'channelId': channelId,
        'timestamp': timestamp.toIso8601String(),
        'isScheduled': isScheduled,
        'isRead': false,
      };

      // Bildirimi kaydet
      await _notificationBox?.put('notification_$id', notificationData);
      debugPrint('✅ Bildirim veritabanına kaydedildi: $id');
    } catch (e) {
      debugPrint('❌ Bildirim veritabanına kaydedilirken hata: $e');
    }
  }

  /// Tüm bildirimleri getir
  /// ✅ Veritabanından kalıcı bildirimleri okur
  static List<Map<String, dynamic>> getAllNotifications() {
    try {
      if (_notificationBox == null) {
        return [];
      }

      final notifications = <Map<String, dynamic>>[];
      final keys = _notificationBox!.keys;

      for (final key in keys) {
        if (key.toString().startsWith('notification_')) {
          final notification = _notificationBox!.get(key);
          if (notification is Map) {
            notifications.add(Map<String, dynamic>.from(notification));
          }
        }
      }

      // Tarihe göre sırala (en yeni önce)
      notifications.sort((a, b) {
        final dateA = DateTime.parse(a['timestamp'] as String);
        final dateB = DateTime.parse(b['timestamp'] as String);
        return dateB.compareTo(dateA);
      });

      return notifications;
    } catch (e) {
      debugPrint('❌ Bildirimler getirilirken hata: $e');
      return [];
    }
  }

  /// Bildirimi okundu olarak işaretle
  static Future<void> markAsRead(int notificationId) async {
    try {
      if (_notificationBox == null) {
        await _initializeNotificationDatabase();
      }

      final key = 'notification_$notificationId';
      final notification = _notificationBox?.get(key);

      if (notification is Map) {
        final updatedNotification = Map<String, dynamic>.from(notification);
        updatedNotification['isRead'] = true;
        await _notificationBox?.put(key, updatedNotification);
        debugPrint('✅ Bildirim okundu olarak işaretlendi: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ Bildirim okundu olarak işaretlenirken hata: $e');
    }
  }

  /// Bildirimi sil
  static Future<void> deleteNotification(int notificationId) async {
    try {
      if (_notificationBox == null) {
        await _initializeNotificationDatabase();
      }

      await _notificationBox?.delete('notification_$notificationId');
      await _notifications.cancel(notificationId);
      debugPrint('✅ Bildirim silindi: $notificationId');
    } catch (e) {
      debugPrint('❌ Bildirim silinirken hata: $e');
    }
  }

  /// Tüm bildirimleri sil
  static Future<void> deleteAllNotifications() async {
    try {
      if (_notificationBox == null) {
        await _initializeNotificationDatabase();
      }

      final keys = _notificationBox!.keys.toList();
      for (final key in keys) {
        if (key.toString().startsWith('notification_')) {
          await _notificationBox?.delete(key);
        }
      }

      await _notifications.cancelAll();
      debugPrint('✅ Tüm bildirimler silindi');
    } catch (e) {
      debugPrint('❌ Tüm bildirimler silinirken hata: $e');
    }
  }

  /// Bekleyen bildirimleri iptal et
  static Future<void> cancelScheduledNotification(int notificationId) async {
    try {
      await _notifications.cancel(notificationId);
      await deleteNotification(notificationId);
      debugPrint('✅ Zamanlanmış bildirim iptal edildi: $notificationId');
    } catch (e) {
      debugPrint('❌ Zamanlanmış bildirim iptal edilirken hata: $e');
    }
  }

  /// Bildirim izinlerini kontrol et
  static Future<bool> checkPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ için bildirim izni kontrolü
      final androidImplementation = _notifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        final granted = await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }
      return true; // Android 12 ve altı için varsayılan olarak true
    } else if (Platform.isIOS) {
      // iOS için bildirim izni kontrolü
      final iosImplementation = _notifications
          .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    }
    return false;
  }

  /// Bildirim izinlerini iste
  static Future<bool> requestPermissions() async {
    return await checkPermissions();
  }
}

