import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/search_result.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../providers/player_provider.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  bool _isLoading = true;
  SearchResults? _library;

  @override
  void initState() {
    super.initState();
    _fetchLibrary();
  }

  Future<void> _fetchLibrary() async {
    try {
      final res = await YouTubeBridge.getLibrary();
      if (res != null) {
        final decoded = jsonDecode(res) as List<dynamic>;
        setState(() {
          _library = SearchResults.fromJson(decoded);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Library error: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : (_library == null || (_library!.songs.isEmpty && _library!.albums.isEmpty && _library!.playlists.isEmpty))
          ? const Center(child: Text("Your library is empty.\n(Anonymous session)", textAlign: TextAlign.center))
          : ListView(
              children: [
                if (_library!.playlists.isNotEmpty) ...[
                  const Padding(padding: EdgeInsets.all(16), child: Text("Playlists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  ..._library!.playlists.map((p) => ListTile(
                    leading: p.thumbnailUrl != null ? Image.network(p.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.playlist_play),
                    title: Text(p.title),
                    subtitle: Text(p.author ?? "Playlist"),
                    onTap: () => context.push('/playlist', extra: p),
                  )).toList(),
                ],
                if (_library!.albums.isNotEmpty) ...[
                  const Padding(padding: EdgeInsets.all(16), child: Text("Albums", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  ..._library!.albums.map((a) => ListTile(
                    leading: a.thumbnailUrl != null ? Image.network(a.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.album),
                    title: Text(a.title),
                    subtitle: Text(a.artistName),
                    onTap: () => context.push('/album', extra: a),
                  )).toList(),
                ],
                if (_library!.songs.isNotEmpty) ...[
                  const Padding(padding: EdgeInsets.all(16), child: Text("Liked Songs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
                  ..._library!.songs.map((s) => ListTile(
                    leading: s.thumbnailUrl != null ? Image.network(s.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover) : const Icon(Icons.music_note),
                    title: Text(s.title),
                    subtitle: Text(s.artistName),
                    onTap: () => ref.read(playerProvider.notifier).play(s),
                  )).toList(),
                ],
              ],
            ),
    );
  }
}
