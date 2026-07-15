enum PlaybackStatus {
  playing,
  paused,
  buffering,
  stopped,
  error
}

class PlaybackState {
  final PlaybackStatus status;
  final Duration position;
  final Duration buffered;
  final double volume;
  final String? errorReason;

  const PlaybackState({
    required this.status,
    this.position = Duration.zero,
    this.buffered = Duration.zero,
    this.volume = 1.0,
    this.errorReason,
  });

  PlaybackState copyWith({
    PlaybackStatus? status,
    Duration? position,
    Duration? buffered,
    double? volume,
    String? errorReason,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      position: position ?? this.position,
      buffered: buffered ?? this.buffered,
      volume: volume ?? this.volume,
      errorReason: errorReason ?? this.errorReason,
    );
  }
}
