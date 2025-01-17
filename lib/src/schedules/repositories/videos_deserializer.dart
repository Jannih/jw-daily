import 'dart:convert';
import 'package:nwt_reading/src/schedules/entities/videos.dart';

class VideosDeserializer {
  Videos convertJsonToVideos(String json) {
    final Map<String, dynamic> videosMap =
        jsonDecode(json) as Map<String, dynamic>;
    final videos = videosMap.map((key, value) =>
        MapEntry(key, _convertMapToVideo(value as Map<String, dynamic>)));

    return Videos(videos);
  }

  Video _convertMapToVideo(Map<String, dynamic> videoMap) {
    return Video(
      title: videoMap['title'] as String,
      url: videoMap['url'] as String,
    );
  }
}
