import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ALBUMS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          final albumsMap = provider.albums;
          if (albumsMap.isEmpty) {
            return const Center(child: Text('No Albums Found', style: TextStyle(color: Colors.white38)));
          }

          final albumNames = albumsMap.keys.toList()..sort();

          return GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.8,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: albumNames.length,
            itemBuilder: (context, index) {
              final name = albumNames[index];
              final items = albumsMap[name]!;
              final artist = items.first.artist ?? 'Various Artists';
              
              return GestureDetector(
                onTap: () => _showAlbumItems(context, name, items, provider),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.05)),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.album_rounded,
                            size: 80,
                            color: name == 'Unknown Album' ? Colors.white12 : const Color(0xFF00E676).withOpacity(0.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    Text(
                      artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    Text(
                      '${items.length} items',
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 10),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAlbumItems(BuildContext context, String albumName, List<MediaItem> items, MediaProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(albumName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
            backgroundColor: Colors.black,
            elevation: 0,
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isCurrent = provider.currentItem == item;
              
              return ListTile(
                onTap: () => provider.playItem(item),
                leading: Container(
                   width: 40,
                   height: 40,
                   decoration: BoxDecoration(
                     color: isCurrent ? const Color(0xFF00E676).withOpacity(0.1) : Colors.white.withOpacity(0.05),
                     borderRadius: BorderRadius.circular(4),
                   ),
                   child: Icon(
                     item.type == MediaType.audio ? Icons.music_note : Icons.movie,
                     color: isCurrent ? const Color(0xFF00E676) : Colors.white24,
                     size: 20,
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
                  item.artist ?? 'Unknown Artist',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: Text(
                   _formatDuration(item.duration),
                   style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration? d) {
    if (d == null || d.inSeconds <= 0) return '--:--';
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}
