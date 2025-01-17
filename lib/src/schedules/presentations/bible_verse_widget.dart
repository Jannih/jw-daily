import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/schedules/entities/bible_verses.dart';
import 'package:url_launcher/url_launcher.dart';

class BibleVersesWidget extends ConsumerWidget {
  const BibleVersesWidget(this.verses, {super.key});

  final List<BibleVerse> verses;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versesText = verses
        .asMap()
        .entries
        .map((verse) => TextSpan(
          text: '${verse.value.verse}: ${verse.value.question}',
          recognizer: TapGestureRecognizer()
            ..onTap = () => _launchURL(verse.value.url),
        ))
        .toList();

    return Text.rich(
      TextSpan(
        children: versesText.expand((span) => [
          span,
          if (versesText.last != span) const TextSpan(text: ' — '),
        ]).toList(),
      ),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}