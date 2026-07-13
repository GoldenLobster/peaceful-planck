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
}
