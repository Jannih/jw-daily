import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:nwt_reading/src/settings/stories/settings_story.dart';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  return NotificationsService(ref);
}, name: 'notificationsServiceProvider');

class NotificationsService {
  NotificationsService(this.ref) {
    _init();
    // Höre auf Änderungen der Einstellungen
    ref.listen(settingsProvider, (previous, next) {
      next.whenData((settings) {
        if (settings.pushNotificationsEnabled) {
          scheduleNotification(settings.notificationTime);
        } else {
          cancelNotification();
        }
      });
    });
  }

  final Ref ref;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  Future<void> _init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initializationSettings);
  }

  Future<void> scheduleNotification(TimeOfDay time) async {
    await cancelNotification(); // Lösche bestehende Benachrichtigung

    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    // Wenn die Zeit für heute bereits vorbei ist, plane für morgen
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final location = tz.local;
    final scheduledTzDateTime = tz.TZDateTime.from(scheduledDate, location);


    await _notifications.zonedSchedule(
      0, // Notification ID
      'Tägliche Lesung', // Titel
      'Vergiss nicht deine tägliche Bibellesung!', // Nachricht
      scheduledTzDateTime,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_reading_reminder',
          'Tägliche Lesung',
          channelDescription: 'Erinnerungen an die tägliche Bibellesung',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Wiederholt täglich zur gleichen Zeit
    );
  }

  Future<void> cancelNotification() async {
    await _notifications.cancel(0);
  }
}