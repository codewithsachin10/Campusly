import 'package:flutter/material.dart';
import '../services/app_haptics.dart';
import '../theme/app_motion.dart';

/// Interactive button wrapper that scales down to 0.97 on press and triggers subtle haptics
class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final HitTestBehavior behavior;
  final bool enableHaptics;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.behavior = HitTestBehavior.opaque,
    this.enableHaptics = true,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails _) {
    if (widget.onTap != null || widget.onLongPress != null) {
      setState(() => _isPressed = true);
    }
  }

  void _handleTapUp(TapUpDetails _) {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTapCancel() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
  }

  void _handleTap() {
    if (widget.enableHaptics) {
      AppHaptics.lightImpact();
    }
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final scale = (_isPressed && !disableAnimations) ? widget.pressedScale : 1.0;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onTap: widget.onTap != null ? _handleTap : null,
      onLongPress: widget.onLongPress != null
          ? () {
              if (widget.enableHaptics) AppHaptics.mediumImpact();
              widget.onLongPress?.call();
            }
          : null,
      child: AnimatedScale(
        scale: scale,
        duration: disableAnimations ? Duration.zero : const Duration(milliseconds: 140),
        curve: AppMotion.easeOut,
        child: widget.child,
      ),
    );
  }
}
