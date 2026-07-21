import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class ThreeDPushableButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double width;
  final double height;

  const ThreeDPushableButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56.0,
  });

  @override
  State<ThreeDPushableButton> createState() => _ThreeDPushableButtonState();
}

class _ThreeDPushableButtonState extends State<ThreeDPushableButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  bool get _isDisabled => widget.onPressed == null || widget.isLoading;

  @override
  Widget build(BuildContext context) {
    // 3D Pushable offsets according to CSS specifications
    final double frontOffset = _isDisabled
        ? -2.0
        : (_isPressed ? -2.0 : (_isHovered ? -6.0 : -4.0));
    final double shadowOffset = _isDisabled
        ? 1.0
        : (_isPressed ? 1.0 : (_isHovered ? 4.0 : 2.0));

    final Duration duration = _isPressed
        ? const Duration(milliseconds: 34)
        : (_isHovered
              ? const Duration(milliseconds: 250)
              : const Duration(milliseconds: 600));

    final Curve curve = _isPressed
        ? Curves.linear
        : (_isHovered
              ? const Cubic(0.3, 0.7, 0.4, 1.5)
              : const Cubic(0.3, 0.7, 0.4, 1.0));

    // Front color with brightness increase on hover
    final Color frontColor = _isDisabled
        ? AppColors.primary.withValues(alpha: 0.6)
        : (_isHovered ? const Color(0xFF4C3CE8) : AppColors.primary);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: _isDisabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTapDown: _isDisabled
            ? null
            : (_) => setState(() => _isPressed = true),
        onTapUp: _isDisabled
            ? null
            : (_) {
                setState(() => _isPressed = false);
                widget.onPressed?.call();
              },
        onTapCancel: _isDisabled
            ? null
            : () => setState(() => _isPressed = false),
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: Stack(
            children: [
              // .shadow layer
              AnimatedPositioned(
                duration: duration,
                curve: curve,
                top: 6.0 + shadowOffset,
                left: 0,
                right: 0,
                bottom: -shadowOffset,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0x40000000), // hsl(0deg 0% 0% / 0.25)
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              // .edge layer
              Positioned(
                top: 6.0,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      begin: Alignment.centerRight,
                      end: Alignment.centerLeft,
                      stops: [0.0, 0.08, 0.92, 1.0],
                      colors: [
                        Color(0xFF1B117A), // 16% lightness purple edge
                        Color(0xFF281C9E), // 32% lightness purple center
                        Color(0xFF281C9E),
                        Color(0xFF1B117A),
                      ],
                    ),
                  ),
                ),
              ),
              // .front layer
              AnimatedPositioned(
                duration: duration,
                curve: curve,
                top: 6.0 + frontOffset,
                left: 0,
                right: 0,
                bottom: -frontOffset,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  decoration: BoxDecoration(
                    color: frontColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: widget.isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          widget.text,
                          style: AppTypography.textTheme.labelLarge?.copyWith(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
