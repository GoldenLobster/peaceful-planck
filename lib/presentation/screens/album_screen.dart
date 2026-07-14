import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/album.dart';
import '../../data/models/song.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../providers/player_provider.dart';

class AlbumScreen extends ConsumerStatefulWidget {
  final Album album;
  const AlbumScreen({super.key, required this.album});

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  bool _isLoading = true;
  List<Song> _tracks = [];

  @override
  void initState() {
    super.initState();
    _fetchTracks();
  }

  Future<void> _fetchTracks() async {
    final res = await YouTubeBridge.getAlbum(widget.album.id);
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
        title: Text(widget.album.title),
        backgroundColor: Colors.transparent,
      ),
      body: Column(
        children: [
          if (widget.album.thumbnailUrl != null)
            Image.network(widget.album.thumbnailUrl!, width: 200, height: 200, fit: BoxFit.cover),
          const SizedBox(height: 16),
          Text(widget.album.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Text(widget.album.artistName, style: const TextStyle(fontSize: 16, color: Colors.white70)),
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
                    leading: Text("${index + 1}", style: const TextStyle(color: Colors.white54)),
                    title: Text(track.title, style: const TextStyle(color: Colors.white)),
                    subtitle: Text(track.artistName, style: const TextStyle(color: Colors.white54)),
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
