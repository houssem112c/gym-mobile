import 'package:flutter/material.dart';
import '../config/colors.dart';

class AnimatedGradientBackground extends StatefulWidget {
  final Widget child;
  final List<Color>? orbColors;

  const AnimatedGradientBackground({
    super.key,
    required this.child,
    this.orbColors,
  });

  @override
  State<AnimatedGradientBackground> createState() =>
      _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState
    extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller1;
  late AnimationController _controller2;
  late AnimationController _controller3;

  @override
  void initState() {
    super.initState();
    _controller1 = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat(reverse: true);

    _controller2 = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _controller3 = AnimationController(
      duration: const Duration(seconds: 6),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller1.dispose();
    _controller2.dispose();
    _controller3.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final orbColors = widget.orbColors ??
        [
          AppColors.primary500,
          AppColors.accent500,
          AppColors.blue500,
        ];

    return Stack(
      children: [
        // Base gradient background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.surface950,
                AppColors.surface900,
                AppColors.surface950,
              ],
            ),
          ),
        ),

        // Animated orbs
        Positioned(
          top: -size.height * 0.1,
          left: -size.width * 0.1,
          child: AnimatedBuilder(
            animation: _controller1,
            builder: (context, child) {
              return Opacity(
                opacity: 0.3 + (_controller1.value * 0.2),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        orbColors[0],
                        orbColors[0].withOpacity(0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          top: -size.height * 0.05,
          right: -size.width * 0.1,
          child: AnimatedBuilder(
            animation: _controller2,
            builder: (context, child) {
              return Opacity(
                opacity: 0.3 + (_controller2.value * 0.2),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        orbColors[1],
                        orbColors[1].withOpacity(0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        Positioned(
          bottom: -size.height * 0.1,
          left: size.width * 0.2,
          child: AnimatedBuilder(
            animation: _controller3,
            builder: (context, child) {
              return Opacity(
                opacity: 0.3 + (_controller3.value * 0.2),
                child: Container(
                  width: size.width * 0.6,
                  height: size.width * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        orbColors[2],
                        orbColors[2].withOpacity(0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Child content
        widget.child,
      ],
    );
  }
}
