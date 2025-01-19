import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/plans/entities/plan.dart';
import 'package:nwt_reading/src/plans/entities/plans.dart';
import 'package:nwt_reading/src/schedules/entities/schedule.dart';
import 'package:nwt_reading/src/schedules/repositories/schedules_repository.dart';
import 'package:nwt_reading/src/bible_languages/entities/bible_languages.dart';

final planEditProviderFamily =
    AutoDisposeNotifierProviderFamily<PlanEdit, Plan, String?>(PlanEdit.new,
        name: 'planEditProviderFamily');

class PlanEdit extends AutoDisposeFamilyNotifier<Plan, String?> {
  String? planId;
  String? _name;
  String? _startBook;
  String? get startBook => _startBook;

  @override
  Plan build(arg) {
    if (arg == null && planId == null) {
      planId = ref.read(plansProvider.notifier).getNewPlanId();
    }
    return ref.watch(planProviderFamily(arg ?? planId!));
  }

  Schedule? getSchedule() =>
      ref.read(scheduleProviderFamily(state.scheduleKey)).valueOrNull;

  void changeName(String name) => _name = name;

  void updateLanguage(String language) {
    if (language != state.language) {
      state = state.copyWith(language: language);
    }
  }

    // Neue Methode zum Aktualisieren des Startbuchs
  void updateStartBook(String? bookName) async {
    if (bookName == _startBook) return;
    _startBook = bookName;
    
    if (bookName == null) {
      // Wenn kein Startbuch gewählt wurde, Original-Schedule verwenden
      state = state.copyWith(
        scheduleKey: state.scheduleKey,
        bookmark: const Bookmark(dayIndex: 0, sectionIndex: -1),
      );
      return;
    }

    // Originalen Schedule laden
    final originalSchedule = await ref.read(
      scheduleProviderFamily(state.scheduleKey).future
    );
    
    if (originalSchedule == null) return;

    // Hole die Bibelbücher für die aktuelle Sprache
    final bibleLanguagesAsync = await ref.read(bibleLanguagesProvider.future);
    final language = bibleLanguagesAsync.bibleLanguages[state.language];
    if (language == null) return;
    
    // Finde den Index des gewählten Buchs
    final books = language.books;
    final bookIndex = books.indexWhere((book) => book.name == bookName);
    if (bookIndex == -1) return;

    // Finde den Tag im Schedule, der mit diesem Buch beginnt
    int startDayIndex = 0;
    bool found = false;
    for (var i = 0; i < originalSchedule.days.length; i++) {
      for (var section in originalSchedule.days[i].sections) {
        if (section.bookIndex == bookIndex) {
          startDayIndex = i;
          found = true;
          break;
        }
      }
      if (found) break;
    }

        // Erstelle einen neuen Schedule, der beim gewählten Buch beginnt
    final adjustedSchedule = Schedule([
      ...originalSchedule.days.sublist(startDayIndex),
      if (startDayIndex > 0) ...originalSchedule.days.sublist(0, startDayIndex)
    ]);

    // Speichere den angepassten Schedule
    final newScheduleKey = state.scheduleKey.copyWith(
      version: '${state.scheduleKey.version}_${bookName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}'
    );
    
    await ref.read(schedulesRepositoryProvider).saveCustomSchedule(
      newScheduleKey,
      adjustedSchedule
    );

    // Aktualisiere den Plan
    state = state.copyWith(
      scheduleKey: newScheduleKey,
      bookmark: const Bookmark(dayIndex: 0, sectionIndex: -1),
      nullStartDate: true,
      nullLastDate: true,
      nullTargetDate: true,
    );
  }

  void updateScheduleDuration(ScheduleDuration scheduleDuration) async {
    final oldScheduleDuration = state.scheduleKey.duration;

    if (scheduleDuration != oldScheduleDuration) {
      final newScheduleKey =
          state.scheduleKey.copyWith(duration: scheduleDuration);
      final newScheduleLength =
          (await ref.read(scheduleProviderFamily(newScheduleKey).future))
                  ?.length ??
              1;
      final oldScheduleLength = getSchedule()?.length ?? 1;
      final newDayIndex =
          (state.bookmark.dayIndex * newScheduleLength / oldScheduleLength)
              .round();

      state = state.copyWith(
        name: _name,
        scheduleKey: newScheduleKey,
        bookmark: Bookmark(dayIndex: newDayIndex, sectionIndex: -1),
        nullStartDate: true,
        nullLastDate: true,
        nullTargetDate: true,
      );
    }
  }

  void updateScheduleType(ScheduleType scheduleType) {
    if (scheduleType != state.scheduleKey.type) {
      final newScheduleKey = state.scheduleKey.copyWith(type: scheduleType);

      state = state.copyWith(
        name: _name,
        scheduleKey: newScheduleKey,
        bookmark: const Bookmark(dayIndex: 0, sectionIndex: -1),
      );
    }
  }

  void updateWithTargetDate(bool withTargetDate) {
    if (withTargetDate != state.withTargetDate) {
      state = state.copyWith(withTargetDate: withTargetDate);
    }
  }

  DateTime? calcTargetDate() {
    final notifier = ref.read(planProviderFamily(state.id).notifier);
    return notifier.calcTargetDate();
  }

  void resetTargetDate() {
    final notifier = ref.read(planProviderFamily(state.id).notifier);
    notifier.resetTargetDate();
  }

  void updateShowEvents(bool showEvents) {
    if (showEvents != state.showEvents) {
      state = state.copyWith(showEvents: showEvents);
    }
  }

  void updateShowLocations(bool showLocations) {
    if (showLocations != state.showLocations) {
      state = state.copyWith(showLocations: showLocations);
    }
  }

  void updateShowBibleVerses(bool showBibleVerses) {
    if (showBibleVerses != state.showBibleVerses) {
      state = state.copyWith(showBibleVerses: showBibleVerses);
    }
  }

  void updateShowVideos(bool showVideos) {
    if (showVideos != state.showVideos) {
      state = state.copyWith(showVideos: showVideos);
    }
  }

  void reset() => state = build(state.id);

  void save() {
    state = state.copyWith(name: _name);
    final notifier = ref.read(plansProvider.notifier);
    notifier.existPlan(state.id)
        ? notifier.updatePlan(state)
        : notifier.addPlan(state);
  }

  void delete() => ref.read(plansProvider.notifier).removePlan(state.id);
}
