import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song.dart';
import '../../data/models/playback_state.dart';
import '../../services/native_bridge/audio_bridge.dart';
import '../../services/app_logger.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
class PlayerState {
  final Song? currentSong;
  final PlaybackState playbackState;
  final List<Song> queue;
  final int currentIndex;
  final String? errorMessage;

  PlayerState({
    this.currentSong,
    this.playbackState = const PlaybackState(status: PlaybackStatus.stopped),
    this.queue = const [],
    this.currentIndex = -1,
    this.errorMessage,
  });

  PlayerState copyWith({
    Song? currentSong,
    PlaybackState? playbackState,
    List<Song>? queue,
    int? currentIndex,
    String? errorMessage,
    bool clearError = false,
  }) {
    return PlayerState(
      currentSong: currentSong ?? this.currentSong,
      playbackState: playbackState ?? this.playbackState,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UseProxyNotifier extends Notifier<bool> {
  @override
  bool build() => true;
  void toggle() => state = !state;
  void setProxy(bool val) => state = val;
}

final useProxyProvider = NotifierProvider<UseProxyNotifier, bool>(() {
  return UseProxyNotifier();
});

class PlayerNotifier extends Notifier<PlayerState> {
  StreamSubscription? _audioSub;

  @override
  PlayerState build() {
    _init();
    ref.onDispose(() {
      _audioSub?.cancel();
    });
    return PlayerState();
  }

  void _init() {
    _audioSub = AudioBridge.audioEventsStream.listen((event) {
      if (event is Map) {
        final type = event['type'];
        if (type == 'state') {
          final val = event['value'] as String;
          AppLogger.log("AVPlayer state changed: $val");
          PlaybackStatus status;
          switch (val) {
            case 'playing': status = PlaybackStatus.playing; break;
            case 'paused': status = PlaybackStatus.paused; break;
            case 'buffering': status = PlaybackStatus.buffering; break;
            case 'completed': 
              status = PlaybackStatus.stopped;
              playNext();
              break;
            default: status = PlaybackStatus.stopped;
          }
          state = state.copyWith(playbackState: PlaybackState(
            status: status,
            position: state.playbackState.position,
            buffered: state.playbackState.buffered,
          ));
        } else if (type == 'position') {
          final pos = event['position'] as double;
          state = state.copyWith(playbackState: PlaybackState(
            status: state.playbackState.status,
            position: Duration(milliseconds: (pos * 1000).toInt()),
            buffered: state.playbackState.buffered,
          ));
        } else if (type == 'buffer') {
          final buf = event['buffered'] as double;
          state = state.copyWith(playbackState: PlaybackState(
            status: state.playbackState.status,
            position: state.playbackState.position,
            buffered: Duration(milliseconds: (buf * 1000).toInt()),
          ));
        } else if (type == 'command') {
          final val = event['value'] as String;
          if (val == 'next') playNext();
          if (val == 'previous') playPrevious();
        } else if (type == 'error') {
          final msg = event['message'] as String;
          AppLogger.log("AVPlayer ERROR: $msg");
          state = state.copyWith(errorMessage: msg);
        }
      }
    });
  }

  Future<void> play(Song song) async {
    state = state.copyWith(currentSong: song, clearError: true);
    
    AppLogger.log("--- REQUESTING PLAYBACK ---");
    AppLogger.log("Song: ${song.title} (${song.id})");

    // Fetch real stream URL from youtube_explode_dart instead of youtubei.js
    String? url;
    try {
      AppLogger.log("youtube_explode_dart: fetching manifest for ${song.id}...");
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(song.id);
      
      // AVPlayer on iOS is extremely strict. It often instantly fails to play raw DASH fragmented audio (itag 140).
      // A rock-solid workaround for iOS is to use the "muxed" progressive streams (which contain both video and audio).
      // AVPlayer parses progressive MP4 flawlessly, extracts the audio track natively, and plays perfectly.
      final progressiveStreams = manifest.muxed.where((s) => s.container == StreamContainer.mp4);
      if (progressiveStreams.isEmpty) {
        throw Exception("No progressive MP4 stream found for ${song.id}");
      }
      final streamInfo = progressiveStreams.withHighestBitrate();
      
      url = streamInfo.url.toString();
      AppLogger.log("youtube_explode_dart: Extracted MP4 URL: $url");
      yt.close();
    } catch (e) {
      AppLogger.log("YT_Explode Error: $e");
      state = state.copyWith(errorMessage: "YT_Explode Error: $e");
      return;
    }

    if (url.isEmpty || url.startsWith("ERROR:")) {
      AppLogger.log("Failed to get stream URL for ${song.id}");
      state = state.copyWith(errorMessage: "No stream URL found");
      return;
    }
    
    final useProxy = ref.read(useProxyProvider);
    AppLogger.log("Initializing AudioBridge.play (useProxy: $useProxy)");
    AudioBridge.play(
      url: url,
      title: song.title,
      artist: song.artistName,
      artworkUrl: song.thumbnailUrl,
      useProxy: useProxy,
    );
  }

  void playNext() {
    if (state.queue.isNotEmpty && state.currentIndex < state.queue.length - 1) {
      final nextIndex = state.currentIndex + 1;
      state = state.copyWith(currentIndex: nextIndex);
      play(state.queue[nextIndex]);
    }
  }

  void playPrevious() {
     if (state.queue.isNotEmpty && state.currentIndex > 0) {
      final prevIndex = state.currentIndex - 1;
      state = state.copyWith(currentIndex: prevIndex);
      play(state.queue[prevIndex]);
    }
  }

  void togglePlayPause() {
    if (state.playbackState.status == PlaybackStatus.playing) {
      AudioBridge.pause();
    } else {
      AudioBridge.resume();
    }
  }

  void seek(Duration position) {
    AudioBridge.seek(position.inSeconds.toDouble());
  }
}

final playerProvider = NotifierProvider<PlayerNotifier, PlayerState>(() {
  return PlayerNotifier();
});
