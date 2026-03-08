import 'package:flutter/material.dart';
import 'package:pixelplay/components/glass_box.dart';
import 'package:pixelplay/components/visualizer.dart';
import 'package:provider/provider.dart';
import 'package:pixelplay/providers/media_provider.dart';

class VisualizerScreen extends StatelessWidget {
  const VisualizerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MediaProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Visualizer', style: TextStyle(fontWeight: FontWeight.bold)),
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
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Visualizer(
                    isPlaying: provider.isPlaying,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(height: 40),
                Text(
                  provider.isPlaying ? "Visualizing Audio..." : "No Audio Playing",
                  style: const TextStyle(color: Colors.white38, letterSpacing: 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
