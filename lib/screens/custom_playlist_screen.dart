import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('PLAYLISTS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
           IconButton(
             icon: const Icon(Icons.add_circle_outline, color: Color(0xFF00E676)),
             onPressed: () => _showCreatePlaylistDialog(context, context.read<MediaProvider>()),
           ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          final playlists = provider.customPlaylists;
          if (playlists.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.playlist_add, size: 64, color: Colors.white.withOpacity(0.1)),
                  const SizedBox(height: 16),
                  const Text('No playlists created yet', style: TextStyle(color: Colors.white38)),
                ],
              ),
            );
          }

          final names = playlists.keys.toList();

          return ListView.builder(
            itemCount: names.length,
            itemBuilder: (context, index) {
              final name = names[index];
              final paths = playlists[name]!;
              
              return ListTile(
                onTap: () => _showPlaylistItems(context, name, paths, provider),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.playlist_play, color: Color(0xFF00E676)),
                ),
                title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                subtitle: Text('${paths.length} items', style: const TextStyle(color: Colors.white38, fontSize: 12)),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white38),
                  color: const Color(0xFF161616),
                  onSelected: (val) {
                    if (val == 'delete') provider.deletePlaylist(name);
                    if (val == 'rename') _showRenameDialog(context, provider, name);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'rename', child: Text('Rename', style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MediaProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('New Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Name...',
            hintStyle: TextStyle(color: Colors.white24),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.createPlaylist(controller.text);
              Navigator.pop(context);
            }
          }, child: const Text('Create', style: TextStyle(color: Color(0xFF00E676)))),
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, MediaProvider provider, String oldName) {
    final controller = TextEditingController(text: oldName);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Rename Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () {
            if (controller.text.isNotEmpty) {
              provider.renamePlaylist(oldName, controller.text);
              Navigator.pop(context);
            }
          }, child: const Text('Rename', style: TextStyle(color: Color(0xFF00E676)))),
        ],
      ),
    );
  }

  void _showPlaylistItems(BuildContext context, String name, List<String> paths, MediaProvider provider) {
    // Find MediaItems matching these paths from the current library
    final items = provider.playlist.where((i) => paths.contains(i.path)).toList();
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(name.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            backgroundColor: Colors.black,
            actions: [
               IconButton(
                 icon: const Icon(Icons.play_circle_fill, color: Color(0xFF00E676)),
                 onPressed: () {
                    // Logic to "load" this playlist as the current queue
                    // For now we just play the first item
                    if (items.isNotEmpty) provider.playItem(items.first);
                 },
               ),
            ],
          ),
          body: ListView.builder(
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                onTap: () => provider.playItem(item),
                leading: const Icon(Icons.music_note, color: Colors.white24),
                title: Text(item.title, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text(item.artist ?? 'Unknown', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                trailing: IconButton(
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 18),
                  onPressed: () => provider.removeFromPlaylist(name, item.path),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
