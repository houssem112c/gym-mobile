import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../models/category.dart' as cat;
import '../config/colors.dart';
import 'muscle_body_diagram.dart';

class CategoryCarousel3D extends StatefulWidget {
  final List<cat.Category> categories;
  final Function(cat.Category) onCategoryTap;

  const CategoryCarousel3D({
    super.key,
    required this.categories,
    required this.onCategoryTap,
  });

  @override
  State<CategoryCarousel3D> createState() => _CategoryCarousel3DState();
}

class _CategoryCarousel3DState extends State<CategoryCarousel3D>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _flipController;
  double _currentPage = 0;
  int? _tappedIndex;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _flipController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..addListener(() {
      setState(() {});
    });
    _pageController = PageController(
      viewportFraction: 0.7,
      initialPage: 0,
    );
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0;
      });
    });
  }

  @override
  void dispose() {
    _flipController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 500,
      child: PageView.builder(
        controller: _pageController,
        itemCount: widget.categories.length,
        itemBuilder: (context, index) {
          return _buildCarouselItem(index);
        },
      ),
    );
  }

  Widget _buildCarouselItem(int index) {
    final category = widget.categories[index];
    final difference = index - _currentPage;

    // Calculate 3D circular carousel position
    final double absPosition = difference.abs();
    final bool isCenter = absPosition < 0.5;

    // Scale: center card largest (1.0), sides smaller (gradually)
    final double scale =
        isCenter ? 1.0 : math.max(0.7, 1.0 - (absPosition * 0.25));

    // Rotation angle for circular positioning
    final double angle = difference * (math.pi / 6); // ~30 degrees per position

    // Calculate X offset for circular path
    final double radius = 60.0;
    final double xOffset = math.sin(angle) * radius;

    // Opacity based on distance from center
    final double opacity =
        isCenter ? 1.0 : math.max(0.3, 1.0 - (absPosition * 0.5));

    // Z-axis translation for depth (cards behind go back)
    final double zOffset = math.cos(angle) * 30;

    return AnimatedBuilder(
      animation: _pageController,
      builder: (context, child) {
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective for 3D effect
            ..translate(xOffset, zOffset * 0.2, zOffset)
            ..rotateY(angle * 0.7) // Rotate cards to face inward
            ..scale(scale),
          child: Opacity(
            opacity: opacity,
            child: child,
          ),
        );
      },
      child: GestureDetector(
        onTapDown: (_) {
          if (isCenter) {
            setState(() {
              _tappedIndex = index;
            });
          }
        },
        onTapUp: (_) {
          setState(() {
            _tappedIndex = null;
          });
        },
        onTapCancel: () {
          setState(() {
            _tappedIndex = null;
          });
        },
        onTap: () async {
          if (isCenter && (_isAnimating == false)) {
            setState(() {
              _isAnimating = true;
            });

            // Start flip animation
            await _flipController.forward();

            // Navigate to next screen
            widget.onCategoryTap(category);

            // Reset flip after navigation
            _flipController.reset();

            setState(() {
              _isAnimating = false;
            });
          } else if (!isCenter) {
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOutCubic,
            );
          }
        },
        child: AnimatedBuilder(
          animation: _flipController,
          builder: (context, child) {
            return child!;
          },
          child: _buildCategoryCard(category, isCenter),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(cat.Category category, bool isCenter) {
    final primaryGlow = AppColors.primary400;
    final secondaryGlow = AppColors.primary500;
    final centerBorderColor = const Color(0xFFFFD700); // Gold color for center card

    return Hero(
      tag: 'category_${category.id}',
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isCenter
                      ? [
                          Colors.white.withOpacity(0.30),
                          primaryGlow.withOpacity(0.10),
                          secondaryGlow.withOpacity(0.05),
                        ]
                      : [
                          Colors.white.withOpacity(0.12),
                          Colors.white.withOpacity(0.06),
                        ],
                ),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: isCenter
                      ? centerBorderColor
                      : Colors.white.withOpacity(0.25),
                  width: isCenter ? 4 : 1.5,
                ),
                boxShadow: isCenter
                    ? [
                        BoxShadow(
                          color: centerBorderColor.withOpacity(0.8),
                          blurRadius: 60,
                          spreadRadius: 12,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: primaryGlow.withOpacity(0.6),
                          blurRadius: 50,
                          spreadRadius: 10,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: secondaryGlow.withOpacity(0.5),
                          blurRadius: 70,
                          spreadRadius: 18,
                          offset: const Offset(0, 15),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 20),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 25,
                          offset: const Offset(0, 10),
                        ),
                      ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Category icon or muscle diagram
                    if (category.muscleGroup != null && category.muscleGroup!.isNotEmpty)
                      // Show muscle diagram
                      SizedBox(
                        width: isCenter ? 90 : 75,
                        height: isCenter ? 180 : 150,
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: MuscleBodyDiagram(
                            selectedMuscle: category.muscleGroup,
                            highlightColor: primaryGlow,
                            width: 180,
                            height: 350,
                          ),
                        ),
                      )
                    else
                      // Show icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              primaryGlow.withOpacity(0.4),
                              secondaryGlow.withOpacity(0.2),
                              Colors.transparent,
                            ],
                          ),
                          boxShadow: isCenter
                              ? [
                                  BoxShadow(
                                    color: primaryGlow.withOpacity(0.7),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: secondaryGlow.withOpacity(0.6),
                                    blurRadius: 50,
                                    spreadRadius: 10,
                                  ),
                                ]
                              : [],
                        ),
                        child: Text(
                          category.icon ?? '💪',
                          style: TextStyle(
                            fontSize: isCenter ? 52 : 44,
                            shadows: isCenter
                                ? [
                                    Shadow(
                                      color: primaryGlow.withOpacity(0.9),
                                      blurRadius: 25,
                                    ),
                                    Shadow(
                                      color: secondaryGlow.withOpacity(0.8),
                                      blurRadius: 30,
                                    ),
                                  ]
                                : [],
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    // Category name
                    Text(
                      category.name,
                      style: TextStyle(
                        fontSize: isCenter ? 24 : 20,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.6),
                            blurRadius: 12,
                            offset: const Offset(0, 3),
                          ),
                          if (isCenter) ...[
                            Shadow(
                              color: primaryGlow.withOpacity(0.8),
                              blurRadius: 25,
                            ),
                            Shadow(
                              color: secondaryGlow.withOpacity(0.7),
                              blurRadius: 30,
                            ),
                          ],
                        ],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isCenter &&
                        category.description != null &&
                        (category.description?.isNotEmpty ?? false)) ...[
                      const SizedBox(height: 4),
                      // Description for center card
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: primaryGlow.withOpacity(0.5),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: primaryGlow.withOpacity(0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          category.description!,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.95),
                            fontWeight: FontWeight.w600,
                            height: 1.4,
                            letterSpacing: 0.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color? _parseColor(String? colorString) {
    if (colorString == null) return null;

    try {
      final hex = colorString.replaceAll('#', '');
      if (hex.length == 6) {
        return Color(int.parse('FF$hex', radix: 16));
      } else if (hex.length == 8) {
        return Color(int.parse(hex, radix: 16));
      }
    } catch (e) {
      print('Error parsing color: $e');
    }

    return null;
  }
}

// Custom painter for detailed body illustration
class _BodyIllustrationPainter extends CustomPainter {
  final Color muscleColor;
  final bool isDetailed;
  final bool isCenter;

  _BodyIllustrationPainter({
    required this.muscleColor,
    this.isDetailed = false,
    this.isCenter = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final outlinePaint = Paint()
      ..color = Colors.grey[400]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = isCenter ? 2.5 : 2;

    final musclePaint = Paint()
      ..color = muscleColor.withOpacity(0.9)
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final scale = (size.height / 380).clamp(0.8, 1.2);

    // Head
    canvas.drawCircle(
      Offset(centerX, 28 * scale),
      16 * scale,
      outlinePaint,
    );

    // Neck
    final neckPath = Path()
      ..moveTo(centerX - 8 * scale, 42 * scale)
      ..lineTo(centerX - 12 * scale, 58 * scale)
      ..lineTo(centerX + 12 * scale, 58 * scale)
      ..lineTo(centerX + 8 * scale, 42 * scale);
    canvas.drawPath(neckPath, outlinePaint);

    // Shoulders and torso outline
    final torsoPath = Path()
      ..moveTo(centerX, 58 * scale)
      ..lineTo(centerX - 40 * scale, 68 * scale) // Left shoulder
      ..lineTo(centerX - 38 * scale, 155 * scale) // Left waist
      ..lineTo(centerX - 15 * scale, 165 * scale) // Left hip
      ..lineTo(centerX, 168 * scale) // Center bottom
      ..lineTo(centerX + 15 * scale, 165 * scale) // Right hip
      ..lineTo(centerX + 38 * scale, 155 * scale) // Right waist
      ..lineTo(centerX + 40 * scale, 68 * scale) // Right shoulder
      ..close();
    canvas.drawPath(torsoPath, outlinePaint);

    // Left arm
    final leftArmPath = Path()
      ..moveTo(centerX - 40 * scale, 70 * scale)
      ..lineTo(centerX - 55 * scale, 95 * scale)
      ..lineTo(centerX - 58 * scale, 125 * scale)
      ..lineTo(centerX - 60 * scale, 145 * scale);
    canvas.drawPath(leftArmPath, outlinePaint);

    // Right arm
    final rightArmPath = Path()
      ..moveTo(centerX + 40 * scale, 70 * scale)
      ..lineTo(centerX + 55 * scale, 95 * scale)
      ..lineTo(centerX + 58 * scale, 125 * scale)
      ..lineTo(centerX + 60 * scale, 145 * scale);
    canvas.drawPath(rightArmPath, outlinePaint);

    // === MUSCLE HIGHLIGHTS ===

    // Left shoulder (deltoid)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 40 * scale, 75 * scale),
        width: 28 * scale,
        height: 22 * scale,
      ),
      musclePaint,
    );

    // Right shoulder (deltoid)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 40 * scale, 75 * scale),
        width: 28 * scale,
        height: 22 * scale,
      ),
      musclePaint,
    );

    // Left chest (pec)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 20 * scale, 88 * scale),
        width: 25 * scale,
        height: 32 * scale,
      ),
      musclePaint,
    );

    // Right chest (pec)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 20 * scale, 88 * scale),
        width: 25 * scale,
        height: 32 * scale,
      ),
      musclePaint,
    );

    // Abs (6-pack)
    final abPositions = [
      Offset(centerX - 10 * scale, 120 * scale),
      Offset(centerX + 10 * scale, 120 * scale),
      Offset(centerX - 10 * scale, 138 * scale),
      Offset(centerX + 10 * scale, 138 * scale),
      Offset(centerX - 8 * scale, 153 * scale),
      Offset(centerX + 8 * scale, 153 * scale),
    ];

    for (var pos in abPositions) {
      canvas.drawOval(
        Rect.fromCenter(
          center: pos,
          width: 18 * scale,
          height: 14 * scale,
        ),
        musclePaint,
      );
    }

    // Left leg
    final leftLegPath = Path()
      ..moveTo(centerX - 15 * scale, 168 * scale)
      ..lineTo(centerX - 18 * scale, 220 * scale)
      ..lineTo(centerX - 20 * scale, 270 * scale)
      ..lineTo(centerX - 18 * scale, 285 * scale);
    canvas.drawPath(leftLegPath, outlinePaint);

    // Right leg
    final rightLegPath = Path()
      ..moveTo(centerX + 15 * scale, 168 * scale)
      ..lineTo(centerX + 18 * scale, 220 * scale)
      ..lineTo(centerX + 20 * scale, 270 * scale)
      ..lineTo(centerX + 18 * scale, 285 * scale);
    canvas.drawPath(rightLegPath, outlinePaint);

    // Left thigh (quadriceps)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 16 * scale, 195 * scale),
        width: 22 * scale,
        height: 40 * scale,
      ),
      musclePaint,
    );

    // Right thigh (quadriceps)
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 16 * scale, 195 * scale),
        width: 22 * scale,
        height: 40 * scale,
      ),
      musclePaint,
    );

    // Left calf
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX - 19 * scale, 250 * scale),
        width: 18 * scale,
        height: 28 * scale,
      ),
      musclePaint,
    );

    // Right calf
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX + 19 * scale, 250 * scale),
        width: 18 * scale,
        height: 28 * scale,
      ),
      musclePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CategoryPatternPainter extends CustomPainter {
  final Color color;

  _CategoryPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (double i = -size.height; i < size.width + size.height; i += 30) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
