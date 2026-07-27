import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/base/repositories/shared_preferences_repository.dart';
import 'package:jw_daily/src/bible_languages/repositories/bible_languages_repository.dart';
import 'package:jw_daily/src/logs/repositories/provider_logger.dart';
import 'package:jw_daily/src/plans/repositories/plans_repository.dart';
import 'package:jw_daily/src/schedules/repositories/events_repository.dart';
import 'package:jw_daily/src/schedules/repositories/locations_repository.dart';
import 'package:jw_daily/src/schedules/repositories/bible_verses_repository.dart';
import 'package:jw_daily/src/schedules/repositories/videos_repository.dart';
import 'package:jw_daily/src/schedules/repositories/schedules_repository.dart';
import 'package:jw_daily/src/settings/repositories/settings_repository.dart';
import 'package:jw_daily/src/notifications/notifications_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'src/app.dart';

Future<UncontrolledProviderScope> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final sharedPreferences = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    observers: [ProviderLogger()],
    overrides: [
      sharedPreferencesRepositoryProvider.overrideWithValue(sharedPreferences),
    ],
  );
  container.read(plansRepositoryProvider).load();
  container.read(locationsRepositoryProvider);
  container.read(eventsRepositoryProvider);
  container.read(bibleVersesRepositoryProvider);
  container.read(videosRepositoryProvider);
  container.read(schedulesRepositoryProvider);
  container.read(bibleLanguagesRepositoryProvider);
  container.read(settingsRepositoryProvider);
  container.read(notificationsServiceProvider);

  final uncontrolledProviderScope = UncontrolledProviderScope(
    container: container,
    child: const App(),
  );

  runApp(uncontrolledProviderScope);

  return uncontrolledProviderScope;
}
