import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:nwt_reading/src/schedules/entities/videos.dart';
import 'package:nwt_reading/src/schedules/repositories/videos_deserializer.dart';

final videosRepositoryProvider = Provider<VideosRepository>(
    (ref) => VideosRepository(ref),
    name: 'videosRepositoryProvider');

class VideosRepository {
  VideosRepository(this.ref) {
    _setVideosFromJsonFiles();
  }

  final Ref ref;

  void _setVideosFromJsonFiles() async {
    final json = await rootBundle.loadString('assets/repositories/videos.json');
    final videos = VideosDeserializer().convertJsonToVideos(json);
    ref.read(videosProvider.notifier).init(videos);
  }
}
