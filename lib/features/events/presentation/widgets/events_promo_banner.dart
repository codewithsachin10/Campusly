import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../core/theme/app_typography.dart';
import '../providers/events_provider.dart';

class EventsPromoBanner extends ConsumerStatefulWidget {
  final VoidCallback onTap;

  const EventsPromoBanner({super.key, required this.onTap});

  @override
  ConsumerState<EventsPromoBanner> createState() => _EventsPromoBannerState();
}

class _EventsPromoBannerState extends ConsumerState<EventsPromoBanner> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _timer = Timer.periodic(Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextPage = (_currentPage + 1) % 3;
        _pageController.animateToPage(
          nextPage,
          duration: Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(eventsStreamProvider);
    final eventsList = eventsAsync.value ?? [];

    final List<Map<String, dynamic>> slides = [
      {
        'category': 'EVENTS',
        'title': eventsList.isNotEmpty
            ? eventsList.first.title
            : 'Campus Tech Fest 2024',
        'icon': LucideIcons.rocket,
      },
      {
        'category': 'HACKATHON',
        'title': eventsList.length > 1
            ? eventsList[1].title
            : 'National AI Hackathon',
        'icon': LucideIcons.code,
      },
      {
        'category': 'WORKSHOP',
        'title': eventsList.length > 2
            ? eventsList[2].title
            : 'Flutter & Cloud Bootcamp',
        'icon': LucideIcons.sparkles,
      },
    ];

    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24.r),
      child: Container(
        width: double.infinity,
        height: 140.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFD946EF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF8B5CF6).withValues(alpha: 0.3),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24.r),
          child: Stack(
            children: [
              // Background decorative glass square
              Positioned(
                right: 28.w,
                bottom: -12,
                child: Container(
                  width: 76.w,
                  height: 76.h,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.18),
                      width: 1.5.w,
                    ),
                  ),
                ),
              ),

              // Carousel PageView
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: slides.length,
                itemBuilder: (context, index) {
                  final slide = slides[index];
                  final IconData iconData = slide['icon'] as IconData;
                  final String category = slide['category'] as String;
                  final String title = slide['title'] as String;

                  return Padding(
                    padding: EdgeInsets.fromLTRB(20, 16, 20, 24),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left Icon Box
                        Container(
                          width: 60.w,
                          height: 60.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(18.r),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.35),
                              width: 1.5.w,
                            ),
                          ),
                          child: Center(
                            child: Icon(
                              iconData,
                              color: Colors.white,
                              size: 30,
                            ),
                          ),
                        ),
                        SizedBox(width: 16.w),

                        // Title & Subtitle
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category,
                                style: AppTypography.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.6,
                                  fontSize: 11.sp,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              SizedBox(height: 4.h),
                              Text(
                                title,
                                style: AppTypography.headlineSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 22.sp,
                                  height: 1.15.h,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Bottom Carousel Dots
              Positioned(
                bottom: 12.h,
                left: 0.w,
                right: 0.w,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(slides.length, (index) {
                    final isActive = index == _currentPage;
                    return AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.symmetric(horizontal: 3.w),
                      width: isActive ? 24 : 6,
                      height: 4.h,
                      decoration: BoxDecoration(
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
