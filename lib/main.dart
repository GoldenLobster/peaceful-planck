import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/widgets/mini_player.dart';
import 'presentation/providers/player_provider.dart';
import 'data/models/song.dart';

void main() {
  runApp(const ProviderScope(child: YTMUltimateApp()));
}

class YTMUltimateApp extends StatelessWidget {
  const YTMUltimateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ytmUltimate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true).copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Colors.white,
          surface: Colors.black,
        ),
      ),
      home: const RootScreen(),
    );
  }
}

class RootScreen extends ConsumerWidget {
  const RootScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('ytmUltimate')),
      body: Center(
        child: ElevatedButton(
          child: const Text("Play Mock Song"),
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
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const MiniPlayer(),
          BottomNavigationBar(
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
              BottomNavigationBarItem(icon: Icon(Icons.library_music), label: "Library"),
            ],
          ),
        ],
      ),
    );
  }
}
