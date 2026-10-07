import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:campusly/core/theme/app_theme.dart';
import 'package:campusly/core/theme/app_radius.dart';
import 'package:campusly/core/widgets/pressable_scale.dart';
import 'package:campusly/core/widgets/app_shimmer.dart';
import 'package:campusly/core/widgets/empty_state.dart';
import 'package:campusly/core/widgets/error_state.dart';
import 'package:campusly/core/widgets/fade_slide_in.dart';
import 'package:campusly/core/widgets/animated_state_switcher.dart';
import 'package:campusly/core/widgets/connectivity_banner.dart';
import 'package:campusly/core/services/connectivity_service.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

Widget _wrapWithTheme(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('PressableScale Widget Tests', () {
    testWidgets('renders child and triggers onTap callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          PressableScale(
            onTap: () => tapped = true,
            child: const Text('Press Me'),
          ),
        ),
      );

      expect(find.text('Press Me'), findsOneWidget);

      await tester.tap(find.text('Press Me'));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    });

    testWidgets('animates scale on pointer down and up', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          PressableScale(
            pressedScale: 0.92,
            onTap: () {},
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(PressableScale)),
      );
      await tester.pump(const Duration(milliseconds: 50));

      final transformFinder = find.descendant(
        of: find.byType(PressableScale),
        matching: find.byType(Transform),
      );
      expect(transformFinder, findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });

  group('AppShimmer Skeleton Widgets', () {
    testWidgets('renders SkeletonBox with custom dimensions and radius', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AppShimmer(
            child: SkeletonBox(width: 120, height: 24, borderRadius: AppRadius.k8),
          ),
        ),
      );

      expect(find.byType(SkeletonBox), findsOneWidget);
      expect(find.byType(AppShimmer), findsOneWidget);
    });

    testWidgets('renders SkeletonCard and SkeletonListTile structures', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const Column(
            children: [
              SkeletonCard(height: 100),
              SkeletonListTile(hasLeading: true),
            ],
          ),
        ),
      );

      expect(find.byType(SkeletonCard), findsOneWidget);
      expect(find.byType(SkeletonListTile), findsOneWidget);
    });
  });

  group('EmptyState & ErrorState Widgets', () {
    testWidgets('EmptyState displays title, subtitle, and action button', (tester) async {
      bool actionPressed = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          EmptyState(
            title: 'No classes today',
            subtitle: 'Enjoy your free day!',
            actionLabel: 'Refresh',
            onAction: () => actionPressed = true,
          ),
        ),
      );

      expect(find.text('No classes today'), findsOneWidget);
      expect(find.text('Enjoy your free day!'), findsOneWidget);
      expect(find.text('Refresh'), findsOneWidget);

      await tester.tap(find.text('Refresh'));
      await tester.pumpAndSettle();
      expect(actionPressed, isTrue);
    });

    testWidgets('ErrorState renders error message and retry button', (tester) async {
      bool retryPressed = false;

      await tester.pumpWidget(
        _wrapWithTheme(
          ErrorState(
            title: 'Failed to load timetable',
            message: 'Server timeout. Check network.',
            onRetry: () => retryPressed = true,
            retryLabel: 'Retry Now',
          ),
        ),
      );

      expect(find.text('Failed to load timetable'), findsOneWidget);
      expect(find.text('Server timeout. Check network.'), findsOneWidget);
      expect(find.text('Retry Now'), findsOneWidget);

      await tester.tap(find.text('Retry Now'));
      await tester.pumpAndSettle();
      expect(retryPressed, isTrue);
    });
  });

  group('Motion and Transition Widgets', () {
    testWidgets('FadeSlideIn displays child smoothly', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const FadeSlideIn(
            child: Text('Animated Headline'),
          ),
        ),
      );

      expect(find.text('Animated Headline'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(find.text('Animated Headline'), findsOneWidget);
    });

    testWidgets('AnimatedStateSwitcher switches between different states', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const AnimatedStateSwitcher(
            child: Text('State 1 View', key: ValueKey('state_1')),
          ),
        ),
      );

      expect(find.text('State 1 View'), findsOneWidget);

      await tester.pumpWidget(
        _wrapWithTheme(
          const AnimatedStateSwitcher(
            child: Text('State 2 View', key: ValueKey('state_2')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('State 2 View'), findsOneWidget);
    });
  });

  group('ConnectivityBanner Widget Tests', () {
    testWidgets('displays offline banner when offline status is emitted', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const ConnectivityBanner(
            child: Center(child: Text('Dashboard Content')),
          ),
          overrides: [
            connectivityStatusProvider.overrideWith((ref) => Stream.value(false)),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Dashboard Content'), findsOneWidget);
      expect(find.text('Offline mode — using cached schedule'), findsOneWidget);
      expect(find.byIcon(LucideIcons.wifiOff), findsOneWidget);
    });

    testWidgets('dismisses offline banner on tap close', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          const ConnectivityBanner(
            child: Center(child: Text('Main Screen')),
          ),
          overrides: [
            connectivityStatusProvider.overrideWith((ref) => Stream.value(false)),
          ],
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));

      expect(find.text('Offline mode — using cached schedule'), findsOneWidget);

      // Tap the dismiss X icon
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.text('Offline mode — using cached schedule'), findsNothing);
    });
  });
}
