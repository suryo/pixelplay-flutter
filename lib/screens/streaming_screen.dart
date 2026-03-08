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
      backgroundColor: const Color(0xFF0C0C14),
      appBar: AppBar(
        title: Text(widget.sourceName, style: const TextStyle(fontWeight: FontWeight.bold)),
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
          if (_isLoading && _movies.isEmpty)
            const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          else
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: GridView.builder(
                controller: _scrollController,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.7,
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
        ],
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
    
    // For DramaBos items, we don't have a direct player API, so send them to the detail page.
    if (movie['bookId'] != null) {
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
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
    );

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
      child: GlassBox(
        borderRadius: 16,
        opacity: 0.1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (thumbnailUrl.isNotEmpty)
                      Image.network(
                        thumbnailUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(child: Icon(Icons.movie, size: 50, color: Colors.white24)),
                      )
                    else
                      const Center(child: Icon(Icons.movie, size: 50, color: Colors.white24)),
                    if (rating != 'N/A')
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black87,
                            borderRadius: BorderRadius.circular(4),
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
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white),
                  ),
                  if (year.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      year,
                      style: const TextStyle(color: Colors.white38, fontSize: 10),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
