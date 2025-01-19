import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nwt_reading/src/schedules/repositories/schedule_deserializer.dart';
import 'package:nwt_reading/src/schedules/repositories/schedule_serializer.dart';
import 'package:nwt_reading/src/schedules/entities/schedule.dart';
import 'package:nwt_reading/src/schedules/entities/schedules.dart';

final schedulesRepositoryProvider = Provider<SchedulesRepository>(
    (ref) => SchedulesRepository(ref),
    name: 'schedulesRepositoryProvider');

class SchedulesRepository {
  SchedulesRepository(this.ref) {
    _setSchedulesFromJsonFiles();
  }

  final Ref ref;

  void _setSchedulesFromJsonFiles() async {
    final schedules = await _getSchedulesFromJsonFiles();
    ref.read(schedulesProvider.notifier).init(schedules);
  }

  Future<void> saveCustomSchedule(ScheduleKey key, Schedule schedule) async {
    final prefs = await SharedPreferences.getInstance();
    final scheduleJson = ScheduleSerializer().convertScheduleToJson(schedule);
    await prefs.setString('custom_schedule_${key.toString()}', scheduleJson);
    
    // Aktualisiere den Provider
    final currentSchedules = ref.read(schedulesProvider).value; 
    if (currentSchedules == null) return;
    
    final updatedSchedules = Schedules({
      ...currentSchedules.schedules,
      key: schedule,
    });
    ref.read(schedulesProvider.notifier).init(updatedSchedules);
  }

  Future<Schedules> _getSchedulesFromJsonFiles() async => Schedules({
        for (var scheduleKey in scheduleKeys)
          scheduleKey: await _getScheduleFromJsonFile(scheduleKey)
      });

  Future<Schedule> _getScheduleFromJsonFile(ScheduleKey key) async {
    // Prüfe zuerst auf benutzerdefinierte Schedules
    if (key.version != '1.0') {
      final prefs = await SharedPreferences.getInstance();
      final customJson = prefs.getString('custom_schedule_${key.toString()}');
      if (customJson != null) {
        return ScheduleDeserializer().convertJsonToSchedule(customJson);
      }
    }

    final json = await rootBundle.loadString(
        'assets/repositories/schedule_${key.type.name}_${key.duration.name}.json');

    return ScheduleDeserializer().convertJsonToSchedule(json);
  }
}
