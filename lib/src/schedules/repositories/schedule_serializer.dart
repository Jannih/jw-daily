import 'dart:convert';
import 'package:nwt_reading/src/schedules/entities/schedule.dart';

class ScheduleSerializer {
  String convertScheduleToJson(Schedule schedule) {
    return jsonEncode(_convertScheduleToMap(schedule));
  }

  List<dynamic> _convertScheduleToMap(Schedule schedule) {
    return schedule.days.map((day) => _convertDayToMap(day)).toList();
  }

  List<Map<String, dynamic>> _convertDayToMap(Day day) {
    return day.sections.map((section) => _convertSectionToMap(section)).toList();
  }

  Map<String, dynamic> _convertSectionToMap(Section section) {
    return {
      'bookIndex': section.bookIndex,
      'chapter': section.chapter,
      'endChapter': section.endChapter,
      'ref': section.ref,
      'startIndex': section.startIndex,
      'endIndex': section.endIndex,
      'url': section.url,
      'events': section.events,
      'locations': section.locations,
      'bibleVerses': section.bibleVerses,
      'videos': section.videos,
    };
  }
}