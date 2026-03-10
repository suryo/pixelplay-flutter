import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/screens/player_screen.dart';
import 'package:pixelplay/components/glass_box.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:pixelplay/models/media_item.dart';

import 'package:pixelplay/screens/playlist_screen.dart';
import 'package:pixelplay/screens/visualizer_screen.dart';
import 'package:pixelplay/screens/web_movie_player.dart';
import 'package:pixelplay/screens/streaming_screen.dart';

String _formatDuration(Duration d) {
  if (d.inSeconds <= 0) return '0:00';
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return '$m:${s.toString().padLeft(2, '0')}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const _QueueHeader(),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(icon: const Icon(Icons.close, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          const _QueueControls(),
          Expanded(child: _buildMediaList(context)),
          _buildSearchQueue(),
        ],
      ),
    );
  }

  Widget _buildSearchQueue() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search, color: Colors.white38, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search in this queue...',
                hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
              ),
              style: const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediaList(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) {
        final allItems = provider.playlist;
        final list = _searchQuery.isEmpty 
            ? allItems 
            : allItems.where((item) => item.title.toLowerCase().contains(_searchQuery)).toList();

        if (list.isEmpty) {
          return Center(child: Text(_searchQuery.isEmpty ? 'Empty Queue' : 'No matches found', style: const TextStyle(color: Colors.white38)));
        }
        
        return ListView.builder(
          padding: EdgeInsets.zero,
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final isCurrent = provider.currentItem == item;
            
            return Container(
              height: 70,
              decoration: BoxDecoration(
                border: isCurrent ? Border.all(color: const Color(0xFF00E676).withOpacity(0.5), width: 1) : null,
                borderRadius: isCurrent ? BorderRadius.circular(8) : null,
                color: isCurrent ? const Color(0xFF00E676).withOpacity(0.05) : Colors.transparent,
              ),
              margin: isCurrent ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2) : EdgeInsets.zero,
              child: ListTile(
                onTap: () => provider.playItem(item),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                dense: true,
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.menu, 
                      color: isCurrent ? const Color(0xFF00E676) : Colors.white24, 
                      size: 20
                    ),
                    const SizedBox(width: 12),
                    _buildThumbnail(item, isCurrent),
                  ],
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isCurrent ? const Color(0xFF00E676) : Colors.white,
                    fontSize: 14,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.artist ?? 'Unknown Artist',
                      style: TextStyle(
                        color: isCurrent ? const Color(0xFF00E676).withOpacity(0.8) : Colors.white38, 
                        fontSize: 11
                      ),
                    ),
                    Text(
                      item.album ?? 'Unknown Album',
                      style: const TextStyle(color: Color(0xFF00E676), fontSize: 10),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.duration != null ? _formatDuration(item.duration!) : '0:00',
                      style: const TextStyle(color: Colors.white38, fontSize: 11),
                    ),
                    const SizedBox(width: 8),
                    _buildItemMenu(context, provider, item, isCurrent),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildThumbnail(MediaItem item, bool isCurrent) {
    return Container(
      width: 45,
      height: 45,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(4),
      ),
      alignment: Alignment.center,
      child: Stack(
        children: [
          Center(
            child: Icon(
              item.type == MediaType.audio ? Icons.play_arrow_rounded : Icons.videocam_rounded,
              color: Colors.white24,
              size: 20,
            ),
          ),
          if (isCurrent)
             const Center(
               child: Icon(Icons.play_arrow_rounded, color: Color(0xFF00E676), size: 24),
             ),
        ],
      ),
    );
  }

  Widget _buildItemMenu(BuildContext context, MediaProvider provider, MediaItem item, bool isCurrent) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isCurrent ? const Color(0xFF00E676) : Colors.white10,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        icon: Icon(Icons.more_horiz, color: isCurrent ? Colors.black : Colors.white70, size: 16),
        padding: EdgeInsets.zero,
        onPressed: () => _showItemOptions(context, provider, item),
      ),
    );
  }

  void _showItemOptions(BuildContext context, MediaProvider provider, MediaItem item) {
     showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => _SongOptionSheet(item: item, provider: provider),
    );
  }
}

class _QueueHeader extends StatelessWidget {
  const _QueueHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    return Row(
      children: [
        GestureDetector(
          onTap: () => _showPlaylistMenu(context, provider),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  provider.currentQueueName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 16),
              ],
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.add, color: Color(0xFF00E676), size: 20),
          onPressed: () => _showCreatePlaylistDialog(context, provider),
        ),
      ],
    );
  }

  void _showPlaylistMenu(BuildContext context, MediaProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Select Queue / Playlist',
              style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined, color: Colors.white70),
            title: const Text('Library Queue (All Tracks)', style: TextStyle(color: Colors.white)),
            onTap: () {
              provider.resetToLibrary();
              Navigator.pop(context);
            },
          ),
          ...provider.customPlaylists.keys.map((name) => ListTile(
            leading: const Icon(Icons.playlist_play, color: Color(0xFF00E676)),
            title: Text(name, style: const TextStyle(color: Colors.white)),
            onTap: () {
              provider.loadPlaylist(name);
              Navigator.pop(context);
            },
          )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _showCreatePlaylistDialog(BuildContext context, MediaProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Create New Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.createPlaylist(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Playlist "${controller.text}" created!')),
                );
              }
            },
            child: const Text('Create', style: TextStyle(color: Color(0xFF00E676))),
          ),
        ],
      ),
    );
  }
}

class _QueueControls extends StatelessWidget {
  const _QueueControls();

  @override
  Widget build(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(provider.isPlaying ? Icons.pause : Icons.play_arrow, color: Colors.white70, size: 24),
                  onPressed: () => provider.togglePlayback(),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.short_text, color: Colors.white70, size: 24),
                const Spacer(),
                Text('${provider.playlist.length} / ${provider.playlist.length}', style: const TextStyle(color: Colors.white30, fontSize: 11)),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.save_outlined, color: Color(0xFF00E676), size: 20),
                  onPressed: () => _showSavePlaylistDialog(context, provider),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.more_horiz, color: Colors.white70, size: 20),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.alarm, color: Colors.white30, size: 12),
                const SizedBox(width: 4),
                _buildTotalDuration(provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalDuration(MediaProvider provider) {
    int totalSec = 0;
    for (var item in provider.playlist) {
      totalSec += item.duration?.inSeconds ?? 0;
    }
    final d = Duration(seconds: totalSec);
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    final timeStr = h > 0 ? '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}' : '$m:${s.toString().padLeft(2, '0')}';
    return Text(timeStr, style: const TextStyle(color: Colors.white30, fontSize: 11));
  }

  void _showSavePlaylistDialog(BuildContext context, MediaProvider provider) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Save Queue as Playlist', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Playlist name...',
            hintStyle: TextStyle(color: Colors.white24),
            enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
            focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              if (controller.text.isNotEmpty) {
                provider.saveQueueAsPlaylist(controller.text);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Playlist "${controller.text}" saved!')));
              }
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00E676))),
          ),
        ],
      ),
    );
  }
}

class _SongOptionSheet extends StatelessWidget {
  final MediaItem item;
  final MediaProvider provider;

  const _SongOptionSheet({required this.item, required this.provider});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.favorite_border, color: Colors.white70, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _optionTile(context, Icons.info_outline, 'Song info', () => _showSongInfo(context)),
                _optionTile(context, Icons.remove_circle_outline, 'Remove from this queue', () {
                   provider.removeMedia(item);
                   Navigator.pop(context);
                }, color: Colors.redAccent),
                _optionTile(context, Icons.play_arrow_outlined, 'Play after current song', () {
                   provider.playAfterCurrent(item);
                   Navigator.pop(context);
                }),
                _optionTile(context, Icons.playlist_add, 'Add to a queue', () => _showAddToQueueDialog(context)),
                _optionTile(context, Icons.add_to_photos_outlined, 'Add to playlists', () => _showAddToPlaylist(context)),
                _optionTile(context, Icons.play_circle_outline, 'Preview', () {
                   provider.playItem(item);
                   Navigator.pop(context);
                }),
                _optionTile(context, Icons.edit_outlined, 'Edit tags', () => _showEditTagsDialog(context)),
                _optionTile(context, Icons.speed, 'Play speed and Pitch', () => _showPlaybackSpeedDialog(context)),
                _optionTile(context, Icons.delete_outline, 'Delete permanently', () => _showDeleteDialog(context), color: Colors.redAccent),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTagsDialog(BuildContext context) {
    final titleC = TextEditingController(text: item.title);
    final artistC = TextEditingController(text: item.artist);
    final albumC = TextEditingController(text: item.album);
    
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Edit Tags', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _editField(titleC, 'Title'),
            _editField(artistC, 'Artist'),
            _editField(albumC, 'Album'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              provider.updateMediaMetadata(item, title: titleC.text, artist: artistC.text, album: albumC.text);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Color(0xFF00E676))),
          ),
        ],
      ),
    );
  }

  void _showPlaybackSpeedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Playback Speed', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _speedOption('0.5x', 0.5),
            _speedOption('1.0x (Normal)', 1.0),
            _speedOption('1.5x', 1.5),
            _speedOption('2.0x', 2.0),
          ],
        ),
      ),
    );
  }

  void _showAddToQueueDialog(BuildContext context) {
    // For now, this just means "Add to the end of the queue" but since it's already in queue
    // we just show a message. In "Musicolet", it can mean different queues.
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item is already in the current media library queue.')));
    Navigator.pop(context);
  }

  Widget _editField(TextEditingController c, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: hint,
          labelStyle: const TextStyle(color: Colors.white38),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF00E676))),
        ),
      ),
    );
  }

  Widget _speedOption(String label, double value) {
    return ListTile(
      title: Text(label, style: const TextStyle(color: Colors.white)),
      onTap: () {
        provider.setRate(value);
        Navigator.pop(provider.player.state.playing ? provider.player.state.playing as dynamic : null); // Simple pop
      },
    );
  }

  void _showSongInfo(BuildContext context) {
    String size = 'Unknown';
    try {
      final file = File(item.path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) size = '$bytes B';
        else if (bytes < 1024 * 1024) size = '${(bytes / 1024).toStringAsFixed(1)} KB';
        else size = '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Song Info', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Title', item.title),
            _infoRow('Artist', item.artist ?? 'Unknown'),
            _infoRow('Album', item.album ?? 'Unknown'),
            _infoRow('Duration', _formatDuration(item.duration ?? Duration.zero)),
            _infoRow('Size', size),
            _infoRow('Path', item.path),
            _infoRow('Type', item.type.toString().split('.').last.toUpperCase()),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK', style: TextStyle(color: Color(0xFF00E676)))),
        ],
      ),
    );
  }

  void _showAddToPlaylist(BuildContext context) {
    if (provider.customPlaylists.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No custom playlists found. Create one first!')));
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF161616),
      builder: (_) => ListView.builder(
        shrinkWrap: true,
        itemCount: provider.customPlaylists.length,
        itemBuilder: (_, i) {
          final name = provider.customPlaylists.keys.elementAt(i);
          return ListTile(
            title: Text(name, style: const TextStyle(color: Colors.white)),
            onTap: () {
              provider.addToPlaylist(name, item);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added to "$name"')));
            },
          );
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        title: const Text('Delete File', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text('Are you sure you want to delete this file permanently?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel', style: TextStyle(color: Colors.white38))),
          TextButton(
            onPressed: () {
              provider.removeMedia(item);
              Navigator.pop(context);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Media removed from library')));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.white38, fontSize: 10)),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 13), overflow: TextOverflow.ellipsis, maxLines: 2),
        ],
      ),
    );
  }

  Widget _optionTile(BuildContext context, IconData icon, String label, VoidCallback onTap, {Color? color}) {
    return ListTile(
      leading: Icon(icon, color: color ?? Colors.white70, size: 20),
      title: Text(label, style: TextStyle(color: color ?? Colors.white, fontSize: 14)),
      dense: true,
      onTap: onTap,
    );
  }
}
