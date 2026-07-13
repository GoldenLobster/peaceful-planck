import 'package:flutter/services.dart';

class AudioBridge {
  static const MethodChannel _methodChannel = MethodChannel('com.ytmultimate/audio');
  static const EventChannel _eventChannel = EventChannel('com.ytmultimate/audioEvents');

  static Future<void> play({
    required String url,
    required String title,
    required String artist,
    String? artworkUrl,
  }) async {
    await _methodChannel.invokeMethod('play', {
      'url': url,
      'title': title,
      'artist': artist,
      'artworkUrl': artworkUrl,
    });
  }

  static Future<void> pause() async {
    await _methodChannel.invokeMethod('pause');
  }

  static Future<void> resume() async {
    await _methodChannel.invokeMethod('resume');
  }

  static Future<void> seek(double positionSeconds) async {
    await _methodChannel.invokeMethod('seek', {'position': positionSeconds});
  }

  static Stream<dynamic> get audioEventsStream {
    return _eventChannel.receiveBroadcastStream();
  }
}
