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
      body: Stack(
        children: [
          // Background Gradient (only for audio)
          if (item.type == MediaType.audio)
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF0F0F1A),
                      Color(0xFF1B1B2F),
                      Color(0xFF0F0F1A),
                    ],
                  ),
                ),
              ),
            ),
          
          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context, item),
                if (item.type == MediaType.video)
                  Expanded(
                    child: Center(
                      child: Video(controller: provider.videoController),
                    ),
                  )
                else ...[
                  const Spacer(),
                  _buildPlayerArea(provider, item),
                  const Spacer(),
                  Visualizer(isPlaying: provider.isPlaying),
                  const Spacer(),
                ],
                _buildControls(context, provider),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, MediaItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 30),
            onPressed: () => Navigator.pop(context),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  item.type == MediaType.video ? 'WATCHING MOVIE' : 'LISTENING TO MUSIC',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white38,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white),
            onPressed: () => _showEqualizer(context),
            tooltip: 'Equalizer',
          ),
        ],
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
              const Text('EQUALIZER', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 2)),
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

  Widget _buildPlayerArea(MediaProvider provider, MediaItem item) {
    return Column(
      children: [
        // Audio Visualization placeholder
        Container(
          height: 250,
          width: 250,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 40,
                spreadRadius: 10,
              ),
            ],
          ),
          child: GlassBox(
            borderRadius: 125,
            opacity: 0.1,
            child: Center(
              child: Icon(
                FontAwesomeIcons.compactDisc,
                size: 150,
                color: provider.isPlaying ? const Color(0xFF6C63FF) : Colors.white24,
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        Text(
          item.title,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        const Text(
          'High Fidelity Audio',
          style: TextStyle(color: Colors.white38),
        ),
      ],
    );
  }

  Widget _buildControls(BuildContext context, MediaProvider provider) {
    final currentPos = provider.position.inMilliseconds.toDouble();
    final totalDur = provider.duration.inMilliseconds.toDouble();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildSlider(context, provider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(provider.position),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
                Text(
                  _formatDuration(provider.duration),
                  style: const TextStyle(color: Colors.white38, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(FontAwesomeIcons.shuffle, size: 20, color: Colors.white38),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.backwardStep, size: 24, color: Colors.white),
                onPressed: () {},
              ),
              GestureDetector(
                onTap: () => provider.togglePlayback(),
                child: Container(
                  height: 80,
                  width: 80,
                  decoration: const BoxDecoration(
                    color: Color(0xFF6C63FF),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6C63FF),
                        blurRadius: 20,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.forwardStep, size: 24, color: Colors.white),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(FontAwesomeIcons.repeat, size: 20, color: Colors.white38),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSlider(BuildContext context, MediaProvider provider) {
    double value = 0;
    if (!_isDragging) {
      if (provider.duration.inMilliseconds > 0) {
        value = provider.position.inMilliseconds / provider.duration.inMilliseconds;
      }
    } else {
      value = _dragValue;
    }

    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        activeTrackColor: const Color(0xFF6C63FF),
        inactiveTrackColor: Colors.white10,
        thumbColor: Colors.white,
        overlayColor: const Color(0xFF6C63FF).withOpacity(0.2),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      child: Slider(
        value: value.clamp(0.0, 1.0),
        onChanged: (val) {
          setState(() {
            _isDragging = true;
            _dragValue = val;
          });
        },
        onChangeEnd: (val) {
          final target = Duration(milliseconds: (val * provider.duration.inMilliseconds).toInt());
          provider.seek(target);
          setState(() {
            _isDragging = false;
          });
        },
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
