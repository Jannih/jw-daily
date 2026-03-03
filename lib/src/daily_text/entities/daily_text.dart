import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final dailyTextProvider =
    StateProvider<AsyncValue<DailyText>>((ref) => const AsyncValue.loading());

@immutable
class DailyText extends Equatable {
  const DailyText({
    required this.date,
    required this.themeScripture,
    required this.themeText,
    required this.comment,
    required this.source,
  });

  final DateTime date;
  final String themeScripture;
  final String themeText;
  final String comment;
  final String source;

  @override
  List<Object> get props => [date, themeScripture, themeText, comment, source];
}
