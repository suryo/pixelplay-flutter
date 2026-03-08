import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/screens/playlist_detail_screen.dart';

class PlaylistScreen extends StatelessWidget {
  const PlaylistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final playlists = provider.customPlaylists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists', style: TextStyle(fontWeight: FontWeight.bold)),
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
          if (playlists.isEmpty)
            const Center(child: Text('No Playlists yet', style: TextStyle(color: Colors.white38)))
          else
            ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: playlists.length,
              itemBuilder: (context, index) {
                final name = playlists.keys.elementAt(index);
                final itemsPaths = playlists[name]!;
                return Card(
                  color: Colors.white.withOpacity(0.05),
                  child: ListTile(
                    leading: const Icon(Icons.playlist_play, color: Color(0xFF6C63FF)),
                    title: Text(name),
                    subtitle: Text('${itemsPaths.length} items'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PlaylistDetailScreen(playlistName: name),
                        ),
                      );
                    },
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.white24),
                          onSelected: (value) {
                            if (value == 'rename') {
                              _showRenamePlaylistDialog(context, provider, name);
                            } else if (value == 'delete') {
                              _showDeleteConfirmDialog(context, provider, name);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(value: 'rename', child: Text('Rename')),
                            const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
                          ],
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white24),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreatePlaylistDialog(context, provider),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add_circle_outline, color: Colors.white),
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MediaProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B2F),
        title: const Text('New Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist Name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createPlaylist(controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showRenamePlaylistDialog(BuildContext context, MediaProvider provider, String currentName) {
    final controller = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B2F),
        title: const Text('Rename Playlist'),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'New Playlist Name',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.renamePlaylist(currentName, controller.text);
                Navigator.pop(context);
              }
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmDialog(BuildContext context, MediaProvider provider, String name) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B2F),
        title: const Text('Delete Playlist'),
        content: Text('Are you sure you want to delete "$name"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deletePlaylist(name);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
