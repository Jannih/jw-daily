import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/settings/stories/settings_story.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

const _notificationId = 0;
const _channelId = 'daily_reading_reminder';

final notificationsServiceProvider = Provider<NotificationsService>((ref) {
  final service = NotificationsService(ref);
  service.start();

  return service;
}, name: 'notificationsServiceProvider');

class NotificationsService {
  NotificationsService(this.ref);

  final Ref ref;
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;

  void start() {
    ref.listen(settingsProvider, (previous, next) {
      next.whenData((settings) =>
          _apply(settings.pushNotificationsEnabled, settings.notificationTime));
    });

    // ref.listen only fires on changes, so apply whatever is already stored.
    final settings = ref.read(settingsProvider).valueOrNull;
    if (settings != null) {
      _apply(settings.pushNotificationsEnabled, settings.notificationTime);
    }
  }

  Future<void> _apply(bool enabled, TimeOfDay time) async {
    if (enabled) {
      await scheduleNotification(time);
    } else {
      await cancelNotification();
    }
  }

  /// Runs at most once; every entry point awaits it so the plugin is never used
  /// before [FlutterLocalNotificationsPlugin.initialize] has completed.
  Future<void> _init() => _initialization ??= _doInit();

  Future<void> _doInit() async {
    tz.initializeTimeZones();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      ),
    );

    await _notifications.initialize(initializationSettings);
  }

  /// Android 13 (API 33) and newer require the notification permission to be
  /// granted at runtime — without it every scheduled notification is dropped
  /// silently. Returns whether notifications may be posted.
  Future<bool> _ensurePermission() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;

    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return true;

    return await android.requestNotificationsPermission() ?? false;
  }

  Future<void> scheduleNotification(TimeOfDay time) async {
    await _init();
    if (!await _ensurePermission()) {
      debugPrint('Notification permission denied, nothing was scheduled.');
      return;
    }
    await _notifications.cancel(_notificationId);

    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    final loc = lookupAppLocalizations(
        _resolveLocale(AppLocalizations.supportedLocales));

    await _notifications.zonedSchedule(
      _notificationId,
      loc.notificationDailyReadingTitle,
      loc.notificationDailyReadingBody,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          loc.notificationChannelName,
          channelDescription: loc.notificationChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(
          sound: 'default',
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification() async {
    await _init();
    await _notifications.cancel(_notificationId);
  }

  /// The service has no BuildContext, so the device locale is matched against
  /// the supported ones by language code, falling back to the first supported
  /// locale.
  static Locale _resolveLocale(List<Locale> supported) {
    for (final locale in PlatformDispatcher.instance.locales) {
      for (final candidate in supported) {
        if (candidate.languageCode == locale.languageCode) return candidate;
      }
    }

    return supported.first;
  }
}
