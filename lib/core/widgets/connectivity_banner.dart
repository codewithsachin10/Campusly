import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../services/connectivity_service.dart';
import '../theme/app_motion.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';

/// Overlay banner that notifies the user when they are offline
/// or when connectivity is restored.
class ConnectivityBanner extends ConsumerStatefulWidget {
  final Widget child;

  const ConnectivityBanner({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<ConnectivityBanner> createState() => _ConnectivityBannerState();
}

class _ConnectivityBannerState extends ConsumerState<ConnectivityBanner> {
  bool _showRestored = false;
  bool _isDismissed = false;
  Timer? _restoredTimer;

  @override
  void dispose() {
    _restoredTimer?.cancel();
    super.dispose();
  }

  void _onConnectivityChanged(bool? previous, bool current) {
    if (previous == false && current == true) {
      // Transition from offline to online
      _restoredTimer?.cancel();
      setState(() {
        _isDismissed = false;
        _showRestored = true;
      });
      _restoredTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _showRestored = false;
          });
        }
      });
    } else if (current == false) {
      // Transition to offline
      _restoredTimer?.cancel();
      setState(() {
        _showRestored = false;
        _isDismissed = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<bool>>(connectivityStatusProvider, (prev, next) {
      final prevVal = prev?.value;
      final nextVal = next.value;
      if (nextVal != null) {
        _onConnectivityChanged(prevVal, nextVal);
      }
    });

    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final isOffline = connectivityAsync.maybeWhen(
      data: (isOnline) => !isOnline,
      orElse: () => false,
    );

    final showOffline = isOffline && !_isDismissed;
    final isVisible = showOffline || _showRestored;

    final disableMotion = MediaQuery.of(context).disableAnimations;
    final topPadding = MediaQuery.of(context).padding.top;

    return Stack(
      children: [
        widget.child,
        // Floating connectivity toast banner at the top
        Positioned(
          top: topPadding + 8,
          left: 16,
          right: 16,
          child: AnimatedSwitcher(
            duration: disableMotion ? Duration.zero : AppMotion.normal,
            reverseDuration: disableMotion ? Duration.zero : AppMotion.fast,
            switchInCurve: AppMotion.easeInOut,
            switchOutCurve: AppMotion.easeInOut,
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(animation),
                child: FadeTransition(
                  opacity: animation,
                  child: child,
                ),
              );
            },
            child: isVisible
                ? _buildBannerContent(
                    context,
                    isRestored: _showRestored,
                  )
                : const SizedBox.shrink(key: ValueKey('empty_banner')),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerContent(BuildContext context, {required bool isRestored}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bgColor = isRestored
        ? const Color(0xFF10B981) // emerald-500
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A));
    final fgColor = Colors.white;

    final icon = isRestored ? LucideIcons.checkCircle2 : LucideIcons.wifiOff;
    final message = isRestored
        ? 'Back online — sync restored'
        : 'Offline mode — using cached schedule';

    return Material(
      key: ValueKey(isRestored ? 'restored_banner' : 'offline_banner'),
      color: Colors.transparent,
      elevation: 6,
      borderRadius: AppRadius.k12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: AppRadius.k12,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: fgColor),
            AppSpacing.h12,
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!isRestored) ...[
              AppSpacing.h8,
              GestureDetector(
                onTap: () {
                  setState(() {
                    _isDismissed = true;
                  });
                },
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.x,
                    size: 14,
                    color: fgColor.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
