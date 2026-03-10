import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class TagScreen extends StatelessWidget {
  const TagScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('TAGS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          // Group by extension/type as a simple "tag" implementation for now
          final Map<String, List<MediaItem>> tagsMap = {};
          for (var item in provider.playlist) {
            final tag = item.extension?.toUpperCase() ?? (item.type == MediaType.audio ? 'AUDIO' : 'VIDEO');
            if (!tagsMap.containsKey(tag)) {
              tagsMap[tag] = [];
            }
            tagsMap[tag]!.add(item);
          }

          if (tagsMap.isEmpty) {
            return const Center(child: Text('No Tags Found', style: TextStyle(color: Colors.white38)));
          }

          final tags = tagsMap.keys.toList()..sort();

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: tags.map((tag) {
                final items = tagsMap[tag]!;
                return ActionChip(
                  backgroundColor: Colors.white.withOpacity(0.05),
                  side: BorderSide(color: Colors.white.withOpacity(0.05)),
                  label: Text(
                    '$tag (${items.length})',
                    style: const TextStyle(color: Color(0xFF00E676), fontSize: 12),
                  ),
                  onPressed: () => _showTagItems(context, tag, items, provider),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }

  void _showTagItems(BuildContext context, String tagName, List<MediaItem> items, MediaProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(tagName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
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
                  item.artist ?? 'Unknown Artist',
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
