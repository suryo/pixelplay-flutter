import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class ArtistScreen extends StatelessWidget {
  const ArtistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ARTISTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          final artistsMap = provider.artists;
          if (artistsMap.isEmpty) {
            return const Center(child: Text('No Artists Found', style: TextStyle(color: Colors.white38)));
          }

          final artistNames = artistsMap.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: artistNames.length,
            itemBuilder: (context, index) {
              final name = artistNames[index];
              final items = artistsMap[name]!;
              final albumsCount = items.map((e) => e.album ?? 'Unknown').toSet().length;
              
              return ListTile(
                onTap: () => _showArtistItems(context, name, items, provider),
                leading: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  child: Icon(
                    Icons.person_rounded,
                    color: name == 'Unknown Artist' ? Colors.white12 : const Color(0xFF00E676),
                  ),
                ),
                title: Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                ),
                subtitle: Text(
                  '${items.length} tracks • $albumsCount albums',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
              );
            },
          );
        },
      ),
    );
  }

  void _showArtistItems(BuildContext context, String artistName, List<MediaItem> items, MediaProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(artistName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
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
                  item.album ?? 'Unknown Album',
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
