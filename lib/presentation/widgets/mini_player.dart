import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/player_provider.dart';
import '../../data/models/playback_state.dart';
import '../screens/player_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerProvider);
    final song = playerState.currentSong;

    if (song == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          backgroundColor: Colors.transparent,
          builder: (context) => const PlayerScreen(),
        );
      },
      child: Container(
        height: 64,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: song.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: song.thumbnailUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                    )
                  : Container(width: 48, height: 48, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(song.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color)),
                ],
              ),
            ),
            IconButton(
              icon: Icon(playerState.playbackState.status == PlaybackStatus.playing ? Icons.pause : Icons.play_arrow),
              onPressed: () {
                ref.read(playerProvider.notifier).togglePlayPause();
              },
            ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              onPressed: () {
                ref.read(playerProvider.notifier).playNext();
              },
            ),
          ],
        ),
      ),
    );
  }
}
