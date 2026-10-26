import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/water.dart';

/// Daily water reminders. Scheduled notifications are Android-only; on other
/// platforms every call is a no-op and the in-app nudge is used instead.
class NotificationService {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static const _firstWaterId = 1000;
  static const _maxWaterIds = 24;
  static bool _ready = false;

  static bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  static Future<void> init() async {
    if (!isSupported || _ready) return;
    tz_data.initializeTimeZones();
    final zone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(zone.identifier));
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
    );
    _ready = true;
  }

  /// Returns false if the user denied notification permission.
  static Future<bool> requestPermission() async {
    if (!isSupported) return false;
    await init();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    return await android?.requestNotificationsPermission() ?? false;
  }

  static Future<void> scheduleWaterReminders(WaterSettings settings) async {
    if (!isSupported) return;
    await init();
    for (var i = 0; i < _maxWaterIds; i++) {
      await _plugin.cancel(id: _firstWaterId + i);
    }
    if (!settings.remindersEnabled) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'water_reminders',
        'Nhắc uống nước',
        channelDescription: 'Nhắc bạn uống nước đều đặn trong ngày',
      ),
    );
    final now = tz.TZDateTime.now(tz.local);
    final hours = settings.reminderHours.take(_maxWaterIds).toList();
    for (var i = 0; i < hours.length; i++) {
      var at = tz.TZDateTime(tz.local, now.year, now.month, now.day, hours[i]);
      if (!at.isAfter(now)) at = at.add(const Duration(days: 1));
      await _plugin.zonedSchedule(
        id: _firstWaterId + i,
        title: 'Đến giờ uống nước rồi 💧',
        body: 'Uống một ly ${settings.glassMl} ml để cơ thể luôn đủ nước nhé!',
        scheduledDate: at,
        notificationDetails: details,
        // Reminders don't need to-the-second precision, so avoid the exact
        // alarm permission.
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }
}
