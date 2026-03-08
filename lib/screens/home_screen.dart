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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0F0F1A),
                  Color(0xFF1B1B2F),
                  Color(0xFF0F0F1A),
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildQuickMenu(context),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Text(
                    'RECENT MEDIA',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(child: _buildMediaList(context)),
              ],
            ),
          ),
          
          _buildMiniPlayer(context),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.read<MediaProvider>().pickMedia(),
        backgroundColor: const Color(0xFF6C63FF),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildQuickMenu(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.8,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _menuItem(
            context, 
            'Playlists', 
            FontAwesomeIcons.listOl, 
            const Color(0xFF6C63FF),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistScreen())),
          ),
          _menuItem(
            context, 
            'Equalizer', 
            FontAwesomeIcons.sliders, 
            const Color(0xFF00D2FF),
            () => _showEqualizer(context),
          ),
          _menuItem(
            context, 
            'Visualizer', 
            FontAwesomeIcons.signal, 
            const Color(0xFF8E2DE2),
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VisualizerScreen())),
          ),
          _menuItem(
            context, 
            'Streaming', 
            FontAwesomeIcons.globe, 
            const Color(0xFF00FF87),
            () => _showWebSelectionDialog(context),
          ),
          _menuItem(
            context, 
            'About', 
            FontAwesomeIcons.circleInfo, 
            const Color(0xFFEC008C),
            () => _showAboutApp(context),
          ),
        ],
      ),
    );
  }

  void _showWebSelectionDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBox(
        borderRadius: 20,
        blur: 20,
        opacity: 0.1,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('STREAMING SOURCES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(FontAwesomeIcons.circlePlay, color: Color(0xFF00FF87)),
                title: const Text('DramaBos', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StreamingScreen(
                    sourceName: 'DramaBos',
                    apiUrl: 'https://dramabox.dramabos.my.id/api/v1/homepage?page=1&lang=in',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.film, color: Color(0xFF00FF87)),
                title: const Text('Rebahin Movies', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StreamingScreen(
                    sourceName: 'Rebahin Movies',
                    apiUrl: 'https://zeldvorik.ru/rebahin21/api.php?action=movies&page=1',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.film, color: Color(0xFF00FF87)),
                title: const Text('Rebahin Series', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StreamingScreen(
                    sourceName: 'Rebahin Series',
                    apiUrl: 'https://zeldvorik.ru/rebahin21/api.php?action=series&page=1',
                  )));
                },
              ),
              ListTile(
                leading: const Icon(FontAwesomeIcons.fire, color: Color(0xFFFF5F6D)),
                title: const Text('Trending Now', style: TextStyle(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const StreamingScreen(
                    sourceName: 'Trending',
                    apiUrl: 'https://zeldvorik.ru/rebahin21/api.php?action=trending&page=1',
                  )));
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuItem(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: GlassBox(
        borderRadius: 16,
        blur: 10,
        opacity: 0.1,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEqualizer(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassBox(
        borderRadius: 20,
        blur: 20,
        opacity: 0.1,
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('EQUALIZER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, color: Colors.white)),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: Consumer<MediaProvider>(
                  builder: (context, provider, _) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: 10,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          Expanded(
                            child: RotatedBox(
                              quarterTurns: 3,
                              child: SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 2,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                ),
                                child: Slider(
                                  value: provider.equalizerGains[index],
                                  min: -10,
                                  max: 10,
                                  onChanged: (val) => provider.updateEqualizer(index, val),
                                ),
                              ),
                            ),
                          ),
                          Text(
                            ['31','62','125','250','500','1k','2k','4k','8k','16k'][index],
                            style: const TextStyle(fontSize: 8, color: Colors.white38),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutApp(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassBox(
          borderRadius: 20,
          opacity: 0.8,
          color: const Color(0xFF1B1B2F),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(FontAwesomeIcons.play, size: 50, color: Color(0xFF6C63FF)),
                const SizedBox(height: 20),
                const Text(
                  'PixelPlay v1.0',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Your premium media hub for all music and video extensions.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 20),
                const Divider(color: Colors.white10),
                const SizedBox(height: 10),
                const Text(
                  'Developed with ❤️ in Flutter',
                  style: TextStyle(fontSize: 10, color: Colors.white24),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('CLOSE', style: TextStyle(color: Color(0xFF6C63FF))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PixelPlay',
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Your Ultimate Media Player',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: Icon(
                    provider.showHidden ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white60,
                  ),
                  onPressed: () => provider.toggleShowHidden(),
                  tooltip: 'Show/Hide Hidden Files',
                ),
                _buildMenu(context, provider),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenu(BuildContext context, MediaProvider provider) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_horiz, color: Colors.white),
      onSelected: (value) {
        if (value == 'scan') {
          provider.autoScanMedia();
        } else if (value == 'playlists') {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const PlaylistScreen()));
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'scan', child: Text('Rescan Media')),
        const PopupMenuItem(value: 'playlists', child: Text('Playlists')),
      ],
    );
  }

  Widget _buildMediaList(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) {
        final list = provider.playlist;
        if (list.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(FontAwesomeIcons.compactDisc, size: 100, color: Colors.white.withOpacity(0.1)),
                const SizedBox(height: 20),
                const Text('No Media Found', style: TextStyle(color: Colors.white38)),
                const SizedBox(height: 8),
                const Text('Tap "+" to select files or rescan', style: TextStyle(color: Colors.white24)),
              ],
            ),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
          itemCount: list.length,
          itemBuilder: (context, index) {
            final item = list[index];
            final isCurrent = provider.currentItem == item;
            
            return Card(
              color: Colors.transparent,
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                onTap: () => provider.playItem(item),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tileColor: isCurrent ? Colors.white.withOpacity(0.05) : Colors.transparent,
                leading: GlassBox(
                  borderRadius: 12,
                  blur: 5,
                  opacity: 0.1,
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    child: Icon(
                      item.type == MediaType.audio ? FontAwesomeIcons.music : FontAwesomeIcons.film,
                      color: isCurrent ? const Color(0xFF6C63FF) : (item.isHidden ? Colors.white24 : Colors.white60),
                      size: 20,
                    ),
                  ),
                ),
                title: Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? const Color(0xFF6C63FF) : (item.isHidden ? Colors.white38 : Colors.white),
                  ),
                ),
                subtitle: Text(
                  '${item.extension?.toUpperCase() ?? 'FILE'}${item.isHidden ? " • HIDDEN" : ""}',
                  style: const TextStyle(color: Colors.white24, fontSize: 10),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isCurrent && provider.isPlaying)
                      const Icon(Icons.equalizer, color: Color(0xFF6C63FF), size: 18),
                    _buildItemMenu(context, provider, item),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildItemMenu(BuildContext context, MediaProvider provider, MediaItem item) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Colors.white24, size: 20),
      onSelected: (value) {
        if (value == 'hide') {
          provider.hideItem(item);
        } else if (value == 'unhide') {
          provider.unhideItem(item);
        } else if (value == 'delete') {
          provider.removeMedia(item);
        } else if (value == 'add_playlist') {
          _showAddToPlaylistDialog(context, provider, item);
        }
      },
      itemBuilder: (context) => [
        if (!item.isHidden) const PopupMenuItem(value: 'hide', child: Text('Hide File')),
        if (item.isHidden) const PopupMenuItem(value: 'unhide', child: Text('Unhide File')),
        const PopupMenuItem(value: 'add_playlist', child: Text('Add to Playlist')),
        const PopupMenuItem(value: 'delete', child: Text('Remove from List', style: TextStyle(color: Colors.redAccent))),
      ],
    );
  }

  void _showAddToPlaylistDialog(BuildContext context, MediaProvider provider, MediaItem media) {
    final list = provider.customPlaylists.keys.toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No playlists available. Create one first!')));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1B1B2F),
        title: const Text('Add to Playlist'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: list.map((name) => ListTile(
            title: Text(name),
            onTap: () {
              provider.addToPlaylist(name, media);
              Navigator.pop(context);
            },
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildMiniPlayer(BuildContext context) {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) {
        if (provider.currentItem == null) return const SizedBox.shrink();
        
        return Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PlayerScreen()),
              );
            },
            child: GlassBox(
              blur: 15,
              opacity: 0.15,
              borderRadius: 20,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.currentItem!.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: provider.duration.inMilliseconds > 0 
                                ? provider.position.inMilliseconds / provider.duration.inMilliseconds 
                                : 0,
                            backgroundColor: Colors.white10,
                            valueColor: const AlwaysStoppedAnimation(Color(0xFF6C63FF)),
                            minHeight: 2,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      icon: Icon(
                        provider.isPlaying ? Icons.pause : Icons.play_arrow,
                        color: Colors.white,
                      ),
                      onPressed: () => provider.togglePlayback(),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
