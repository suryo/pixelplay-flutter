import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pixelplay/providers/media_provider.dart';
import 'package:pixelplay/models/media_item.dart';
import 'package:pixelplay/components/glass_box.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import 'package:pixelplay/components/visualizer.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  bool _isDragging = false;
  double _dragValue = 0.0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    final item = provider.currentItem;
    
    if (item == null) {
      return const Scaffold(body: Center(child: Text('No media selected')));
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildAppBar(context, item),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildArtwork(item),
                    const SizedBox(height: 40),
                    _buildMetadata(item),
                    const SizedBox(height: 20),
                    _buildSecondaryActions(),
                    const SizedBox(height: 30),
                    _buildProgressBar(provider),
                    const SizedBox(height: 30),
                    _buildMainControls(provider),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MediaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white70, size: 28),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white70, size: 24),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildArtwork(MediaItem item) {
    return Container(
      width: 320,
      height: 320,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Icon(
          item.type == MediaType.audio ? Icons.play_arrow_rounded : Icons.videocam_rounded,
          size: 160,
          color: Colors.white12,
        ),
      ),
    );
  }

  Widget _buildMetadata(MediaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          Text(
            item.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            item.artist ?? 'Unknown Artist',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            item.album ?? 'Unknown Album',
            style: const TextStyle(color: Color(0xFF00E676), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _actionIcon(Icons.favorite_border),
          _actionIcon(Icons.info_outline),
          _actionIcon(Icons.playlist_add),
          _actionIcon(Icons.more_horiz),
        ],
      ),
    );
  }

  Widget _actionIcon(IconData icon) {
    return Icon(icon, color: Colors.white70, size: 22);
  }

  Widget _buildProgressBar(MediaProvider provider) {
    final currentPos = provider.position.inMilliseconds.toDouble();
    final totalDur = provider.duration.inMilliseconds.toDouble();
    
    double progressValue = 0;
    if (!_isDragging) {
      if (totalDur > 0) progressValue = currentPos / totalDur;
    } else {
      progressValue = _dragValue;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: Colors.white,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: Colors.white10,
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: progressValue.clamp(0.0, 1.0),
              onChanged: (val) {
                setState(() {
                  _isDragging = true;
                  _dragValue = val;
                });
              },
              onChangeEnd: (val) {
                final target = Duration(milliseconds: (val * totalDur).toInt());
                provider.seek(target);
                setState(() {
                  _isDragging = false;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(provider.position),
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
                Text(
                  _formatDuration(provider.duration),
                  style: const TextStyle(color: Colors.white30, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainControls(MediaProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white38, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.skip_previous, color: Colors.white, size: 36),
            onPressed: () => provider.playPrevious(),
          ),
          IconButton(
            icon: const Icon(Icons.fast_rewind_outlined, color: Colors.white38, size: 24),
            onPressed: () => provider.seek(provider.position - const Duration(seconds: 10)),
          ),
          GestureDetector(
            onTap: () => provider.togglePlayback(),
            child: Container(
              height: 50,
              width: 50,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Icon(
                provider.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 32,
                color: Colors.black,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.fast_forward_outlined, color: Colors.white38, size: 24),
            onPressed: () => provider.seek(provider.position + const Duration(seconds: 10)),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next, color: Colors.white, size: 36),
            onPressed: () => provider.skipNext(),
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white38, size: 20),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}
