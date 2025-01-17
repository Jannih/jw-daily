import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/schedules/entities/videos.dart';
import 'package:url_launcher/url_launcher.dart';

class VideosWidget extends ConsumerWidget {
  const VideosWidget(this.videos, {super.key});

  final List<Video> videos;

  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final videosText = videos
        .asMap()
        .entries
        .map((video) => TextSpan(
              text: video.value.title,
              recognizer: TapGestureRecognizer()
                ..onTap = () => _launchURL(video.value.url),
            ))
        .toList();

    return Text.rich(
      TextSpan(
        children: videosText
            .expand((span) => [
                  span,
                  if (videosText.last != span) const TextSpan(text: ' — '),
                ])
            .toList(),
      ),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
