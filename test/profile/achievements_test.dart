import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jw_daily/src/plans/entities/plan.dart';
import 'package:jw_daily/src/profile/achievements.dart';
import 'package:jw_daily/src/schedules/entities/schedule.dart';
import 'package:shared_preferences/shared_preferences.dart';

Section _section(int bookIndex) => Section(
      bookIndex: bookIndex,
      chapter: 1,
      endChapter: 1,
      ref: '1',
      startIndex: 0,
      endIndex: 0,
      url: '',
      events: const [],
      locations: const [],
      bibleVerses: const [],
      videos: const [],
    );

/// Three days with two sections each: book 0 spans day 0, book 1 spans day 1
/// and book 2 spans day 2.
Schedule _schedule() => Schedule([
      for (var book = 0; book < 3; book++)
        Day([_section(book), _section(book)]),
    ]);

Plan _plan(Bookmark bookmark) => Plan(
      id: 'plan',
      scheduleKey: const ScheduleKey(
          type: ScheduleType.chronological,
          duration: ScheduleDuration.y1,
          version: '1.0'),
      bookmark: bookmark,
      withTargetDate: false,
      showEvents: false,
      showLocations: false,
      showBibleVerses: false,
      showVideos: false,
    );

/// Rebuilds the notifier from what it persisted, which is how the state is
/// restored on the next app start.
Future<AchievementsNotifier> _reload() async {
  final notifier = AchievementsNotifier();
  await notifier.load();

  return notifier;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('Streaks', () {
    test('Start at one and do not grow within the same day', () async {
      final notifier = AchievementsNotifier();
      final plan = _plan(const Bookmark(dayIndex: 0, sectionIndex: 0));

      notifier.registerReading(plan, _schedule());
      expect(notifier.state.currentStreak, 1);

      notifier.registerReading(plan, _schedule());
      expect(notifier.state.currentStreak, 1);
      expect(notifier.state.byId(AchievementId.streak3).isCompleted, false);
    });

    test('Grow on consecutive days and unlock the streak achievements',
        () async {
      final notifier = AchievementsNotifier();
      final plan = _plan(const Bookmark(dayIndex: 0, sectionIndex: 0));
      final today = DateTime.now();

      // Pretend the previous readings happened on the two preceding days.
      notifier.state = notifier.state.copyWith(
        firstReadDate: today.subtract(const Duration(days: 2)),
        lastReadDate: today.subtract(const Duration(days: 1)),
        currentStreak: 2,
      );

      notifier.registerReading(plan, _schedule());

      expect(notifier.state.currentStreak, 3);
      expect(notifier.state.byId(AchievementId.streak3).isCompleted, true);
      expect(notifier.state.byId(AchievementId.streak7).isCompleted, false);
    });

    test('Reset after a missed day', () async {
      final notifier = AchievementsNotifier();
      final plan = _plan(const Bookmark(dayIndex: 0, sectionIndex: 0));

      notifier.state = notifier.state.copyWith(
        lastReadDate: DateTime.now().subtract(const Duration(days: 3)),
        currentStreak: 9,
      );

      notifier.registerReading(plan, _schedule());

      expect(notifier.state.currentStreak, 1);
    });
  });

  group('Milestones', () {
    test('Count the sections that are at or before the bookmark', () {
      final notifier = AchievementsNotifier();

      // Day 0 fully read, day 1 up to its first section — five sections.
      notifier.recompute(
          _plan(const Bookmark(dayIndex: 2, sectionIndex: 0)), _schedule());

      expect(notifier.state.byId(AchievementId.firstChapter).isCompleted, true);
      expect(notifier.state.byId(AchievementId.chapters5).isCompleted, true);
    });

    test('Count a book only once all of its sections are read', () {
      final notifier = AchievementsNotifier();

      // Half way through book 0 — nothing completed yet.
      notifier.recompute(
          _plan(const Bookmark(dayIndex: 0, sectionIndex: 0)), _schedule());
      expect(notifier.state.byId(AchievementId.firstBook).isCompleted, false);

      // Book 0 finished.
      notifier.recompute(
          _plan(const Bookmark(dayIndex: 0, sectionIndex: 1)), _schedule());
      expect(notifier.state.byId(AchievementId.firstBook).isCompleted, true);
    });

    test('Unlock the month achievements from the reading duration', () {
      final notifier = AchievementsNotifier();
      final now = DateTime.now();

      notifier.state = notifier.state.copyWith(
        firstReadDate: DateTime(now.year, now.month - 3, now.day),
        lastReadDate: now,
      );
      notifier.recompute(
          _plan(const Bookmark(dayIndex: 0, sectionIndex: 0)), _schedule());

      expect(notifier.state.byId(AchievementId.firstMonth).isCompleted, true);
      expect(notifier.state.byId(AchievementId.months3).isCompleted, true);
    });

    test('Do not throw without a schedule', () {
      final notifier = AchievementsNotifier();

      notifier.recompute(
          _plan(const Bookmark(dayIndex: 5, sectionIndex: 0)), null);

      expect(notifier.state.byId(AchievementId.firstBook).isCompleted, false);
    });

    test('Never revoke an achievement that was already earned', () {
      final notifier = AchievementsNotifier();

      notifier.recompute(
          _plan(const Bookmark(dayIndex: 2, sectionIndex: 1)), _schedule());
      expect(notifier.state.byId(AchievementId.firstBook).isCompleted, true);

      // Marking everything as unread again must not take the achievement away.
      notifier.recompute(
          _plan(const Bookmark(dayIndex: 0, sectionIndex: -1)), _schedule());
      expect(notifier.state.byId(AchievementId.firstBook).isCompleted, true);
    });
  });

  group('Daily reward', () {
    test('Requires a reading on the current day', () {
      final notifier = AchievementsNotifier();
      final daily = notifier.state.byId(AchievementId.dailyReading);

      expect(daily.canClaimDailyReward(false), false);
      expect(daily.canClaimDailyReward(true), true);
    });

    test('Can only be claimed once per day', () {
      final notifier = AchievementsNotifier();

      notifier.claimDailyReward();

      expect(
          notifier.state
              .byId(AchievementId.dailyReading)
              .canClaimDailyReward(true),
          false);
    });
  });

  group('Persistence', () {
    test('Restores the streak and the earned achievements', () async {
      final notifier = AchievementsNotifier();
      notifier.registerReading(
          _plan(const Bookmark(dayIndex: 0, sectionIndex: 1)), _schedule());
      // Give the fire-and-forget write a chance to complete.
      await Future<void>.delayed(Duration.zero);

      final restored = await _reload();

      expect(restored.state.currentStreak, 1);
      expect(restored.state.byId(AchievementId.firstBook).isCompleted, true);
      expect(restored.state.lastReadDate, isNotNull);
    });

    test('Migrates the previous format keyed by the German title', () async {
      SharedPreferences.setMockInitialValues({
        'achievements': jsonEncode([
          {
            'title': 'Erste Bibellesung',
            'isCompleted': true,
            'isRewardClaimed': true,
            'lastRewardClaimed': null,
          },
          {
            'title': '5 Kapitel abgeschlossen',
            'isCompleted': true,
            'isRewardClaimed': false,
            'lastRewardClaimed': null,
          },
        ]),
      });

      final restored = await _reload();

      expect(restored.state.byId(AchievementId.firstReading).isCompleted, true);
      expect(restored.state.byId(AchievementId.firstReading).isRewardClaimed,
          true);
      expect(restored.state.byId(AchievementId.chapters5).isCompleted, true);
      expect(
          restored.state.byId(AchievementId.chapters5).isRewardClaimed, false);
    });

    test('Keeps achievements that the stored data does not know yet', () async {
      SharedPreferences.setMockInitialValues({
        'achievements': jsonEncode({
          'currentStreak': 4,
          'achievements': [
            {
              'id': 'firstReading',
              'isCompleted': true,
              'isRewardClaimed': false,
              'lastRewardClaimed': null,
            },
          ],
        }),
      });

      final restored = await _reload();

      expect(restored.state.achievements.length, AchievementId.values.length);
      expect(restored.state.currentStreak, 4);
      expect(restored.state.byId(AchievementId.months3).isCompleted, false);
    });
  });
}
