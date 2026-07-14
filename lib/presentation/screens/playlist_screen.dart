import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/playlist.dart';
import '../../data/models/song.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../providers/player_provider.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final Playlist playlist;
  const PlaylistScreen({super.key, required this.playlist});

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  bool _isLoading = true;
  List<Song> _tracks = [];

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    final res = await YouTubeBridge.getPlaylist(widget.playlist.id);
    if (res != null) {
      final decoded = jsonDecode(res) as List<dynamic>;
      final tracks = decoded.map((e) => Song.fromJson(e as Map<String, dynamic>)).toList();
      setState(() {
        _tracks = tracks;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.playlist.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (widget.playlist.thumbnailUrl != null)
            Image.network(widget.playlist.thumbnailUrl!, width: 200, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 16),
          Text(widget.playlist.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          if (widget.playlist.author != null)
            Text(widget.playlist.author!, style: const TextStyle(fontSize: 16, color: Colors.white70)),
          const SizedBox(height: 16),
          if (_isLoading)
            const CircularProgressIndicator()
          else if (_tracks.isEmpty)
            const Text("No tracks found.")
          else
            Expanded(
              child: ListView.builder(
                itemCount: _tracks.length,
                itemBuilder: (context, index) {
                  final track = _tracks[index];
                  return ListTile(
                    leading: track.thumbnailUrl != null 
                        ? Image.network(track.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover)
                        : const Icon(Icons.music_note),
                    title: Text(track.title, style: const TextStyle(color: Colors.white), maxLines: 1),
                    subtitle: Text(track.artistName, style: const TextStyle(color: Colors.white54), maxLines: 1),
                    onTap: () {
                       ref.read(playerProvider.notifier).play(track);
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
