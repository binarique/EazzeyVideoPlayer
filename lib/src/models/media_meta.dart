import 'package:flutter_vlc_player/flutter_vlc_player.dart';

class MediaMeta {
  final Duration duration, position;
  final int time;
  final double? playBackspeed, videoScale;
  final int? audioDelay, audioTrackCount, volume;
  final bool? isPlaying, isSeekable;
  final String? videoAspectRatio;

  MediaMeta({
    required this.position,
    required this.videoScale,
    required this.duration,
    required this.volume,
    required this.time,
    required this.playBackspeed,
    required this.audioDelay,
    required this.audioTrackCount,
    required this.isPlaying,
    required this.isSeekable,
    required this.videoAspectRatio,
  });
}
