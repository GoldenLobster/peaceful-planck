import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/native_bridge/youtube_bridge.dart';
import '../../data/models/search_result.dart';
import '../../data/models/song.dart';
import '../providers/player_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  SearchResults? _results;
  String _error = '';

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    setState(() {
      _isLoading = true;
      _error = '';
      _results = null;
    });

    try {
      final jsonStr = await YouTubeBridge.search(query);
      if (jsonStr != null) {
        if (jsonStr.startsWith("ERROR:")) {
            setState(() {
                _error = jsonStr.replaceFirst("ERROR:", "");
                _isLoading = false;
            });
            return;
        }
        final decoded = jsonDecode(jsonStr);
        setState(() {
          _results = SearchResults.fromJson(decoded as List<dynamic>);
        });
      } else {
        setState(() {
          _error = 'Failed to fetch results (null from bridge)';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error parsing results: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search songs, albums...',
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: IconButton(
              icon: const Icon(Icons.search, color: Colors.white),
              onPressed: () => _performSearch(_controller.text),
            ),
          ),
          onSubmitted: _performSearch,
          textInputAction: TextInputAction.search,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error.isNotEmpty) {
      return Center(
        child: Text(_error, style: const TextStyle(color: Colors.redAccent)),
      );
    }

    if (_results == null) {
      return const Center(
        child: Text(
          "Search for your favorite music",
          style: TextStyle(color: Colors.white54, fontSize: 16),
        ),
      );
    }

    if (_results!.songs.isEmpty && _results!.albums.isEmpty && _results!.artists.isEmpty && _results!.playlists.isEmpty) {
      return const Center(
        child: Text("No results found", style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView(
      children: [
        if (_results!.songs.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(16), child: Text("Songs", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ..._results!.songs.map((song) => ListTile(
            leading: song.thumbnailUrl != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(song.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover))
              : const Icon(Icons.music_note, color: Colors.white54),
            title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(song.artistName, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => ref.read(playerProvider.notifier).play(song),
          )),
        ],
        if (_results!.albums.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(16), child: Text("Albums", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ..._results!.albums.map((album) => ListTile(
            leading: album.thumbnailUrl != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(album.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover))
              : const Icon(Icons.album, color: Colors.white54),
            title: Text(album.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(album.artistName, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => context.push('/album', extra: album),
          )),
        ],
        if (_results!.artists.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(16), child: Text("Artists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ..._results!.artists.map((artist) => ListTile(
            leading: artist.thumbnailUrl != null 
              ? ClipOval(child: Image.network(artist.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover))
              : const Icon(Icons.person, color: Colors.white54),
            title: Text(artist.name, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: const Text("Artist", style: TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => context.push('/artist', extra: artist),
          )),
        ],
        if (_results!.playlists.isNotEmpty) ...[
          const Padding(padding: EdgeInsets.all(16), child: Text("Playlists", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
          ..._results!.playlists.map((playlist) => ListTile(
            leading: playlist.thumbnailUrl != null 
              ? ClipRRect(borderRadius: BorderRadius.circular(4), child: Image.network(playlist.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover))
              : const Icon(Icons.playlist_play, color: Colors.white54),
            title: Text(playlist.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(playlist.author ?? "Playlist", style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => context.push('/playlist', extra: playlist),
          )),
        ],
      ],
    );
  }
}
