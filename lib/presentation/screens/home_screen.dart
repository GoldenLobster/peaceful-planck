import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/song.dart';
import '../providers/player_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ytmUltimate', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.music_note, size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const Text(
              "Welcome to ytmUltimate",
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              "Recommendations coming in Phase 10",
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text("Play Mock Song"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              ),
              onPressed: () {
                ref.read(playerProvider.notifier).play(
                  const Song(
                    id: 'mock_1',
                    title: 'Starlight',
                    artistName: 'Muse',
                    thumbnailUrl: 'https://upload.wikimedia.org/wikipedia/en/2/2a/Muse_-_Black_Holes_and_Revelations.jpg',
                    durationSeconds: 239,
                  )
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
