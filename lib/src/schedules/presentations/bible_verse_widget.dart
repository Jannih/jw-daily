import 'package:flutter/material.dart';
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
    return Wrap(
      children: [
        for (var i = 0; i < verses.length; i++) ...[
          GestureDetector(
            onTap: () => _launchURL(verses[i].url),
            child: Text(
              '${verses[i].verse}: ${verses[i].question}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (i < verses.length - 1)
            Text(' — ', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
