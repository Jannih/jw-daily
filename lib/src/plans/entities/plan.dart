import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/plans/entities/plans.dart';
import 'package:jw_daily/src/schedules/entities/schedule.dart';
import 'package:jw_daily/src/profile/achievements.dart';

final planProviderFamily =
    AutoDisposeNotifierProviderFamily<PlanNotifier, Plan, String>(
        PlanNotifier.new,
        name: 'planProviderFamily');

class PlanNotifier extends AutoDisposeFamilyNotifier<Plan, String> {
  PlansNotifier? plansNotifier;
  Schedule? schedule;

  @override
  Plan build(arg) {
    final planId = arg;

    ref.watch(plansProvider);
    plansNotifier = ref.watch(plansProvider.notifier);

    final plan =
        (plansNotifier!.getPlan(planId) ?? plansNotifier!.getNewPlan(planId));
    schedule = ref.watch(scheduleProviderFamily(plan.scheduleKey)).valueOrNull;

    return plan.copyWith();
  }

  void delete() {
    plansNotifier?.removePlan(state.id);
  }

  bool isRead({required int dayIndex, required int sectionIndex}) =>
      state.bookmark.compareTo(
          Bookmark(dayIndex: dayIndex, sectionIndex: sectionIndex)) >=
      0;

  void toggleRead(
      {required int dayIndex, required int sectionIndex, bool force = false}) {
    final achievements = ref.read(achievementsProvider.notifier);

    if (isRead(dayIndex: dayIndex, sectionIndex: sectionIndex)) {
      final plan = setUnread(
          dayIndex: dayIndex, sectionIndex: sectionIndex, force: force);
      // Un-marking a section is not a reading, so it must neither extend the
      // streak nor count towards the daily reward.
      achievements.recompute(plan, schedule);
    } else {
      final plan =
          setRead(dayIndex: dayIndex, sectionIndex: sectionIndex, force: force);
      achievements.registerReading(plan, schedule);
    }
  }

  /// Marks everything up to and including the given section as read and returns
  /// the updated plan. The notifier's own [state] is only refreshed once the
  /// plans provider has rebuilt, so callers that need the new bookmark right
  /// away have to use the return value.
  Plan setRead(
      {required int dayIndex, required int sectionIndex, bool force = false}) {
    final days = schedule?.days;
    final sections = days != null && dayIndex >= 0 && dayIndex < days.length
        ? days[dayIndex].sections.length
        : null;
    final newBookmark = sections != null && sectionIndex >= sections - 1
        ? Bookmark(dayIndex: dayIndex + 1, sectionIndex: -1)
        : Bookmark(dayIndex: dayIndex, sectionIndex: sectionIndex);

    if (!force && (newBookmark.dayIndex - state.bookmark.dayIndex).abs() > 3) {
      throw TogglingTooManyDaysException();
    }

    final plan = state.copyWith(
      bookmark: newBookmark,
      startDate: getStartDate(newBookmark),
      lastDate: DateUtils.dateOnly(DateTime.now()),
      targetDate: state.targetDate ?? calcTargetDate(newBookmark),
    );
    plansNotifier?.updatePlan(plan);

    return plan;
  }

  Plan setUnread(
          {required int dayIndex,
          required int sectionIndex,
          bool force = false}) =>
      setRead(dayIndex: dayIndex, sectionIndex: sectionIndex - 1, force: force);

  void resetTargetDate() {
    if (state.withTargetDate) {
      plansNotifier?.updatePlan(
          state.copyWith(targetDate: calcTargetDate(state.bookmark)));
    }
  }

  double getProgress() =>
      schedule == null ? 0 : state.bookmark.dayIndex / schedule!.length;

  int getDeviationDays() {
    final targetDate = getTargetDate();
    final calculatedTargetDate = calcTargetDate();

    if (state.withTargetDate &&
        targetDate != null &&
        calculatedTargetDate != null) {
      final deviationDays = targetDate.difference(calculatedTargetDate).inDays;

      // If ahead, don't count the current day.
      return deviationDays <= 0 ? deviationDays : deviationDays - 1;
    } else {
      return 0;
    }
  }

  bool isFinished() => getRemainingDays() == 0;

  DateTime? getTargetDate() => state.targetDate ?? calcTargetDate();

  DateTime? calcTargetDate([Bookmark? bookmark]) {
    final remainingDays = getRemainingDays(bookmark);

    return state.withTargetDate && remainingDays != null
        ? DateUtils.dateOnly(DateTime.now()).add(Duration(days: remainingDays))
        : null;
  }

  int? todayTargetIndex() => state.withTargetDate &&
          getTargetDate() != null &&
          schedule != null
      ? schedule!.length -
          getTargetDate()!.difference(DateUtils.dateOnly(DateTime.now())).inDays
      : null;

  DateTime? getStartDate([Bookmark? bookmark]) => state.withTargetDate
      ? state.startDate ??
          DateUtils.dateOnly(DateTime.now())
              .add(Duration(days: -(bookmark ?? state.bookmark).dayIndex))
      : null;

  int? getRemainingDays([Bookmark? bookmark]) => schedule == null
      ? null
      : schedule!.length - (bookmark ?? state.bookmark).dayIndex;
}

class TogglingTooManyDaysException implements Exception {}

// @immutable
class Plan extends Equatable {
  const Plan(
      {required this.id,
      this.name,
      required this.scheduleKey,
      this.language,
      required this.bookmark,
      this.startDate,
      this.lastDate,
      this.targetDate,
      required this.withTargetDate,
      required this.showEvents,
      required this.showLocations,
      required this.showBibleVerses,
      required this.showVideos});

  final String id;
  final String? name;
  final ScheduleKey scheduleKey;
  final String? language;
  final Bookmark bookmark;
  final DateTime? startDate;
  final DateTime? lastDate;
  final DateTime? targetDate;
  final bool withTargetDate;
  final bool showEvents;
  final bool showLocations;
  final bool showBibleVerses;
  final bool showVideos;

  Plan copyWith({
    String? id,
    String? name,
    ScheduleKey? scheduleKey,
    String? language,
    Bookmark? bookmark,
    DateTime? startDate,
    DateTime? lastDate,
    DateTime? targetDate,
    bool? withTargetDate,
    bool? showEvents,
    bool? showLocations,
    bool? showBibleVerses,
    bool? showVideos,
    bool? nullStartDate,
    bool? nullLastDate,
    bool? nullTargetDate,
  }) =>
      Plan(
          id: id ?? this.id,
          name: name ?? this.name,
          scheduleKey: scheduleKey ?? this.scheduleKey,
          language: language ?? this.language,
          bookmark: bookmark ?? this.bookmark,
          startDate: nullStartDate == true ? null : startDate ?? this.startDate,
          lastDate: nullLastDate == true ? null : lastDate ?? this.lastDate,
          targetDate:
              nullTargetDate == true ? null : targetDate ?? this.targetDate,
          withTargetDate: withTargetDate ?? this.withTargetDate,
          showEvents: showEvents ?? this.showEvents,
          showLocations: showLocations ?? this.showLocations,
          showBibleVerses: showBibleVerses ?? this.showBibleVerses,
          showVideos: showVideos ?? this.showVideos);

  @override
  List<Object?> get props => [
        name,
        scheduleKey,
        language,
        bookmark,
        startDate,
        lastDate,
        targetDate,
        withTargetDate,
        showEvents,
        showLocations,
        showBibleVerses,
        showVideos
      ];
}

@immutable
class Bookmark extends Equatable implements Comparable<Bookmark> {
  const Bookmark({
    required this.dayIndex,
    required this.sectionIndex,
  });

  final int dayIndex;
  final int sectionIndex;

  Bookmark copyWith({
    int? dayIndex,
    int? sectionIndex,
  }) =>
      Bookmark(
        dayIndex: dayIndex ?? this.dayIndex,
        sectionIndex: sectionIndex ?? this.sectionIndex,
      );

  @override
  List<Object> get props => [dayIndex, sectionIndex];

  @override
  int compareTo(Bookmark other) {
    if (dayIndex < other.dayIndex) return -1;
    if (dayIndex > other.dayIndex) return 1;
    return sectionIndex.compareTo(other.sectionIndex);
  }
}
