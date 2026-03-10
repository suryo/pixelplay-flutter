import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PiPView extends StatefulWidget {
  const PiPView({super.key});

  @override
  State<PiPView> createState() => _PiPViewState();
}

class _PiPViewState extends State<PiPView> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final item = provider.currentItem;

    if (item == null) return const SizedBox.shrink();

    final isRadio = item.album == 'Online Stream';

    return Scaffold(
      backgroundColor: Colors.black,
      body: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white12, width: 0.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Artwork / Video Content
            if (item.type == MediaType.audio)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  image: item.thumbnail != null 
                      ? DecorationImage(
                          image: NetworkImage(item.thumbnail!), 
                          fit: BoxFit.cover, 
                          opacity: 0.5,
                        )
                      : null,
                ),
                child: item.thumbnail == null 
                    ? Icon(isRadio ? Icons.radio : Icons.music_note, color: Colors.white10, size: 80)
                    : null,
              )
            else
              Video(controller: provider.videoController),

            // Minimal Controls Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.2),
                    Colors.black.withOpacity(0.5),
                    Colors.black.withOpacity(0.9),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isRadio)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            ScaleTransition(
                              scale: Tween<double>(begin: 0.8, end: 1.2).animate(_pulseController),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(color: Color(0xFFFF5252), blurRadius: 4, spreadRadius: 1),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE',
                              style: TextStyle(
                                color: Color(0xFFFF5252), 
                                fontWeight: FontWeight.bold, 
                                fontSize: 9, 
                                letterSpacing: 1.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      item.artist ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white38, fontSize: 9),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _smallControlIcon(FontAwesomeIcons.backwardStep, provider.playPrevious),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: provider.togglePlayback,
                          child: Container(
                            height: 36,
                            width: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF00E676),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00E676).withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(
                              provider.isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
                              color: Colors.black,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        _smallControlIcon(FontAwesomeIcons.forwardStep, provider.skipNext),
                      ],
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _smallControlIcon(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: Colors.white, size: 16),
    );
  }
}
