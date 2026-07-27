import 'dart:convert';

import 'package:jw_daily/src/plans/entities/plan.dart';
import 'package:jw_daily/src/plans/entities/plans.dart';
import 'package:jw_daily/src/schedules/entities/schedule.dart';

class PlansDeserializer {
  Plans convertStringListToPlans(List<String>? plansStringList) =>
      Plans((plansStringList ?? [])
          .map((planJson) =>
              _convertMapToPlan(jsonDecode(planJson) as Map<String, dynamic>))
          .toList());

  ScheduleKey convertMapToScheduleKey(Map<String, dynamic> scheduleKeyMap) {
    final type = ScheduleType.values[scheduleKeyMap['type'] as int];
    final duration = ScheduleDuration.values[scheduleKeyMap['duration'] as int];
    final version = scheduleKeyMap['version'] as String;

    return ScheduleKey(
      type: type,
      duration: duration,
      version: version,
    );
  }

  Plan _convertMapToPlan(Map<String, dynamic> planMap) {
    final id = planMap['id'] as String;
    final name = planMap['name'] == null ? null : planMap['name'] as String;
    final schedule =
        convertMapToScheduleKey(planMap['scheduleKey'] as Map<String, dynamic>);
    final language = planMap['language'] as String;
    final bookmark =
        _convertMapToBookmark(planMap['bookmark'] as Map<String, dynamic>);
    final startDate = planMap['startDate'] == null
        ? null
        : DateTime.parse(planMap['startDate'] as String);
    final lastDate = planMap['lastDate'] == null
        ? null
        : DateTime.parse(planMap['lastDate'] as String);
    final targetDate = planMap['targetDate'] == null
        ? null
        : DateTime.parse(planMap['targetDate'] as String);
    final withTargetDate = planMap['withTargetDate'] as bool;
    final showEvents = planMap['showEvents'] as bool;
    final showLocations = planMap['showLocations'] as bool;
    // Plans stored before these toggles existed have no such key. Fall back to
    // the defaults of a new plan instead of throwing away the whole plan.
    final showBibleVerses = planMap['showBibleVerses'] as bool? ?? true;
    final showVideos = planMap['showVideos'] as bool? ?? true;

    return Plan(
        id: id,
        name: name,
        scheduleKey: schedule,
        language: language,
        bookmark: bookmark,
        startDate: startDate,
        lastDate: lastDate,
        targetDate: targetDate,
        withTargetDate: withTargetDate,
        showEvents: showEvents,
        showLocations: showLocations,
        showBibleVerses: showBibleVerses,
        showVideos: showVideos);
  }

  Bookmark _convertMapToBookmark(Map<String, dynamic> bookmarkMap) {
    final dayIndex = bookmarkMap['dayIndex'] as int;
    final sectionIndex = bookmarkMap['sectionIndex'] as int;

    return Bookmark(
      dayIndex: dayIndex,
      sectionIndex: sectionIndex,
    );
  }
}
