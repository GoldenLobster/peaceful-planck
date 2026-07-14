import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
        final decoded = jsonDecode(jsonStr);
        setState(() {
          _results = SearchResults.fromJson(decoded as List<dynamic>);
        });
      } else {
        setState(() {
          _error = 'Failed to fetch results';
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

    final songs = _results!.songs;
    if (songs.isEmpty) {
      return const Center(
        child: Text("No results found", style: TextStyle(color: Colors.white54, fontSize: 16)),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      itemBuilder: (context, index) {
        final song = songs[index];
        return ListTile(
          leading: song.thumbnailUrl != null 
            ? ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Image.network(song.thumbnailUrl!, width: 48, height: 48, fit: BoxFit.cover),
              )
            : const Icon(Icons.music_note, color: Colors.white54),
          title: Text(song.title, style: const TextStyle(color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(song.artistName, style: const TextStyle(color: Colors.white54), maxLines: 1, overflow: TextOverflow.ellipsis),
          onTap: () {
            ref.read(playerProvider.notifier).play(song);
          },
        );
      },
    );
  }
}
