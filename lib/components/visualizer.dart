import 'package:flutter/material.dart';
import 'dart:math';

class Visualizer extends StatefulWidget {
  final bool isPlaying;
  final Color color;

  const Visualizer({
    super.key,
    required this.isPlaying,
    this.color = const Color(0xFF6C63FF),
  });

  @override
  State<Visualizer> createState() => _VisualizerState();
}

class _VisualizerState extends State<Visualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<double> _heights = List.generate(15, (index) => Random().nextDouble());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(15, (index) {
            double h = widget.isPlaying 
              ? (_heights[index] * 0.5 + 0.5 * sin(_controller.value * 2 * pi + index)) * 50
              : 5.0;
            return Container(
              width: 4,
              height: h.clamp(2.0, 50.0),
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              decoration: BoxDecoration(
                color: widget.color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        );
      },
    );
  }
}
