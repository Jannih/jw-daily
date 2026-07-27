import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:jw_daily/src/schedules/entities/locations.dart';
import 'package:jw_daily/src/schedules/repositories/locations_deserializer.dart';

final locationsRepositoryProvider = Provider<LocationsRepository>(
    (ref) => LocationsRepository(ref),
    name: 'locationsRepositoryProvider');

class LocationsRepository {
  LocationsRepository(this.ref) {
    _setLocationsFromJsonFiles();
  }

  final Ref ref;

  void _setLocationsFromJsonFiles() async {
    final json =
        await rootBundle.loadString('assets/repositories/locations.json');
    final locations = LocationsDeserializer().convertJsonToLocations(json);
    ref.read(locationsProvider.notifier).init(locations);
  }
}
