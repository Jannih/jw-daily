import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/repositories/shared_preferences_repository.dart';
import 'package:nwt_reading/src/settings/stories/settings_story.dart';

const _themeModePreferenceKey = 'themeModeSetting';
const _seenWhatsNewVersionPreferenceKey = 'seenWhatsNewVersionSetting';
const _pushNotificationsEnabledKey = 'pushNotificationsEnabled';
const _notificationTimeHourKey = 'notificationTimeHour';
const _notificationTimeMinuteKey = 'notificationTimeMinute';

final settingsRepositoryProvider = Provider<void>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesRepositoryProvider);
  final themeModeSerialized =
      sharedPreferences.getInt(_themeModePreferenceKey) ??
          ThemeMode.system.index;
  final seenWhatsNewVersion =
      sharedPreferences.getString(_seenWhatsNewVersionPreferenceKey);
  final pushNotificationsEnabled = sharedPreferences.getBool(_pushNotificationsEnabledKey) ?? false;
  final notificationTimeHour = sharedPreferences.getInt(_notificationTimeHourKey) ?? 20;
  final notificationTimeMinute = sharedPreferences.getInt(_notificationTimeMinuteKey) ?? 0;

  ref.read(settingsProvider.notifier).init(Settings(
    themeMode: ThemeMode.values[themeModeSerialized],
    seenWhatsNewVersion: seenWhatsNewVersion,
    pushNotificationsEnabled: pushNotificationsEnabled,
    notificationTime: TimeOfDay(hour: notificationTimeHour, minute: notificationTimeMinute),
  ));

  ref.listen(settingsProvider, (previousSettings, currentSettings) =>
    currentSettings.whenData((settings) {
      sharedPreferences.setInt(_themeModePreferenceKey, settings.themeMode.index);
      if (settings.seenWhatsNewVersion != null) {
        sharedPreferences.setString(_seenWhatsNewVersionPreferenceKey, settings.seenWhatsNewVersion!);
      }
      sharedPreferences.setBool(_pushNotificationsEnabledKey, settings.pushNotificationsEnabled);
      sharedPreferences.setInt(_notificationTimeHourKey, settings.notificationTime.hour);
      sharedPreferences.setInt(_notificationTimeMinuteKey, settings.notificationTime.minute);
    }));
}, name: 'settingsRepositoryProvider');
