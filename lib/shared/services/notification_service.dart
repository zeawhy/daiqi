import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static void Function(String listId)? onNotificationTap;

  /// Initialize local notification plugin and timezones (Section 7.5 & 10)
  static Future<void> init({void Function(String listId)? onSelectNotification}) async {
    if (_initialized) return;
    _initialized = true;
    onNotificationTap = onSelectNotification;

    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (e) {
      debugPrint('NotificationService init timezones error: $e');
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notificationsPlugin.initialize(
        settings: initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            onNotificationTap?.call(payload);
          }
        },
      );

      // Check if launched from a notification
      final launchDetails =
          await _notificationsPlugin.getNotificationAppLaunchDetails();
      if (launchDetails != null && launchDetails.didNotificationLaunchApp) {
        final payload = launchDetails.notificationResponse?.payload;
        if (payload != null && payload.isNotEmpty) {
          onNotificationTap?.call(payload);
        }
      }
    } catch (e) {
      debugPrint('NotificationService init plugin error: $e');
    }
  }

  /// Request notification permission (Android 13+ and iOS)
  static Future<bool> requestPermission() async {
    try {
      if (kIsWeb) return false;

      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final granted = await androidImpl?.requestNotificationsPermission();
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
    }
    return false;
  }

  /// Check whether notification permission is granted
  static Future<bool> isPermissionGranted() async {
    try {
      if (kIsWeb) return false;
      if (Platform.isAndroid) {
        final androidImpl = _notificationsPlugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
        final areEnabled = await androidImpl?.areNotificationsEnabled();
        return areEnabled ?? false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Unique notification ID for a checklist on a specific weekday
  static int _getNotificationId(String listId, int weekday) {
    return (listId.hashCode ^ weekday).abs() % 100000;
  }

  /// Schedule repeating weekly notification for a checklist (Section 7.5)
  /// Title: "⏰ 快出门了，装包啦 🎒"
  /// Body: "{清单名}还有 {N} 件没装"
  static Future<void> scheduleChecklistReminder({
    required String listId,
    required String listName,
    required int itemCount,
    required String reminderTime, // "HH:mm"
    required List<int> reminderWeekdays, // 1-7 (1 = Monday)
  }) async {
    try {
      // First cancel existing notifications for this list
      await cancelChecklistReminders(listId);

      final parts = reminderTime.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 30;

      const androidDetails = AndroidNotificationDetails(
        'daiqi_checklist_reminders',
        '带齐了出门提醒',
        channelDescription: '在出门前提醒您检查物品是否带齐',
        importance: Importance.high,
        priority: Priority.high,
      );
      const darwinDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      final title = '⏰ 快出门了，装包啦 🎒';
      final body = '$listName还有 $itemCount 件没装';

      for (final weekday in reminderWeekdays) {
        final id = _getNotificationId(listId, weekday);
        final scheduledDate = _nextInstanceOfWeekdayTime(weekday, hour, minute);

        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: scheduledDate,
          notificationDetails: notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: listId,
        );
      }
    } catch (e) {
      debugPrint('NotificationService scheduleChecklistReminder error: $e');
    }
  }

  static tz.TZDateTime _nextInstanceOfWeekdayTime(int weekday, int hour, int minute) {
    try {
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Shanghai'));
    } catch (_) {}
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    while (scheduledDate.weekday != weekday || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  /// Cancel all scheduled reminders for a checklist
  static Future<void> cancelChecklistReminders(String listId) async {
    try {
      for (int day = 1; day <= 7; day++) {
        final id = _getNotificationId(listId, day);
        await _notificationsPlugin.cancel(id: id);
      }
    } catch (e) {
      debugPrint('NotificationService cancelChecklistReminders error: $e');
    }
  }
}
