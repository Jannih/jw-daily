import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nwt_reading/src/base/entities/incomplete_notifier.dart';

final videosProvider =
    AsyncNotifierProvider<IncompleteNotifier<Videos>, Videos>(
        IncompleteNotifier.new,
        name: 'videosProvider');

@immutable
class Videos {
  const Videos._internal(this.videos);
  factory Videos(Map<VideoID, Video> videos) =>
      Videos._internal(Map.unmodifiable(videos));

  final Map<VideoID, Video> videos;

  int get length => keys.length;
  Iterable<VideoID> get keys => videos.keys;
}

typedef VideoID = String;

@immutable
class Video extends Equatable {
  const Video({
    required this.title,
    required this.url,
  });

  final String title;
  final String url;

  @override
  List<Object> get props => [title, url];
}
