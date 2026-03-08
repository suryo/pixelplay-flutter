import 'package:flutter/material.dart';
import 'dart:ui';

class GlassBox extends StatelessWidget {
  final Widget? child;
  final double blur;
  final double opacity;
  final Color color;
  final double borderRadius;

  const GlassBox({
    super.key,
    this.child,
    this.blur = 10,
    this.opacity = 0.1,
    this.color = Colors.white,
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(opacity),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: color.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}
