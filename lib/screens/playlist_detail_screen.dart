import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';
import 'package:pixelplay/components/glass_box.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlaylistDetailScreen extends StatelessWidget {
  final String playlistName;

  const PlaylistDetailScreen({super.key, required this.playlistName});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final paths = provider.customPlaylists[playlistName] ?? [];
    
    // Filter playlist items from the main playlist based on paths
    final items = provider.playlist.where((item) => paths.contains(item.path)).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(playlistName, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F1A), Color(0xFF1B1B2F)],
              ),
            ),
          ),
          if (items.isEmpty)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No items in this playlist', style: TextStyle(color: Colors.white38)),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => _showAddItemsDialog(context, provider),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Media'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Icon(
                      item.type == MediaType.audio ? FontAwesomeIcons.music : FontAwesomeIcons.film,
                      color: Colors.white60,
                      size: 20,
                    ),
                    title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(item.extension?.toUpperCase() ?? 'FILE', style: const TextStyle(fontSize: 10, color: Colors.white24)),
                    onTap: () => provider.playItem(item),
                    trailing: IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                      onPressed: () {
                        // We need a removeFromPlaylist method in provider
                        provider.removeFromPlaylist(playlistName, item.path);
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: items.isNotEmpty 
        ? FloatingActionButton(
            onPressed: () => _showAddItemsDialog(context, provider),
            backgroundColor: const Color(0xFF6C63FF),
            child: const Icon(Icons.add_to_photos, color: Colors.white),
          )
        : null,
    );
  }

  void _showAddItemsDialog(BuildContext context, MediaProvider provider) {
    final allMedia = provider.playlist;
    final playlistPaths = provider.customPlaylists[playlistName] ?? [];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => GlassBox(
        borderRadius: 20,
        blur: 30,
        opacity: 0.9,
        color: const Color(0xFF1B1B2F),
        child: DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, controller) => Column(
            children: [
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Add to Playlist', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: allMedia.length,
                  itemBuilder: (context, index) {
                    final item = allMedia[index];
                    final isAlreadyIn = playlistPaths.contains(item.path);

                    return ListTile(
                      leading: Icon(
                        item.type == MediaType.audio ? FontAwesomeIcons.music : FontAwesomeIcons.film,
                        color: isAlreadyIn ? Colors.greenAccent : Colors.white30,
                      ),
                      title: Text(item.title, style: TextStyle(color: isAlreadyIn ? Colors.white30 : Colors.white)),
                      trailing: Checkbox(
                        value: isAlreadyIn,
                        activeColor: const Color(0xFF6C63FF),
                        onChanged: (val) {
                          if (val == true) {
                            provider.addToPlaylist(playlistName, item);
                          } else {
                            provider.removeFromPlaylist(playlistName, item.path);
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
