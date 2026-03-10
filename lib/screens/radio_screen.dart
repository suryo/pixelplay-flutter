import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  List<dynamic> _stations = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fetchStations();
  }

  Future<void> _fetchStations() async {
    setState(() => _isLoading = true);
    try {
      // Primary: German server (usually most stable)
      final response = await http.get(Uri.parse('https://de1.api.radio-browser.info/json/stations/search?countrycode=ID&limit=100&hidebroken=true&order=clickcount&reverse=true'));
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          _stations = data;
          _isLoading = false;
        });
      } else {
        // Fallback: Netherlands server
        final fallbackResponse = await http.get(Uri.parse('https://nl1.api.radio-browser.info/json/stations/search?countrycode=ID&limit=100&hidebroken=true'));
        if (fallbackResponse.statusCode == 200) {
          final List<dynamic> data = jsonDecode(fallbackResponse.body);
          setState(() {
            _stations = data;
            _isLoading = false;
          });
        } else {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Error fetching stations: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredStations = _stations.where((s) {
      final name = s['name'].toString().toLowerCase();
      return name.contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('ONLINE RADIO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search stations...',
                hintStyle: const TextStyle(color: Colors.white24),
                prefixIcon: const Icon(Icons.search, color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),
          Expanded(
            child: _isLoading 
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00E676)))
              : filteredStations.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.radio_outlined, size: 64, color: Colors.white10),
                        const SizedBox(height: 16),
                        Text(_searchQuery.isEmpty ? 'Failed to load stations' : 'No results for "$_searchQuery"', 
                          style: const TextStyle(color: Colors.white38)),
                        if (_searchQuery.isEmpty)
                          TextButton.icon(
                            onPressed: _fetchStations, 
                            icon: const Icon(Icons.refresh, color: Color(0xFF00E676)),
                            label: const Text('Try Again', style: TextStyle(color: Color(0xFF00E676))),
                          ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: filteredStations.length,
                    itemBuilder: (context, index) {
                      final station = filteredStations[index];
                      final name = station['name'] ?? 'Unknown Radio';
                      final tags = station['tags'] ?? '';
                      final favicon = station['favicon'] ?? '';

                      return Card(
                        color: Colors.white.withOpacity(0.05),
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          onTap: () => _playRadio(context, station),
                          leading: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: favicon.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    favicon,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(Icons.radio, color: Color(0xFF00E676)),
                                  ),
                                )
                              : const Icon(Icons.radio, color: Color(0xFF00E676)),
                          ),
                          title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                          subtitle: Text(
                            tags.isEmpty ? 'Live Stream' : tags,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.play_circle_fill, color: Color(0xFF00E676), size: 30),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _playRadio(BuildContext context, dynamic station) {
    final provider = context.read<MediaProvider>();
    final url = station['url_resolved'] ?? station['url'];
    
    if (url == null || url.isEmpty) return;

    final mediaItem = MediaItem(
      title: station['name'] ?? 'Online Radio',
      path: url,
      type: MediaType.audio,
      artist: station['country'] ?? 'Radio',
      album: 'Online Stream',
      thumbnail: (station['favicon'] != null && station['favicon'].toString().isNotEmpty) 
          ? station['favicon'] 
          : null,
    );

    provider.playItem(mediaItem);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing ${station['name']}'),
        duration: const Duration(seconds: 2),
        backgroundColor: const Color(0xFF00E676).withOpacity(0.9),
      ),
    );
  }
}
