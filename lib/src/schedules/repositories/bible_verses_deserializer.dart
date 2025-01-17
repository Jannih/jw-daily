import 'dart:convert';
import 'package:nwt_reading/src/schedules/entities/bible_verses.dart';

class BibleVersesDeserializer {
  BibleVerses convertJsonToBibleVerses(String json) {
    final Map<String, dynamic> versesMap =
        jsonDecode(json) as Map<String, dynamic>;
    final verses = versesMap.map((key, value) =>
        MapEntry(key, _convertMapToBibleVerse(value as Map<String, dynamic>)));

    return BibleVerses(verses);
  }

  BibleVerse _convertMapToBibleVerse(Map<String, dynamic> verseMap) {
    return BibleVerse(
      verse: verseMap['verse'] as String,
      question: verseMap['question'] as String,
      url: verseMap['url'] as String,
    );
  }
}
