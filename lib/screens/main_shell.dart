import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/screens/home_screen.dart';
import 'package:pixelplay/screens/player_screen.dart';
import 'package:pixelplay/screens/playlist_screen.dart';
import 'package:pixelplay/screens/streaming_screen.dart';
import 'package:pixelplay/screens/folder_screen.dart';
import 'package:pixelplay/screens/album_screen.dart';
import 'package:pixelplay/screens/artist_screen.dart';
import 'package:pixelplay/screens/radio_screen.dart';
import 'package:pixelplay/screens/global_search_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const PlayerScreen(),
    const StreamingHub(),
    const FolderScreen(),
    const AlbumScreen(),
    const ArtistScreen(),
    const PlaylistScreen(),
    const GlobalSearchScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: Colors.black,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniPlayerSlider(),
            BottomNavigationBar(
              currentIndex: _selectedIndex > 7 ? 0 : _selectedIndex,
              onTap: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.black,
              selectedItemColor: const Color(0xFF00E676),
              unselectedItemColor: Colors.white38,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.playlist_play), label: 'Queue'),
                BottomNavigationBarItem(icon: Icon(Icons.play_circle_outline), label: 'Play'),
                BottomNavigationBarItem(icon: Icon(Icons.cloud_outlined), label: 'Streaming'),
                BottomNavigationBarItem(icon: Icon(Icons.folder_open), label: 'Folders'),
                BottomNavigationBarItem(icon: Icon(Icons.album_outlined), label: 'Albums'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Artists'),
                BottomNavigationBarItem(icon: Icon(Icons.featured_play_list_outlined), label: 'Playlists'),
                BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniPlayerSlider() {
    return Consumer<MediaProvider>(
      builder: (context, provider, _) {
        if (provider.currentItem == null) return const SizedBox.shrink();
        final progress = provider.duration.inMilliseconds > 0 
            ? provider.position.inMilliseconds / provider.duration.inMilliseconds 
            : 0.0;
        
        return Container(
          height: 2,
          width: double.infinity,
          color: Colors.white10,
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress.clamp(0.0, 1.0),
            child: Container(color: const Color(0xFF00E676)),
          ),
        );
      },
    );
  }
}

class StreamingHub extends StatelessWidget {
  const StreamingHub({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('STREAMING SOURCES', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _sourceItem(
              context, 
              'Radio Online', 
              'Live International Stations', 
              Icons.radio, 
              Colors.purpleAccent,
              '',
              destination: const RadioScreen(),
            ),
            const SizedBox(height: 12),
            _sourceItem(
              context, 
              'DramaBos', 
              'Global Movies & Series', 
              Icons.language, 
              const Color(0xFF00E676),
              'https://dramabox.dramabos.my.id/api/v1/homepage?page=1&lang=in'
            ),
            const SizedBox(height: 12),
            _sourceItem(
              context, 
              'Rebahin Movies', 
              'Latest Cinema Movies', 
              Icons.movie_filter, 
              Colors.blueAccent,
              'https://zeldvorik.ru/rebahin21/api.php?action=movies&page=1'
            ),
            const SizedBox(height: 12),
            _sourceItem(
              context, 
              'Rebahin Series', 
              'TV Series & Drama', 
              Icons.tv_rounded, 
              Colors.orangeAccent,
              'https://zeldvorik.ru/rebahin21/api.php?action=series&page=1'
            ),
            const SizedBox(height: 12),
            _sourceItem(
              context, 
              'Trending Now', 
              'Hot & Popular Content', 
              Icons.whatshot, 
              Colors.redAccent,
              'https://zeldvorik.ru/rebahin21/api.php?action=trending&page=1'
            ),
          ],
        ),
      ),
    );
  }

  Widget _sourceItem(BuildContext context, String title, String subtitle, IconData icon, Color color, String url, {Widget? destination}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => destination ?? StreamingScreen(
          sourceName: title,
          apiUrl: url,
        )));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: Colors.white38, fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 16),
          ],
        ),
      ),
    );
  }
}
