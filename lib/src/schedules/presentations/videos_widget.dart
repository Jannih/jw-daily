import 'package:flutter/material.dart';
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
    return Wrap(
      children: [
        for (var i = 0; i < videos.length; i++) ...[
          GestureDetector(
            onTap: () => _launchURL(videos[i].url),
            child: Text(
              videos[i].title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          if (i < videos.length - 1)
            Text(' — ', style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}
