import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/localization/app_localizations_getter.dart';
import 'package:nwt_reading/src/settings/stories/settings_story.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode =
        ref.watch(settingsProvider).value?.themeMode ?? ThemeMode.system;
    final pushNotificationsEnabled = ref.watch(settingsProvider).value?.pushNotificationsEnabled ?? false;
    final notificationTime = ref.watch(settingsProvider).value?.notificationTime ?? const TimeOfDay(hour: 20, minute: 0);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.loc.settingsPageTitle),
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SegmentedButton<ThemeMode>(
            segments: <ButtonSegment<ThemeMode>>[
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.system,
                  label: Text(context.loc.settingsPageSystemLabel),
                  icon: const Icon(Icons.auto_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.light,
                  label: Text(context.loc.settingsPageLightLabel),
                  icon: const Icon(Icons.light_mode)),
              ButtonSegment<ThemeMode>(
                  value: ThemeMode.dark,
                  label: Text(context.loc.settingsPageDarkLabel),
                  icon: const Icon(Icons.dark_mode)),
            ],
            selected: {themeMode},
            onSelectionChanged: (Set<ThemeMode> newSelection) => ref
                .read(settingsProvider.notifier)
                .updateThemeMode(newSelection.single),
          ),
        ),

        const Divider(),

        SwitchListTile(
          title: Text(context.loc.settingsPageDailyRemindersTitle),
          subtitle: Text(context.loc.settingsPageDailyRemindersSubtitle),
          value: pushNotificationsEnabled,
          onChanged: (bool value) {
            ref.read(settingsProvider.notifier).updatePushNotifications(value);
          },
        ),

        if (pushNotificationsEnabled)
          ListTile(
            title: Text(context.loc.settingsPageReminderTimeTitle),
            subtitle: Text(notificationTime.format(context)),
            trailing: const Icon(Icons.access_time),
            onTap: () async {
              final TimeOfDay? newTime = await showTimePicker(
                context: context,
                initialTime: notificationTime,
              );
              if (newTime != null) {
                ref.read(settingsProvider.notifier).updateNotificationTime(newTime);
              }
            },
          ),

        const Divider(),

        ListTile(
            subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<PackageInfo>(
              future: PackageInfo.fromPlatform(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }
                final version = snapshot.data?.version ?? '-';
                return Text(
                  '${context.loc.settingsPageVersionLabel}: $version',
                  key: const Key('version'),
                );
              },
            ),
            Text(
              '${context.loc.settingsPageCopyrightLabel} © 2024 searchwork.org',
              style: const TextStyle(height: 3),
              key: const Key('copyright'),
            ),
          ],
        )),
      ]),
    );
  }
}
