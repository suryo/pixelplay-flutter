import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pixelplay/components/glass_box.dart';
import 'package:pixelplay/screens/web_movie_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class StreamingScreen extends StatefulWidget {
  final String sourceName;
  final String apiUrl;

  const StreamingScreen({super.key, required this.sourceName, required this.apiUrl});

  @override
  State<StreamingScreen> createState() => _StreamingScreenState();
}

class _StreamingScreenState extends State<StreamingScreen> {
  List<dynamic> _movies = [];
  bool _isLoading = true;
  int _currentPage = 1;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchMovies();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMore();
      }
    });
  }

  Future<void> _fetchMovies() async {
    setState(() => _isLoading = true);
    try {
      final url = widget.apiUrl.replaceAll('page=1', 'page=$_currentPage');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['success'] == true && data['data'] != null) {
            _movies = data['data'];
          } else if (data['recommendList'] != null && data['recommendList']['records'] != null) {
            _movies = data['recommendList']['records'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('Error fetching movies: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    _currentPage++;
    try {
      final url = widget.apiUrl.replaceAll('page=1', 'page=$_currentPage');
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          if (data['success'] == true && data['data'] != null) {
            _movies.addAll(data['data']);
          } else if (data['recommendList'] != null && data['recommendList']['records'] != null) {
            _movies.addAll(data['recommendList']['records']);
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading more: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.sourceName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading && _movies.isEmpty
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
          : Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.65,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _movies.length,
                itemBuilder: (context, index) {
                  final movie = _movies[index];
                  return _buildMovieCard(movie);
                },
              ),
            ),
    );
  }

  String _ensureHttps(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('//')) return 'https:$url';
    if (!url.startsWith('http')) return 'https://$url';
    return url;
  }

  Future<void> _playMovie(dynamic movie) async {
    String title = movie['title'] ?? movie['bookName'] ?? 'Unknown';
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF00E676))),
    );

    // For DramaBos items, we don't have a direct player API, so send them to the detail page.
    if (movie['bookId'] != null) {
      if (mounted) Navigator.pop(context);
      final playerUrl = 'https://dramabox.dramabos.my.id/?bookId=${movie['bookId']}';
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => WebMoviePlayer(
            url: playerUrl,
            title: title,
          ),
        ),
      );
      return;
    }
    
    try {
      final detailUrl = 'https://zeldvorik.ru/rebahin21/api.php?action=detail&slug=${movie['slug']}';
      final response = await http.get(Uri.parse(detailUrl));
      
      if (mounted) Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data']['player_url'] != null) {
          final playerUrl = _ensureHttps(data['data']['player_url']);
          
          if (mounted && playerUrl.isNotEmpty) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => WebMoviePlayer(
                  url: playerUrl,
                  title: title,
                ),
              ),
            );
          }
          return;
        }
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to get streaming link. Try again later.')),
        );
      }
    } catch (e) {
      if (mounted) {
        if (Navigator.canPop(context)) Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
      debugPrint('Error playing movie: $e');
    }
  }

  Widget _buildMovieCard(dynamic movie) {
    String title = movie['title'] ?? movie['bookName'] ?? 'Unknown';
    title = title.replaceAll(RegExp(r'\s+'), ' ').trim();
    final thumbnailUrl = _ensureHttps(movie['thumbnail'] ?? movie['coverWap']);
    final rating = movie['rating'] ?? 'N/A';
    final year = movie['year'] ?? '';
    
    return GestureDetector(
      onTap: () => _playMovie(movie),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbnailUrl.isNotEmpty)
                    Image.network(
                      thumbnailUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: Colors.white.withOpacity(0.05),
                        child: const Center(child: Icon(Icons.movie, size: 40, color: Colors.white10)),
                      ),
                    )
                  else
                    Container(
                      color: Colors.white.withOpacity(0.05),
                      child: const Center(child: Icon(Icons.movie, size: 40, color: Colors.white10)),
                    ),
                  if (rating != 'N/A')
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white10, width: 0.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.star, color: Colors.amber, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              rating,
                              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 8, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    if (year.isNotEmpty)
                      Text(year, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                    if (year.isNotEmpty)
                      const Text(' • ', style: TextStyle(color: Colors.white12, fontSize: 11)),
                    Text(widget.sourceName.split(' ').first, style: const TextStyle(color: Color(0xFF00E676), fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
