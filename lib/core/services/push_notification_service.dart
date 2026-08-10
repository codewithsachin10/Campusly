import 'dart:convert';
import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../router/app_router.dart';

// Top-level function to handle background FCM messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Handle background data/message if needed
  debugPrint("Handling a background message: ${message.messageId}");
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Firebase (Requires GoogleService-Info.plist & google-services.json)
      await Firebase.initializeApp();
      
      // 2. Set background message handler
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // 3. Setup Local Notifications (for Android Heads-Up)
      await _setupLocalNotifications();

      // 4. Request Permissions (Don't await before runApp to prevent deadlocks)
      _fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: true,
        provisional: false,
        sound: true,
      ).then((settings) {
        debugPrint('User granted permission: ${settings.authorizationStatus}');
      });

      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Handle notification opens
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);
      
      // Handle app opened from terminated state
      final initialMessage = await _fcm.getInitialMessage();
      if (initialMessage != null) {
        _handleNotificationTap(initialMessage);
      }

      // 7. Sync FCM Token to Supabase
      await _syncToken();
      _fcm.onTokenRefresh.listen((token) {
        _syncToken(newToken: token);
      });

      _isInitialized = true;
    } catch (e) {
      debugPrint('Failed to initialize push notifications: $e');
      // Gracefully handle if Firebase isn't configured in the project yet
    }
  }

  Future<void> _setupLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );
    
    const initSettings = InitializationSettings(android: androidInit, iOS: iosInit);
    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          final data = jsonDecode(details.payload!);
          _routeNotification(data);
        }
      },
    );

    // Create high-priority channel for Android Class Alerts
    if (Platform.isAndroid) {
      const channel = AndroidNotificationChannel(
        'campusly_class_alerts', // id
        'Class Alerts', // name
        description: 'Important notifications about class venue and time changes.',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
    }
  }

  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('Got a message whilst in the foreground!');
    debugPrint('Message data: ${message.data}');

    if (message.notification != null) {
      final notification = message.notification!;
      final android = message.notification?.android;

      // Check user preferences in Supabase before showing
      // (This can be cached locally, but for now we'll just show it)
      
      _localNotifications.show(
        id: notification.hashCode,
        title: notification.title,
        body: notification.body,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'campusly_class_alerts',
            'Class Alerts',
            channelDescription: 'Important notifications about class venue and time changes.',
            importance: Importance.max,
            priority: Priority.high,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  void _handleNotificationTap(RemoteMessage message) {
    _routeNotification(message.data);
  }

  void _routeNotification(Map<String, dynamic> data) {
    debugPrint("Routing notification: $data");
    
    // Check if we have a valid context for navigation
    final context = rootNavigatorKey.currentContext;
    if (context != null) {
      if (data['change_type'] != null) {
        context.push('/notifications/alert', extra: jsonEncode(data));
      }
    } else {
      debugPrint("Root navigator context is null. Could not route notification.");
    }
  }

  Future<void> _syncToken({String? newToken}) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final token = newToken ?? await _fcm.getToken();
    if (token == null) return;

    try {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      
      // Upsert token in user_devices
      await Supabase.instance.client.from('user_devices').upsert({
        'user_id': user.id,
        'device_id': 'default_device_${Platform.operatingSystem}', // Ideal to use a device_info plugin here
        'push_token': token,
        'platform': Platform.operatingSystem,
        'app_version': packageInfo.version,
        'is_active': true,
        'last_seen_at': DateTime.now().toIso8601String(),
      });
      debugPrint('FCM Token synced successfully');
    } catch (e) {
      debugPrint('Failed to sync FCM token: $e');
    }
  }

  Future<void> clearToken() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      await Supabase.instance.client
          .from('user_devices')
          .update({'is_active': false})
          .eq('user_id', user.id)
          .eq('device_id', 'default_device_${Platform.operatingSystem}');
      await _fcm.deleteToken();
    } catch (e) {
      debugPrint('Failed to clear FCM token: $e');
    }
  }
}
