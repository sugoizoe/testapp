import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

/// Hafif alev/aurora hissi veren, mor-siyah tonlarda
/// animasyonlu arka plan. İçerik için Stack'in altına yerleştir.
class AuroraBackground extends StatefulWidget {
  const AuroraBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AuroraBackground> createState() => _AuroraBackgroundState();
}

class _AuroraBackgroundState extends State<AuroraBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 22),
    )..repeat();
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
      builder: (context, _) {
        final t = _controller.value;
        // Alev hissi için iki katmanlı gradientler ve hafif blur.
        return Stack(
          fit: StackFit.expand,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  transform: GradientRotation(t * 2 * math.pi),
                  colors: const [
                    Color(0xFF0A0518),
                    Color(0xFF120A2C),
                    Color(0xFF1A0F3C),
                  ],
                ),
              ),
            ),
            Opacity(
              opacity: 0.65,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.6 + 0.2 * math.sin(t * 2 * math.pi), -0.4),
                    radius: 0.9,
                    colors: const [
                      Color(0xFF7C3AED),
                      Color(0xFF9D4EDD),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: 0.55,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(
                      0.5 * math.cos(t * 2 * math.pi),
                      0.6 * math.sin(t * 2 * math.pi),
                    ),
                    radius: 1.0,
                    colors: const [
                      Color(0xFFFF5E8A),
                      Color(0xFFFF7EB3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
              child: const SizedBox.expand(),
            ),
            widget.child,
          ],
        );
      },
    );
  }
}
