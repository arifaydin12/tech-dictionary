import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../services/firebase_service.dart';

import 'package:flutter/material.dart';

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final FirebaseService _firebaseService = FirebaseService();
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    // Local notifications ayarları
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // FCM izinleri
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // FCM token al
    final token = await _firebaseMessaging.getToken();
    if (token != null && _firebaseService.isLoggedIn) {
      await _saveToken(token);
    }

    // Token yenilendiğinde
    _firebaseMessaging.onTokenRefresh.listen(_saveToken);

    // Mesaj geldiğinde
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    _isInitialized = true;
  }

  Future<void> _saveToken(String token) async {
    if (!_firebaseService.isLoggedIn) return;

    // Token'ı Firestore'a kaydet
    // TODO: Implement
    debugPrint('FCM Token: $token');
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Bildirime tıklandığında
    debugPrint('Bildirime tıklandı: ${response.payload}');
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    // Foreground'da mesaj geldiğinde local notification göster
    await showLocalNotification(
      title: message.notification?.title ?? 'Yeni Bildirim',
      body: message.notification?.body ?? '',
      payload: message.data.toString(),
    );
  }

  /// Local bildirim göster
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'default_channel',
      'Genel Bildirimler',
      channelDescription: 'Genel bildirimler için kanal',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title,
      body,
      details,
      payload: payload,
    );
  }

  /// Günlük kelime hatırlatıcısı
  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    const androidDetails = AndroidNotificationDetails(
      'daily_reminder',
      'Günlük Hatırlatıcı',
      channelDescription: 'Günlük kelime öğrenme hatırlatıcısı',
      importance: Importance.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.periodicallyShow(
      0,
      'Yeni Kelime Öğrenme Zamanı!',
      'Bugün hangi yeni kelimeleri öğreneceksiniz?',
      RepeatInterval.daily,
      details,
    );
  }

  void dispose() {
    // Cleanup
  }
}
