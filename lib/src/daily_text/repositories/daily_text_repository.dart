import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:nwt_reading/src/daily_text/entities/daily_text.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _dailyTextCacheKey = 'daily_text_cache';
const _dailyTextCacheDateKey = 'daily_text_cache_date';

final dailyTextRepositoryProvider = Provider<DailyTextRepository>(
    (ref) => DailyTextRepository(ref),
    name: 'dailyTextRepositoryProvider');

class DailyTextRepository {
  DailyTextRepository(this.ref);

  final Ref ref;

  Future<void> loadTodaysDailyText() async {
    final now = DateTime.now();
    final todayString = '${now.year}-${now.month}-${now.day}';

    // Versuche zuerst aus dem Cache zu laden
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDate = prefs.getString(_dailyTextCacheDateKey);
      final cachedData = prefs.getString(_dailyTextCacheKey);

      if (cachedDate == todayString && cachedData != null) {
        final data = jsonDecode(cachedData) as Map<String, dynamic>;
        final dailyText = DailyText(
          date: now,
          themeScripture: data['themeScripture'] as String,
          themeText: data['themeText'] as String,
          comment: data['comment'] as String,
          source: data['source'] as String,
        );
        ref.read(dailyTextProvider.notifier).state = AsyncValue.data(dailyText);
        return;
      }
    } catch (e) {
      debugPrint('Cache-Lesefehler: $e');
    }

    // Lade vom Netzwerk
    try {
      final dailyText = await _fetchDailyText(now);
      ref.read(dailyTextProvider.notifier).state = AsyncValue.data(dailyText);

      // Speichere im Cache
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_dailyTextCacheDateKey, todayString);
        await prefs.setString(_dailyTextCacheKey, jsonEncode({
          'themeScripture': dailyText.themeScripture,
          'themeText': dailyText.themeText,
          'comment': dailyText.comment,
          'source': dailyText.source,
        }));
      } catch (e) {
        debugPrint('Cache-Schreibfehler: $e');
      }
    } catch (e) {
      ref.read(dailyTextProvider.notifier).state =
          AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<DailyText> _fetchDailyText(DateTime date) async {
    final url = Uri.parse(
        'https://wol.jw.org/de/wol/dt/r10/lp-x/${date.year}/${date.month}/${date.day}');

    final response = await http.get(url, headers: {
      'User-Agent':
          'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
      'Accept': 'text/html,application/xhtml+xml',
      'Accept-Language': 'de-DE,de;q=0.9',
    }).timeout(const Duration(seconds: 15));

    if (response.statusCode != 200) {
      throw Exception(
          'Tagestext konnte nicht geladen werden (${response.statusCode})');
    }

    return _parseHtml(response.body, date);
  }

  DailyText _parseHtml(String html, DateTime date) {
    // Extract theme scripture reference (the bold text in the first paragraph)
    final themeScripture = _extractBetween(html, 'themeScrp', '</em>');
    // Extract the theme text (the verse text, typically in the first paragraph after the scripture)
    final themeText = _extractThemeText(html);
    // Extract the comment
    final comment = _extractComment(html);
    // Extract the source
    final source = _extractSource(html);

    return DailyText(
      date: date,
      themeScripture: _cleanHtml(themeScripture),
      themeText: _cleanHtml(themeText),
      comment: _cleanHtml(comment),
      source: _cleanHtml(source),
    );
  }

  String _extractThemeText(String html) {
    // The theme text is usually in the first <p> inside bodyTxt
    // It contains the scripture in <em> and the reference
    final bodyTxtStart = html.indexOf('bodyTxt');
    if (bodyTxtStart == -1) return '';

    final firstPStart = html.indexOf('<p', bodyTxtStart);
    if (firstPStart == -1) return '';

    final firstPEnd = html.indexOf('</p>', firstPStart);
    if (firstPEnd == -1) return '';

    final paragraph = html.substring(firstPStart, firstPEnd + 4);

    // Extract the italic/em text which is the scripture
    final emMatch = RegExp(r'<em>(.*?)</em>', dotAll: true).firstMatch(paragraph);
    if (emMatch != null) {
      return emMatch.group(1) ?? '';
    }

    return paragraph;
  }

  String _extractComment(String html) {
    // The comment is in the second <p> (or subsequent paragraphs) inside bodyTxt
    final bodyTxtStart = html.indexOf('bodyTxt');
    if (bodyTxtStart == -1) return '';

    // Find the first </p> to skip the theme text paragraph
    final firstPEnd = html.indexOf('</p>', bodyTxtStart);
    if (firstPEnd == -1) return '';

    // Find the next paragraph(s) - this is the comment
    final commentStart = html.indexOf('<p', firstPEnd);
    if (commentStart == -1) return '';

    // Collect all remaining paragraphs in bodyTxt
    final bodyTxtEnd = html.indexOf('</div>', commentStart);
    if (bodyTxtEnd == -1) return '';

    final commentSection = html.substring(commentStart, bodyTxtEnd);

    // Remove the last paragraph if it's the source reference
    final paragraphs = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
        .allMatches(commentSection)
        .map((m) => m.group(1) ?? '')
        .toList();

    if (paragraphs.isEmpty) return '';

    // The last paragraph often contains the source, separate it
    if (paragraphs.length > 1) {
      return paragraphs.sublist(0, paragraphs.length - 1).join('\n\n');
    }

    return paragraphs.first;
  }

  String _extractSource(String html) {
    // Source is typically the last paragraph in bodyTxt, contains publication reference
    final bodyTxtStart = html.indexOf('bodyTxt');
    if (bodyTxtStart == -1) return '';

    final bodyTxtSection = html.substring(bodyTxtStart);
    final paragraphs = RegExp(r'<p[^>]*>(.*?)</p>', dotAll: true)
        .allMatches(bodyTxtSection)
        .map((m) => m.group(1) ?? '')
        .toList();

    if (paragraphs.isEmpty) return '';
    return paragraphs.last;
  }

  String _extractBetween(String html, String startMarker, String endMarker) {
    final startIndex = html.indexOf(startMarker);
    if (startIndex == -1) return '';

    final contentStart = html.indexOf('>', startIndex) + 1;
    final contentEnd = html.indexOf(endMarker, contentStart);
    if (contentEnd == -1) return '';

    return html.substring(contentStart, contentEnd);
  }

  String _cleanHtml(String text) {
    return text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .replaceAll(RegExp(r'&nbsp;'), ' ')
        .replaceAll(RegExp(r'&amp;'), '&')
        .replaceAll(RegExp(r'&lt;'), '<')
        .replaceAll(RegExp(r'&gt;'), '>')
        .replaceAll(RegExp(r'&quot;'), '"')
        .replaceAll(RegExp(r'&#39;'), "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
