import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../features/timetable/domain/models/timetable_item.dart';

// Notification preferences state
class NotificationPreferences {
  final bool masterEnabled;
  final bool remind15Min;
  final bool remind10Min;
  final bool morningBriefing;
  final bool soundAndVibrate;

  NotificationPreferences({
    this.masterEnabled = true,
    this.remind15Min = true,
    this.remind10Min = true,
    this.morningBriefing = false,
    this.soundAndVibrate = true,
  });

  NotificationPreferences copyWith({
    bool? masterEnabled,
    bool? remind15Min,
    bool? remind10Min,
    bool? morningBriefing,
    bool? soundAndVibrate,
  }) {
    return NotificationPreferences(
      masterEnabled: masterEnabled ?? this.masterEnabled,
      remind15Min: remind15Min ?? this.remind15Min,
      remind10Min: remind10Min ?? this.remind10Min,
      morningBriefing: morningBriefing ?? this.morningBriefing,
      soundAndVibrate: soundAndVibrate ?? this.soundAndVibrate,
    );
  }
}

class NotificationPreferencesNotifier
    extends Notifier<NotificationPreferences> {
  @override
  NotificationPreferences build() {
    return NotificationPreferences();
  }

  void setMasterEnabled(bool enabled) {
    state = state.copyWith(masterEnabled: enabled);
  }

  void setRemind15Min(bool enabled) {
    state = state.copyWith(remind15Min: enabled);
  }

  void setRemind10Min(bool enabled) {
    state = state.copyWith(remind10Min: enabled);
  }

  void setMorningBriefing(bool enabled) {
    state = state.copyWith(morningBriefing: enabled);
  }

  void setSoundAndVibrate(bool enabled) {
    state = state.copyWith(soundAndVibrate: enabled);
  }
}

final notificationPreferencesProvider =
    NotifierProvider<NotificationPreferencesNotifier, NotificationPreferences>(
      () {
        return NotificationPreferencesNotifier();
      },
    );

// Notification Service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  final StreamController<String?> onNotificationClick =
      StreamController<String?>.broadcast();

  final Set<String> _seenNotificationIds = {};
  bool _seenIdsLoaded = false;

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));
    } catch (_) {
      // Fallback
    }

    AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await _notificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint('Notification clicked: ${response.payload}');
        onNotificationClick.add(response.payload);
      },
    );

    final androidPlugin = _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.requestNotificationsPermission();

    final exactAllowed = await androidPlugin?.canScheduleExactNotifications();
    if (exactAllowed != null && !exactAllowed) {
      await androidPlugin?.requestExactAlarmsPermission();
    }

    AndroidNotificationChannel channel = AndroidNotificationChannel(
      'campusly_class_reminders',
      'Class Reminders (10 & 15 mins)',
      description: 'System notifications sent before every lecture starts',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    AndroidNotificationChannel systemChannel = AndroidNotificationChannel(
      'campusly_system_notifications',
      'Campus Notifications & Alerts',
      description: 'Real-time campus notices, circulars, and reminders',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );

    AndroidNotificationChannel chatChannel = AndroidNotificationChannel(
      'campusly_chat_messages',
      'Chat Messages',
      description: 'Direct messages and group chats',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await androidPlugin?.createNotificationChannel(channel);
    await androidPlugin?.createNotificationChannel(systemChannel);
    await androidPlugin?.createNotificationChannel(chatChannel);

    await _loadSeenIds();
    _initialized = true;
    debugPrint('NotificationService initialized successfully.');
  }

  Future<void> _loadSeenIds() async {
    if (_seenIdsLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('seen_system_notification_ids') ?? [];
      _seenNotificationIds.addAll(list);
      _seenIdsLoaded = true;
    } catch (_) {}
  }

  Future<void> _saveSeenId(String id) async {
    _seenNotificationIds.add(id);
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _seenNotificationIds.toList();
      if (list.length > 500) {
        list.removeRange(0, list.length - 500);
      }
      await prefs.setStringList('seen_system_notification_ids', list);
    } catch (_) {}
  }

  Future<bool> hasSeenNotification(String id) async {
    if (!_seenIdsLoaded) {
      await _loadSeenIds();
    }
    return _seenNotificationIds.contains(id);
  }

  Future<void> markSeenNotification(String id) async {
    if (!_seenIdsLoaded) {
      await _loadSeenIds();
    }
    if (!_seenNotificationIds.contains(id)) {
      await _saveSeenId(id);
    }
  }

  Future<void> showSystemNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    bool isEmergency = false,
  }) async {
    await init();
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'campusly_system_notifications',
          'Campus Notifications & Alerts',
          channelDescription:
              'Real-time campus notices, circulars, and reminders',
          importance: isEmergency ? Importance.max : Importance.high,
          priority: isEmergency ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          color: isEmergency
              ? Color(0xFFEF4444)
              : Color(0xFF4F46E5),
          styleInformation: BigTextStyleInformation(body, contentTitle: title),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: isEmergency
              ? InterruptionLevel.critical
              : InterruptionLevel.active,
        ),
      ),
      payload: payload,
    );
  }

  Future<void> showChatMessageNotification({
    required int id,
    required String senderName,
    required String message,
    required String chatId,
    bool isSilent = false,
  }) async {
    await init();

    final groupKey = 'chat_$chatId';

    // Show the actual message notification
    await _notificationsPlugin.show(
      id: id,
      title: senderName,
      body: message,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'campusly_chat_messages',
          'Chat Messages',
          channelDescription: 'Direct messages and group chats',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          playSound: !isSilent,
          enableVibration: !isSilent,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4F46E5),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: !isSilent,
          threadIdentifier: groupKey,
        ),
      ),
      payload: 'chat_$chatId',
    );

    // Show group summary (required for Android 7.0+)
    await _notificationsPlugin.show(
      id: id * 1000,
      title: 'Messages',
      body: 'New messages',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'campusly_chat_messages',
          'Chat Messages',
          channelDescription: 'Direct messages and group chats',
          importance: Importance.high,
          priority: Priority.high,
          groupKey: groupKey,
          setAsGroupSummary: true,
          playSound: false,
          enableVibration: false,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFF4F46E5),
        ),
        iOS: DarwinNotificationDetails(threadIdentifier: groupKey),
      ),
    );
  }

  Future<void> scheduleClassReminders(
    List<TimetableItem> weeklyItems,
    NotificationPreferences prefs,
  ) async {
    if (!prefs.masterEnabled) {
      await cancelAllReminders();
      return;
    }

    await cancelAllReminders();

    final now = DateTime.now();
    int scheduledCount = 0;

    for (final item in weeklyItems) {
      if (item.isBreak || item.category.toLowerCase() == 'break') continue;

      final targetWeekday = _dayStringToWeekday(item.dayOfWeek);
      if (targetWeekday == null) continue;

      int daysUntil = (targetWeekday - now.weekday) % 7;
      DateTime classDateTime = DateTime(
        now.year,
        now.month,
        now.day + daysUntil,
        item.startHour,
        item.startMinute,
      );

      if (daysUntil == 0 && classDateTime.isBefore(now)) {
        classDateTime = classDateTime.add(Duration(days: 7));
      }

      if (prefs.remind15Min) {
        final remind15Time = classDateTime.subtract(
          Duration(minutes: 15),
        );
        if (remind15Time.isAfter(now)) {
          final int notificationId = (item.id.hashCode.abs() % 100000) * 10 + 1;
          await _scheduleZoned(
            id: notificationId,
            title: '📚 Class in 15 mins: ${item.title}',
            body:
                '${item.room} · ${item.instructor}\nGet your materials ready!',
            scheduledTime: remind15Time,
            payload: 'class_${item.id}',
          );
          scheduledCount++;
        }
      }

      if (prefs.remind10Min) {
        final remind10Time = classDateTime.subtract(
          Duration(minutes: 10),
        );
        if (remind10Time.isAfter(now)) {
          final int notificationId = (item.id.hashCode.abs() % 100000) * 10 + 2;
          await _scheduleZoned(
            id: notificationId,
            title: '⏰ 10 Minutes to ${item.title}!',
            body:
                'Head to ${item.room} now. Lecture starts at ${_formatTime(item.startHour, item.startMinute)}!',
            scheduledTime: remind10Time,
            payload: 'class_${item.id}',
          );
          scheduledCount++;
        }
      }
    }

    debugPrint(
      'Scheduled $scheduledCount system notifications for upcoming classes.',
    );
  }

  Future<void> _scheduleZoned({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload,
  }) async {
    try {
      final tz.TZDateTime tzScheduledTime = tz.TZDateTime.from(
        scheduledTime,
        tz.local,
      );

      final androidPlugin = _notificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      bool canExact = true;
      if (androidPlugin != null) {
        final exactAllowed = await androidPlugin
            .canScheduleExactNotifications();
        if (exactAllowed != null && !exactAllowed) {
          canExact = false;
        }
      }

      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzScheduledTime,
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            'campusly_class_reminders',
            'Class Reminders (10 & 15 mins)',
            channelDescription:
                'System notifications sent before every lecture starts',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: canExact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } catch (e) {
      debugPrint('Error scheduling notification id $id: $e');
    }
  }

  Future<void> showTestNotification({required int minutesBefore}) async {
    await init();
    const int testId = 999999;
    final String title = minutesBefore == 10
        ? '⏰ 10 Minutes to Database Management!'
        : '📚 Class in 15 mins: Database Management';
    final String body = minutesBefore == 10
        ? 'Head to Room ANEW101-A now. Lecture starts at 10:00 AM!'
        : 'Room ANEW101-A · Rajammal K\nGet your lab notes ready!';

    await _notificationsPlugin.show(
      id: testId + minutesBefore,
      title: title,
      body: body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'campusly_class_reminders',
          'Class Reminders (10 & 15 mins)',
          channelDescription:
              'System notifications sent before every lecture starts',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: 'test_reminder',
    );
  }

  Future<void> cancelAllReminders() async {
    await _notificationsPlugin.cancelAll();
    debugPrint('All class reminders cancelled.');
  }

  int? _dayStringToWeekday(String day) {
    switch (day.trim().toLowerCase()) {
      case 'mon':
        return DateTime.monday;
      case 'tue':
        return DateTime.tuesday;
      case 'wed':
        return DateTime.wednesday;
      case 'thu':
        return DateTime.thursday;
      case 'fri':
        return DateTime.friday;
      case 'sat':
        return DateTime.saturday;
      case 'sun':
        return DateTime.sunday;
      default:
        return null;
    }
  }

  String _formatTime(int hour, int minute) {
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    final String displayMinute = minute.toString().padLeft(2, '0');
    return '$displayHour:$displayMinute $period';
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
