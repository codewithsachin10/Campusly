import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/promo_banners_provider.dart';

class EventsPromoBanner extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const EventsPromoBanner({super.key, required this.onTap});

  @override
  ConsumerState<EventsPromoBanner> createState() => _EventsPromoBannerState();
}

class _EventsPromoBannerState extends ConsumerState<EventsPromoBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.trim().isEmpty) return AppColors.primary;
    try {
      var hex = hexColor.replaceAll('#', '').trim();
      if (hex.length == 6) {
        hex = 'FF$hex';
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bannersAsync = ref.watch(promoBannersProvider);

    return bannersAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (banners) {
        if (banners.isEmpty) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          height: 150.0,
          margin: EdgeInsets.zero,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: banners.length,
                itemBuilder: (context, index) {
                  final banner = banners[index];
                  final hasImage =
                      banner.imageUrl != null && banner.imageUrl!.isNotEmpty;

                  return GestureDetector(
                    onTap: widget.onTap,
                    child: Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        gradient: hasImage
                            ? null
                            : LinearGradient(
                                colors: [
                                  _parseColor(banner.gradientStart),
                                  _parseColor(banner.gradientEnd),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (hasImage)
                            CachedNetworkImage(
                              imageUrl: banner.imageUrl!,
                              fit: BoxFit.cover,
                              fadeInDuration: const Duration(milliseconds: 250),
                              placeholder: (context, url) => Container(
                                color: AppColors.surfaceContainerLow,
                                child: const Center(
                                  child: SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: AppColors.primary,
                                child: const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                          // Dark overlay for text readability
                          Container(color: Colors.black.withValues(alpha: 0.4)),

                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  banner.category.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white70,
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  banner.title,
                                  style: AppTypography.headlineSmall.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 20.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (banner.ctaText != null &&
                                    banner.ctaText!.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      banner.ctaText!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Dots Indicator
              if (banners.length > 1)
                Positioned(
                  bottom: 12.0,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      banners.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 6,
                        width: _currentPage == index ? 16 : 6,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
