/// Notification service for handling FCM and local notifications

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'audio_service.dart';

/// Background message handler (must be top-level function)
/// This is called when app is in background or terminated
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  
  final data = message.data;
  
  // Check if this is a predator alert
  if (data['type'] == 'predator_alert') {
    // Initialize Flutter bindings for background isolate
    WidgetsFlutterBinding.ensureInitialized();
    
    // Send broadcast to native AlertReceiver to launch app
    const platform = MethodChannel('com.predatoralert.app/alert');
    try {
      await platform.invokeMethod('launchAlert', {
        'animal': data['animal'] ?? 'unknown',
        'confidence': data['confidence'] ?? '0',
      });
    } catch (e) {
      print('Could not invoke native launcher: $e');
    }
    
    // Also show notification with siren sound
    final FlutterLocalNotificationsPlugin localNotifications = 
        FlutterLocalNotificationsPlugin();
    
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await localNotifications.initialize(initSettings);
    
    // Create notification channel with custom siren sound
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'predator_alerts_call',
      'Predator Alerts',
      description: 'Critical predator detection alerts',
      importance: Importance.max,
      playSound: true,
      sound: const RawResourceAndroidNotificationSound('siren'),
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
    );
    
    await localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
    
    // Create phone-call style notification
    final androidDetails = AndroidNotificationDetails(
      'predator_alerts_call',
      'Predator Alerts',
      channelDescription: 'Critical predator detection alerts',
      importance: Importance.max,
      priority: Priority.max,
      fullScreenIntent: true,
      category: AndroidNotificationCategory.call,
      visibility: NotificationVisibility.public,
      sound: const RawResourceAndroidNotificationSound('siren'),
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 1000, 500, 1000, 500, 1000]),
      ongoing: true,
      autoCancel: false,
      timeoutAfter: 60000,
      audioAttributesUsage: AudioAttributesUsage.alarm,
    );
    
    await localNotifications.show(
      999,
      '🚨 ${data['title'] ?? 'PREDATOR ALERT'}',
      data['body'] ?? 'Predator detected!',
      NotificationDetails(android: androidDetails),
      payload: 'predator_alert:${data['animal'] ?? 'unknown'}',
    );
  }
}

class NotificationService {
  NotificationService._();
  
  static final NotificationService instance = NotificationService._();
  
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = 
      FlutterLocalNotificationsPlugin();
  
  // Callback for handling predator alerts
  Function(Map<String, dynamic>)? onPredatorAlert;
  
  Future<void> initialize() async {
    // Request permission
    await _requestPermission();
    
    // Configure local notifications
    await _initializeLocalNotifications();
    
    // Configure FCM
    await _configureFCM();
    
    // Subscribe to predator alerts topic
    await _messaging.subscribeToTopic('predator_alerts');
    
    print('✓ Notification service initialized');
  }
  
  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      criticalAlert: true,
      provisional: false,
    );
    
    print('Notification permission: ${settings.authorizationStatus}');
  }
  
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
    
    // Create notification channel for Android
    const channel = AndroidNotificationChannel(
      'predator_alerts',
      'Predator Alerts',
      description: 'Critical alerts for predator detections',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  Future<void> _configureFCM() async {
    // Background message handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    
    // Handle notification tap when app was terminated
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Delay slightly to ensure app is fully initialized
      Future.delayed(const Duration(milliseconds: 500), () {
        _handleNotificationTap(initialMessage.data);
      });
    }
    
    // Handle notification tap when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      _handleNotificationTap(message.data);
    });
    
    // Get FCM token
    final token = await _messaging.getToken();
    print('FCM Token: $token');
  }
  
  void _handleForegroundMessage(RemoteMessage message) {
    print('Foreground message: ${message.notification?.title}');
    
    final data = message.data;
    
    // Check if this is a predator alert
    if (data['type'] == 'predator_alert') {
      _handlePredatorAlert(data);
    } else {
      // Show regular notification
      _showLocalNotification(
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        payload: message.messageId,
      );
    }
  }
  
  void _handlePredatorAlert(Map<String, dynamic> data) {
    // Always trigger siren for predator alerts
    final sirenEnabled = data['siren_enabled'] != 'false';
    if (sirenEnabled) {
      AudioService.instance.playSiren();
    }
    
    // Call the alert callback
    onPredatorAlert?.call(data);
    
    // Show high-priority notification
    _showLocalNotification(
      title: '🚨 PREDATOR ALERT',
      body: '${data['animal']?.toString().toUpperCase() ?? 'Unknown'} detected!',
      payload: data['detection_id'],
      isPredatorAlert: true,
    );
  }
  
  void _handleNotificationTap(Map<String, dynamic> data) {
    print('Notification tapped with data: $data');
    
    if (data['type'] == 'predator_alert') {
      // Trigger siren when app opens from notification tap
      final sirenEnabled = data['siren_enabled'] != 'false';
      if (sirenEnabled) {
        AudioService.instance.playSiren();
      }
      
      // Trigger the siren overlay
      onPredatorAlert?.call(data);
    }
  }
  
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.payload}');
    
    // Handle predator alert notifications (from background handler)
    if (response.payload != null && response.payload!.startsWith('predator_alert:')) {
      final animal = response.payload!.split(':').last;
      
      // Cancel the ongoing siren notification
      _localNotifications.cancel(999);
      
      // Trigger in-app siren
      AudioService.instance.playSiren();
      
      // Trigger the siren overlay
      onPredatorAlert?.call({
        'type': 'predator_alert',
        'animal': animal,
        'siren_enabled': 'true',
      });
    }
  }
  
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    bool isPredatorAlert = false,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      isPredatorAlert ? 'predator_alerts' : 'general',
      isPredatorAlert ? 'Predator Alerts' : 'General',
      importance: isPredatorAlert ? Importance.max : Importance.high,
      priority: isPredatorAlert ? Priority.max : Priority.high,
      color: isPredatorAlert ? const Color(0xFFFF1744) : null,
      enableVibration: true,
      fullScreenIntent: isPredatorAlert,
    );
    
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    
    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      details,
      payload: payload,
    );
  }
  
  Future<String?> getToken() async {
    return await _messaging.getToken();
  }
}
