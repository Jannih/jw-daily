import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/schedules/entities/bible_verses.dart';
import 'package:nwt_reading/src/schedules/repositories/bible_verses_deserializer.dart';

final bibleVersesRepositoryProvider = Provider<BibleVersesRepository>(
    (ref) => BibleVersesRepository(ref),
    name: 'bibleVersesRepositoryProvider');

class BibleVersesRepository {
  BibleVersesRepository(this.ref) {
    _setBibleVersesFromJsonFiles();
  }

  final Ref ref;

  void _setBibleVersesFromJsonFiles() async {
    final json =
        await rootBundle.loadString('assets/repositories/bible_verses.json');
    final verses = BibleVersesDeserializer().convertJsonToBibleVerses(json);
    ref.read(bibleVersesProvider.notifier).init(verses);
  }
}