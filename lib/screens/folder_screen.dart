import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';

class FolderScreen extends StatelessWidget {
  const FolderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('FOLDERS', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2, fontSize: 13, color: Colors.white70)),
        backgroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70, size: 20),
            onPressed: () => context.read<MediaProvider>().autoScanMedia(),
          ),
        ],
      ),
      body: Consumer<MediaProvider>(
        builder: (context, provider, _) {
          final foldersMap = provider.folders;
          if (foldersMap.isEmpty) {
            return const Center(child: Text('No Folders Found', style: TextStyle(color: Colors.white38)));
          }

          final folderPaths = foldersMap.keys.toList()..sort();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: folderPaths.length,
            itemBuilder: (context, index) {
              final path = folderPaths[index];
              final items = foldersMap[path]!;
              final folderName = path.split(Platform.pathSeparator).last;
              
              return ListTile(
                onTap: () => _showFolderItems(context, folderName, items, provider),
                leading: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.folder_rounded, color: Color(0xFF00E676), size: 28),
                ),
                title: Text(
                  folderName,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 15),
                ),
                subtitle: Text(
                  '${items.length} items • ${path}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 20),
              );
            },
          );
        },
      ),
    );
  }

  void _showFolderItems(BuildContext context, String folderName, List<MediaItem> items, MediaProvider provider) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            title: Text(folderName.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5, fontSize: 14)),
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
                     item.type == MediaType.audio ? Icons.audiotrack : Icons.movie,
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
