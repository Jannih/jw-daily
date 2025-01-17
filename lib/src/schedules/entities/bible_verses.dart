import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/entities/incomplete_notifier.dart';

final bibleVersesProvider =
    AsyncNotifierProvider<IncompleteNotifier<BibleVerses>, BibleVerses>(
        IncompleteNotifier.new,
        name: 'bibleVersesProvider');

@immutable
class BibleVerses {
  const BibleVerses._internal(this.verses);
  factory BibleVerses(Map<BibleVerseID, BibleVerse> verses) =>
      BibleVerses._internal(Map.unmodifiable(verses));

  final Map<BibleVerseID, BibleVerse> verses;

  int get length => keys.length;

  Iterable<BibleVerseID> get keys => verses.keys;
}

typedef BibleVerseID = String;

@immutable
class BibleVerse extends Equatable {
  const BibleVerse({
    required this.verse,
    required this.question,
    required this.url,
  });

  final String verse;
  final String question;
  final String url;

  @override
  List<Object> get props => [verse, question, url];
}