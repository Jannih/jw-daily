import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/entities/incomplete_notifier.dart';

final settingsProvider = AsyncNotifierProvider<SettingsNotifier, Settings>(
    SettingsNotifier.new,
    name: 'settingsProvider');

class SettingsNotifier extends IncompleteNotifier<Settings> {
  Future<void> updateSettings({
    ThemeMode? themeMode,
    String? seenWhatsNewVersion,
    bool? pushNotificationsEnabled,
    TimeOfDay? notificationTime
  }) async {
    state = AsyncValue.data(state.asData?.value == null
        ? Settings(
            themeMode: themeMode ?? ThemeMode.system,
            seenWhatsNewVersion: seenWhatsNewVersion,
            pushNotificationsEnabled: pushNotificationsEnabled ?? false,
            notificationTime: notificationTime ?? const TimeOfDay(hour: 20, minute: 0))
        : state.asData!.value.copyWith(
            themeMode: themeMode,
            seenWhatsNewVersion: seenWhatsNewVersion,
            pushNotificationsEnabled: pushNotificationsEnabled ?? state.asData!.value.pushNotificationsEnabled,
            notificationTime: notificationTime ?? state.asData!.value.notificationTime));
  }

  void updateThemeMode(ThemeMode themeMode) =>
      updateSettings(themeMode: themeMode);

  void updateSeenWhatsNewVersion(String seenWhatsNewVersion) =>
      updateSettings(seenWhatsNewVersion: seenWhatsNewVersion);

  void updatePushNotifications(bool enabled) =>
      updateSettings(pushNotificationsEnabled: enabled);

  void updateNotificationTime(TimeOfDay time) =>
      updateSettings(notificationTime: time);
}

@immutable
class Settings extends Equatable {
  const Settings({
    required this.themeMode,
    this.seenWhatsNewVersion,
    this.pushNotificationsEnabled = false,
    this.notificationTime = const TimeOfDay(hour: 20, minute: 0),
  });

  final ThemeMode themeMode;
  final String? seenWhatsNewVersion;
  final bool pushNotificationsEnabled;
  final TimeOfDay notificationTime;

  Settings copyWith({
    ThemeMode? themeMode,
    String? seenWhatsNewVersion,
    bool? pushNotificationsEnabled,
    TimeOfDay? notificationTime,
  }) =>
      Settings(
        themeMode: themeMode ?? this.themeMode,
        seenWhatsNewVersion: seenWhatsNewVersion ?? this.seenWhatsNewVersion,
        pushNotificationsEnabled: pushNotificationsEnabled ?? this.pushNotificationsEnabled,
        notificationTime: notificationTime ?? this.notificationTime,
      );

  @override
  List<Object?> get props => [themeMode, seenWhatsNewVersion, pushNotificationsEnabled, notificationTime];
}
