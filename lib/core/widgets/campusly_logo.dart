import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CampuslyLogo extends StatelessWidget {
  final double size;
  final bool showBackground;
  final double borderRadius;
  final bool addShadow;

  const CampuslyLogo({
    super.key,
    this.size = 72.0,
    this.showBackground = true,
    this.borderRadius = 18.0,
    this.addShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget imageWidget = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Image.asset(
        'assets/icons/campusly_logo.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          // Fallback angled graduation icon
          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF4A42EC), Color(0xFF2D31FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
            child: Icon(
              Icons.school_rounded,
              size: size * 0.55,
              color: Colors.white,
            ),
          );
        },
      ),
    );

    if (!showBackground) {
      return imageWidget;
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: addShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF3D5AFE).withValues(alpha: 0.25),
                  blurRadius: size * 0.25,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
      ),
      child: imageWidget,
    );
  }
}
