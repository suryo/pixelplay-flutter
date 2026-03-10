import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<MediaItem> _searchResults = [];
  bool _hasSearched = false;

  void _onSearch(String query, List<MediaItem> allItems) {
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _hasSearched = false;
      });
      return;
    }

    final trimmedQuery = query.toLowerCase().trim();
    final results = allItems.where((item) {
      final title = item.title.toLowerCase();
      final artist = (item.artist ?? '').toLowerCase();
      final album = (item.album ?? '').toLowerCase();
      return title.contains(trimmedQuery) || 
             artist.contains(trimmedQuery) || 
             album.contains(trimmedQuery);
    }).toList();

    setState(() {
      _searchResults = results;
      _hasSearched = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('SEARCH', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _onSearch(val, provider.playlist),
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search, color: Colors.white38),
                      hintText: 'Search songs, artists, albums...',
                      hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 15),
                      suffixIcon: _searchController.text.isNotEmpty 
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _onSearch('', provider.playlist);
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _searchResults.isEmpty 
                  ? Center(
                      child: Text(
                        _hasSearched ? 'No results found' : 'Find your favorite media',
                        style: const TextStyle(color: Colors.white24),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final item = _searchResults[index];
                        final isCurrent = provider.currentItem == item;
                        
                        return ListTile(
                          onTap: () => provider.playItem(item),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: isCurrent ? const Color(0xFF00E676).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              item.type == MediaType.audio ? Icons.music_note : Icons.movie,
                              color: isCurrent ? const Color(0xFF00E676) : Colors.white24,
                            ),
                          ),
                          title: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isCurrent ? const Color(0xFF00E676) : Colors.white,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Text(
                            '${item.artist ?? 'Unknown Artist'} • ${item.album ?? 'Unknown Album'}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          trailing: Icon(
                            item.type == MediaType.audio ? Icons.audiotrack : Icons.movie,
                            size: 14,
                            color: Colors.white12,
                          ),
                        );
                      },
                    ),
              ),
            ],
          );
        },
      ),
    );
  }
}
