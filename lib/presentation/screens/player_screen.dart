import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/player_provider.dart';
import '../../data/models/playback_state.dart';

class PlayerScreen extends ConsumerWidget {
  const PlayerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    if (song == null) return const Scaffold(body: Center(child: Text("No song playing")));

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          if (song.thumbnailUrl != null)
            Positioned.fill(
              child: CachedNetworkImage(
                imageUrl: song.thumbnailUrl!,
                fit: BoxFit.cover,
              ),
            ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
              child: Container(color: Colors.black.withOpacity(0.5)),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 32),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Text("Now Playing", style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600)),
                      IconButton(
                        icon: const Icon(Icons.more_vert, color: Colors.white),
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Hero(
                      tag: 'artwork',
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 10))
                          ],
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(song.thumbnailUrl ?? ''),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(song.title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 4),
                            Text(song.artistName, style: const TextStyle(color: Colors.white70, fontSize: 18), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.favorite_border, color: Colors.white),
                        onPressed: () {},
                      )
                    ],
                  ),
                ),
                
                if (playerState.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        playerState.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 4,
                      ),
                    ),
                  ),
                const SizedBox(height: 24),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: _ProgressBar(playerState: playerState, ref: ref),
                ),
                
                const SizedBox(height: 16),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(icon: const Icon(Icons.shuffle, color: Colors.white70), onPressed: () {}),
                      IconButton(icon: const Icon(Icons.skip_previous, color: Colors.white, size: 40), onPressed: () => ref.read(playerProvider.notifier).playPrevious()),
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.1),
                        ),
                        child: IconButton(
                          icon: Icon(playerState.playbackState.status == PlaybackStatus.playing ? Icons.pause : Icons.play_arrow, color: Colors.white, size: 48),
                          onPressed: () => ref.read(playerProvider.notifier).togglePlayPause(),
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.skip_next, color: Colors.white, size: 40), onPressed: () => ref.read(playerProvider.notifier).playNext()),
                      IconButton(icon: const Icon(Icons.repeat, color: Colors.white70), onPressed: () {}),
                    ],
                  ),
                ),
                
                const SizedBox(height: 48),
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton.icon(
                        icon: const Icon(Icons.lyrics_outlined, color: Colors.white70),
                        label: const Text("Lyrics", style: TextStyle(color: Colors.white70)),
                        onPressed: () {},
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.queue_music, color: Colors.white70),
                        label: const Text("Up Next", style: TextStyle(color: Colors.white70)),
                        onPressed: () {},
                      ),
                    ],
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final PlayerState playerState;
  final WidgetRef ref;

  const _ProgressBar({required this.playerState, required this.ref});

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${d.inHours > 0 ? '${d.inHours}:' : ''}$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    final pos = playerState.playbackState.position.inSeconds.toDouble();
    final dur = playerState.currentSong?.durationSeconds.toDouble() ?? 100.0;
    
    return Column(
      children: [
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 4,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
            activeTrackColor: Colors.white,
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
          ),
          child: Slider(
            min: 0,
            max: dur > 0 ? dur : 1,
            value: pos.clamp(0, dur > 0 ? dur : 1),
            onChanged: (v) {
              ref.read(playerProvider.notifier).seek(Duration(seconds: v.toInt()));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_formatDuration(playerState.playbackState.position), style: const TextStyle(color: Colors.white70, fontSize: 12)),
              Text(_formatDuration(Duration(seconds: dur.toInt())), style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }
}
