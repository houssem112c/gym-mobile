import 'dart:ui';
import 'package:flutter/material.dart';
import '../config/colors.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final Color? borderColor;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final BorderRadius? borderRadius;
  final List<Color>? gradientColors;

  const GlassCard({
    super.key,
    required this.child,
    this.blur = 10.0,
    this.borderColor,
    this.padding,
    this.margin,
    this.borderRadius,
    this.gradientColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        border: Border.all(
          color: borderColor ?? AppColors.surface800.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors ?? [
                  AppColors.surface900.withOpacity(0.7),
                  AppColors.surface950.withOpacity(0.5),
                ],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
