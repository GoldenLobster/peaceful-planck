import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song.dart';
import '../../data/models/playback_state.dart';
import '../../services/native_bridge/audio_bridge.dart';
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
          state = state.copyWith(errorMessage: msg);
        }
      }
    });
  }

  Future<void> play(Song song) async {
    state = state.copyWith(currentSong: song, clearError: true);
    
    // Fetch real stream URL from youtube_explode_dart instead of youtubei.js
    String? url;
    try {
      final yt = YoutubeExplode();
      final manifest = await yt.videos.streamsClient.getManifest(song.id);
      final streamInfo = manifest.audioOnly.withHighestBitrate();
      url = streamInfo.url.toString();
      yt.close();
    } catch (e) {
      state = state.copyWith(errorMessage: "YT_Explode Error: $e");
      print("Failed to get stream URL using yt_explode: $e");
      return;
    }

    if (url == null || url.isEmpty || url.startsWith("ERROR:")) {
      state = state.copyWith(errorMessage: "No stream URL found");
      print("Failed to get stream URL for ${song.id}: $url");
      return;
    }
    
    AudioBridge.play(
      url: url,
      title: song.title,
      artist: song.artistName,
      artworkUrl: song.thumbnailUrl,
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
