import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/plans/entities/plan.dart';
import 'package:jw_daily/src/schedules/entities/schedule.dart';
import 'package:jw_daily/src/utils/date_utils.dart' as app_date_utils;
import 'package:shared_preferences/shared_preferences.dart';

const _preferenceKey = 'achievements';

/// Stable identifiers for the achievements. These are persisted, so the enum
/// names must not be changed — the displayed title comes from the localization
/// and may change freely.
enum AchievementId {
  firstReading,
  dailyReading,
  streak3,
  streak7,
  streak10,
  firstChapter,
  chapters5,
  firstBook,
  books5,
  firstMonth,
  months3,
}

const Map<AchievementId, IconData> achievementIcons = {
  AchievementId.firstReading: Icons.book,
  AchievementId.dailyReading: Icons.auto_stories,
  AchievementId.streak3: Icons.calendar_today,
  AchievementId.streak7: Icons.calendar_view_week,
  AchievementId.streak10: Icons.calendar_view_month,
  AchievementId.firstChapter: Icons.check_circle,
  AchievementId.chapters5: Icons.check_circle_outline,
  AchievementId.firstBook: Icons.library_books,
  AchievementId.books5: Icons.library_books_outlined,
  AchievementId.firstMonth: Icons.date_range,
  AchievementId.months3: Icons.event,
};

const Map<AchievementId, int> achievementXP = {
  AchievementId.firstReading: 50,
  AchievementId.dailyReading: 10,
  AchievementId.streak3: 75,
  AchievementId.streak7: 150,
  AchievementId.streak10: 250,
  AchievementId.firstChapter: 50,
  AchievementId.chapters5: 150,
  AchievementId.firstBook: 200,
  AchievementId.books5: 300,
  AchievementId.firstMonth: 250,
  AchievementId.months3: 400,
};

/// Titles used before the achievements were keyed by [AchievementId]. Kept so
/// that existing installations do not lose their progress on upgrade.
const Map<String, AchievementId> _legacyTitleIds = {
  'Erste Bibellesung': AchievementId.firstReading,
  'Tägliche Bibellesung': AchievementId.dailyReading,
  '3 Tage hintereinander gelesen': AchievementId.streak3,
  '7 Tage hintereinander gelesen': AchievementId.streak7,
  '10 Tage hintereinander gelesen': AchievementId.streak10,
  'Erstes Kapitel abgeschlossen': AchievementId.firstChapter,
  '5 Kapitel abgeschlossen': AchievementId.chapters5,
  'Erstes Buch abgeschlossen': AchievementId.firstBook,
  '5 Bücher abgeschlossen': AchievementId.books5,
  'Erster Monat abgeschlossen': AchievementId.firstMonth,
  '3 Monate abgeschlossen': AchievementId.months3,
};

int getRequiredXPForLevel(int level) => (100 * pow(1.2, level - 1)).round();

@immutable
class Achievement {
  const Achievement(
    this.id, {
    this.isCompleted = false,
    this.isRewardClaimed = false,
    this.lastRewardClaimed,
  });

  final AchievementId id;
  final bool isCompleted;
  final bool isRewardClaimed;
  final DateTime? lastRewardClaimed;

  IconData get icon => achievementIcons[id]!;

  Achievement copyWith({
    bool? isCompleted,
    bool? isRewardClaimed,
    DateTime? lastRewardClaimed,
  }) =>
      Achievement(
        id,
        isCompleted: isCompleted ?? this.isCompleted,
        isRewardClaimed: isRewardClaimed ?? this.isRewardClaimed,
        lastRewardClaimed: lastRewardClaimed ?? this.lastRewardClaimed,
      );

  /// The daily achievement resets every day: it can be claimed once per day and
  /// only when a section was actually read on that day.
  bool canClaimDailyReward(bool hasReadToday) =>
      id == AchievementId.dailyReading &&
      hasReadToday &&
      !app_date_utils.DateUtils.isSameDay(lastRewardClaimed, DateTime.now());

  bool get canClaimReward => isCompleted && !isRewardClaimed;
}

@immutable
class AchievementsState {
  const AchievementsState({
    required this.achievements,
    this.firstReadDate,
    this.lastReadDate,
    this.currentStreak = 0,
  });

  factory AchievementsState.initial() => AchievementsState(
      achievements: [for (final id in AchievementId.values) Achievement(id)]);

  final List<Achievement> achievements;

  /// Calendar day of the very first registered reading. Used to derive how many
  /// months of reading are completed.
  final DateTime? firstReadDate;

  /// Calendar day of the most recent registered reading. Drives both the streak
  /// and whether the daily reward is available.
  final DateTime? lastReadDate;

  /// Number of consecutive calendar days on which something was read.
  final int currentStreak;

  Achievement byId(AchievementId id) =>
      achievements.firstWhere((achievement) => achievement.id == id);

  AchievementsState copyWith({
    List<Achievement>? achievements,
    DateTime? firstReadDate,
    DateTime? lastReadDate,
    int? currentStreak,
  }) =>
      AchievementsState(
        achievements: achievements ?? this.achievements,
        firstReadDate: firstReadDate ?? this.firstReadDate,
        lastReadDate: lastReadDate ?? this.lastReadDate,
        currentStreak: currentStreak ?? this.currentStreak,
      );
}

final achievementsProvider =
    StateNotifierProvider<AchievementsNotifier, AchievementsState>(
        (ref) => AchievementsNotifier(),
        name: 'achievementsProvider');

/// Number of rewards that are ready to be collected, used for the badge on the
/// profile button.
final availableRewardsProvider = Provider<int>((ref) {
  final state = ref.watch(achievementsProvider);
  final hasReadToday = ref.watch(hasReadTodayProvider);

  return state.achievements
      .where((achievement) => achievement.id == AchievementId.dailyReading
          ? achievement.canClaimDailyReward(hasReadToday)
          : achievement.canClaimReward)
      .length;
}, name: 'availableRewardsProvider');

/// Whether a section was marked as read on the current calendar day.
final hasReadTodayProvider = Provider<bool>(
    (ref) => app_date_utils.DateUtils.isSameDay(
        ref.watch(achievementsProvider).lastReadDate, DateTime.now()),
    name: 'hasReadTodayProvider');

class AchievementsNotifier extends StateNotifier<AchievementsState> {
  AchievementsNotifier() : super(AchievementsState.initial()) {
    load();
  }

  /// Registers that the user marked something as read today and re-evaluates
  /// every achievement. Call this only when a section is marked as *read* —
  /// un-marking must not extend a streak.
  void registerReading(Plan plan, Schedule? schedule) {
    final today = DateUtils.dateOnly(DateTime.now());
    final lastReadDate = state.lastReadDate;

    final int streak;
    if (lastReadDate == null) {
      streak = 1;
    } else if (app_date_utils.DateUtils.isSameDay(lastReadDate, today)) {
      streak = max(1, state.currentStreak);
    } else if (app_date_utils.DateUtils.isSameDay(
        lastReadDate, today.subtract(const Duration(days: 1)))) {
      streak = state.currentStreak + 1;
    } else {
      // The chain was broken — start over at today.
      streak = 1;
    }

    state = state.copyWith(
      firstReadDate: state.firstReadDate ?? today,
      lastReadDate: today,
      currentStreak: streak,
    );

    recompute(plan, schedule);
  }

  /// Re-evaluates which achievements are completed. Safe to call at any time;
  /// it never *revokes* an achievement that was already earned.
  void recompute(Plan plan, Schedule? schedule) {
    final bookmark = plan.bookmark;
    final sectionsRead =
        schedule == null ? 0 : _countSectionsRead(schedule, bookmark);
    final booksCompleted =
        schedule == null ? 0 : _countBooksCompleted(schedule, bookmark);
    final monthsCompleted =
        _monthsBetween(state.firstReadDate, state.lastReadDate);
    final streak = state.currentStreak;

    final completed = <AchievementId, bool>{
      AchievementId.firstReading: sectionsRead >= 1,
      // The daily achievement is not a milestone; it is driven by
      // [Achievement.canClaimDailyReward] instead.
      AchievementId.dailyReading: false,
      AchievementId.streak3: streak >= 3,
      AchievementId.streak7: streak >= 7,
      AchievementId.streak10: streak >= 10,
      AchievementId.firstChapter: sectionsRead >= 1,
      AchievementId.chapters5: sectionsRead >= 5,
      AchievementId.firstBook: booksCompleted >= 1,
      AchievementId.books5: booksCompleted >= 5,
      AchievementId.firstMonth: monthsCompleted >= 1,
      AchievementId.months3: monthsCompleted >= 3,
    };

    state = state.copyWith(
      achievements: [
        for (final achievement in state.achievements)
          achievement.id == AchievementId.dailyReading
              ? achievement
              : achievement.copyWith(
                  isCompleted: achievement.isCompleted ||
                      (completed[achievement.id] ?? false)),
      ],
    );
    _save();
  }

  void claimReward(AchievementId id) {
    state = state.copyWith(achievements: [
      for (final achievement in state.achievements)
        achievement.id == id
            ? achievement.copyWith(isRewardClaimed: true)
            : achievement,
    ]);
    _save();
  }

  void claimDailyReward() {
    state = state.copyWith(achievements: [
      for (final achievement in state.achievements)
        achievement.id == AchievementId.dailyReading
            ? achievement.copyWith(lastRewardClaimed: DateTime.now())
            : achievement,
    ]);
    _save();
  }

  /// Number of sections at or before the bookmark.
  static int _countSectionsRead(Schedule schedule, Bookmark bookmark) {
    var count = 0;
    for (var dayIndex = 0; dayIndex < schedule.days.length; dayIndex++) {
      final sections = schedule.days[dayIndex].sections;
      for (var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++) {
        if (Bookmark(dayIndex: dayIndex, sectionIndex: sectionIndex)
                .compareTo(bookmark) <=
            0) {
          count++;
        }
      }
    }

    return count;
  }

  /// A book counts as completed once every section belonging to it is at or
  /// before the bookmark.
  static int _countBooksCompleted(Schedule schedule, Bookmark bookmark) {
    final read = <int>{};
    final unread = <int>{};
    for (var dayIndex = 0; dayIndex < schedule.days.length; dayIndex++) {
      final sections = schedule.days[dayIndex].sections;
      for (var sectionIndex = 0;
          sectionIndex < sections.length;
          sectionIndex++) {
        final bookIndex = sections[sectionIndex].bookIndex;
        if (Bookmark(dayIndex: dayIndex, sectionIndex: sectionIndex)
                .compareTo(bookmark) <=
            0) {
          read.add(bookIndex);
        } else {
          unread.add(bookIndex);
        }
      }
    }

    return read.difference(unread).length;
  }

  /// Whole months between the first and the most recent reading.
  static int _monthsBetween(DateTime? start, DateTime? end) {
    if (start == null || end == null) return 0;
    var months = (end.year - start.year) * 12 + end.month - start.month;
    if (end.day < start.day) months--;

    return max(0, months);
  }

  Future<void> _save() async {
    final snapshot = state;
    try {
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
          _preferenceKey,
          jsonEncode({
            'firstReadDate': snapshot.firstReadDate?.toIso8601String(),
            'lastReadDate': snapshot.lastReadDate?.toIso8601String(),
            'currentStreak': snapshot.currentStreak,
            'achievements': [
              for (final achievement in snapshot.achievements)
                {
                  'id': achievement.id.name,
                  'isCompleted': achievement.isCompleted,
                  'isRewardClaimed': achievement.isRewardClaimed,
                  'lastRewardClaimed':
                      achievement.lastRewardClaimed?.toIso8601String(),
                }
            ],
          }));
    } catch (e) {
      debugPrint('Storing the achievements failed with error $e');
    }
  }

  Future<void> load() async {
    try {
      final preferences = await SharedPreferences.getInstance();
      final stored = preferences.getString(_preferenceKey);
      if (stored == null) return;

      final decoded = jsonDecode(stored);
      // The previous format was a bare list keyed by the German title.
      final Map<String, dynamic> data = decoded is List
          ? {'achievements': decoded}
          : decoded as Map<String, dynamic>;
      final storedAchievements =
          (data['achievements'] as List?) ?? const <dynamic>[];

      final byId = <AchievementId, Achievement>{};
      for (final entry in storedAchievements.cast<Map<String, dynamic>>()) {
        final id = _idOf(entry);
        if (id == null) continue;
        final lastRewardClaimed = entry['lastRewardClaimed'] as String?;
        byId[id] = Achievement(
          id,
          isCompleted: entry['isCompleted'] as bool? ?? false,
          isRewardClaimed: entry['isRewardClaimed'] as bool? ?? false,
          lastRewardClaimed: lastRewardClaimed == null
              ? null
              : DateTime.tryParse(lastRewardClaimed),
        );
      }

      final firstReadDate = data['firstReadDate'] as String?;
      final lastReadDate = data['lastReadDate'] as String?;

      // Start from the full set so achievements added in a later version are
      // not lost for existing installations.
      state = AchievementsState(
        achievements: [
          for (final id in AchievementId.values) byId[id] ?? Achievement(id)
        ],
        firstReadDate:
            firstReadDate == null ? null : DateTime.tryParse(firstReadDate),
        lastReadDate:
            lastReadDate == null ? null : DateTime.tryParse(lastReadDate),
        currentStreak: data['currentStreak'] as int? ?? 0,
      );
    } catch (e) {
      debugPrint('Loading the achievements failed with error $e');
    }
  }

  static AchievementId? _idOf(Map<String, dynamic> entry) {
    final id = entry['id'] as String?;
    if (id != null) {
      for (final value in AchievementId.values) {
        if (value.name == id) return value;
      }
    }

    return _legacyTitleIds[entry['title'] as String?];
  }
}
