import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:campusly/core/widgets/lazy_indexed_stack.dart';
import 'package:campusly/features/timetable/presentation/widgets/countdown_text.dart';
import 'package:campusly/features/timetable/domain/models/timetable_item.dart';
import 'package:campusly/core/theme/app_theme.dart';

Widget _wrapWithApp(Widget child, {List<dynamic> overrides = const []}) {
  return ProviderScope(
    overrides: overrides.cast(),
    child: ScreenUtilInit(
      designSize: const Size(375, 812),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, _) => MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  group('LazyIndexedStack Widget Tests', () {
    testWidgets('lazily inflates only the initially selected tab', (tester) async {
      int tab0Builds = 0;
      int tab1Builds = 0;
      int tab2Builds = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          LazyIndexedStack(
            index: 0,
            itemCount: 3,
            itemBuilder: (context, i) {
              if (i == 0) {
                tab0Builds++;
                return const Text('Content 0');
              } else if (i == 1) {
                tab1Builds++;
                return const Text('Content 1');
              } else {
                tab2Builds++;
                return const Text('Content 2');
              }
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content 0'), findsOneWidget);
      expect(find.text('Content 1'), findsNothing);
      expect(find.text('Content 2'), findsNothing);
      expect(tab0Builds, 1);
      expect(tab1Builds, 0);
      expect(tab2Builds, 0);

      // Verify TickerMode is enabled for active tab
      final tickerFinder = find.ancestor(
        of: find.text('Content 0'),
        matching: find.byType(TickerMode),
      );
      final TickerMode tickerMode = tester.widget(tickerFinder.last);
      expect(tickerMode.enabled, isTrue);
    });

    testWidgets('inflates tab 1 when switching index while maintaining tab 0 in tree', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => activeIndex = 1),
                    child: const Text('Switch to Tab 1'),
                  ),
                  Expanded(
                    child: LazyIndexedStack(
                      index: activeIndex,
                      itemCount: 2,
                      itemBuilder: (context, i) {
                        return Text('Content $i');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Content 0'), findsOneWidget);
      expect(find.text('Content 1'), findsNothing);

      // Tap button to switch to index 1
      await tester.tap(find.text('Switch to Tab 1'));
      await tester.pumpAndSettle();

      // Both should now exist in the tree, but Content 0 is offstage and has TickerMode disabled
      expect(find.text('Content 1'), findsOneWidget);
      expect(find.text('Content 0', skipOffstage: false), findsOneWidget);

      // Verify disabled TickerMode exists for inactive tab 0 (which is offstage)
      final disabledTickerFinder = find.byWidgetPredicate(
        (widget) => widget is TickerMode && !widget.enabled,
        skipOffstage: false,
      );
      expect(disabledTickerFinder, findsOneWidget);

      // Verify active tab 1 has enabled TickerMode
      final enabledTickerFinder = find.ancestor(
        of: find.text('Content 1'),
        matching: find.byType(TickerMode),
      );
      final TickerMode ticker1 = tester.widget(enabledTickerFinder.last);
      expect(ticker1.enabled, isTrue);
    });

    testWidgets('preserves state when navigating between tabs', (tester) async {
      int activeIndex = 0;

      await tester.pumpWidget(
        _wrapWithApp(
          StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  ElevatedButton(
                    onPressed: () => setState(() => activeIndex = 0),
                    child: const Text('Go Tab 0'),
                  ),
                  ElevatedButton(
                    onPressed: () => setState(() => activeIndex = 1),
                    child: const Text('Go Tab 1'),
                  ),
                  Expanded(
                    child: LazyIndexedStack(
                      index: activeIndex,
                      itemCount: 2,
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return const _StatefulCounterTab();
                        }
                        return const Text('Tab 1 Body');
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Counter: 0'), findsOneWidget);

      // Increment counter on Tab 0
      await tester.tap(find.text('Increment'));
      await tester.pumpAndSettle();
      expect(find.text('Counter: 1'), findsOneWidget);

      // Switch to Tab 1
      await tester.tap(find.text('Go Tab 1'));
      await tester.pumpAndSettle();
      expect(find.text('Tab 1 Body'), findsOneWidget);

      // Switch back to Tab 0
      await tester.tap(find.text('Go Tab 0'));
      await tester.pumpAndSettle();

      // Counter should retain state value 1
      expect(find.text('Counter: 1'), findsOneWidget);
    });
  });

  group('CountdownText Widget Tests', () {
    String getTodayDayOfWeek() {
      final now = DateTime.now();
      switch (now.weekday) {
        case DateTime.monday:
          return 'mon';
        case DateTime.tuesday:
          return 'tue';
        case DateTime.wednesday:
          return 'wed';
        case DateTime.thursday:
          return 'thu';
        case DateTime.friday:
          return 'fri';
        case DateTime.saturday:
          return 'sat';
        case DateTime.sunday:
          return 'sun';
        default:
          return 'mon';
      }
    }

    testWidgets('renders countdown format when class is scheduled for today in future', (tester) async {
      final now = DateTime.now();
      // Future class later today (or 23:59 if late)
      final targetHour = (now.hour + 2) % 24;
      final isFutureToday = targetHour > now.hour;

      final item = TimetableItem(
        id: 'test-class-today',
        title: 'Distributed Systems',
        shortTitle: 'DS',
        dayOfWeek: isFutureToday ? getTodayDayOfWeek() : 'sun',
        startTime: '${targetHour.toString().padLeft(2, '0')}:00',
        endTime: '${(targetHour + 1).toString().padLeft(2, '0')}:00',
        startHour: isFutureToday ? targetHour : 23,
        startMinute: 59,
        endHour: 23,
        endMinute: 59,
        category: 'Major',
        room: 'Lab 4',
        instructor: 'Dr. Turing',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          CountdownText(item: item),
        ),
      );
      await tester.pumpAndSettle();

      // Either NEXT CLASS IN or UPCOMING CLASS ON depending on hour
      expect(
        find.byType(CountdownText),
        findsOneWidget,
      );
    });

    testWidgets('renders upcoming class date label when scheduled for a different day', (tester) async {
      final now = DateTime.now();
      // Pick a weekday that is definitely not today
      final otherDay = now.weekday == DateTime.sunday ? 'mon' : 'sun';

      final item = TimetableItem(
        id: 'test-class-other-day',
        title: 'Quantum Computing',
        shortTitle: 'QC',
        dayOfWeek: otherDay,
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        startHour: 10,
        startMinute: 0,
        endHour: 11,
        endMinute: 30,
        category: 'Elective',
        room: 'Hall B',
        instructor: 'Dr. Feynman',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          CountdownText(item: item),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UPCOMING CLASS ON'), findsOneWidget);
      expect(
        find.textContaining('10:00 AM'),
        findsOneWidget,
      );
    });
  });
}

class _StatefulCounterTab extends StatefulWidget {
  const _StatefulCounterTab();

  @override
  State<_StatefulCounterTab> createState() => _StatefulCounterTabState();
}

class _StatefulCounterTabState extends State<_StatefulCounterTab> {
  int _count = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('Counter: $_count'),
        ElevatedButton(
          onPressed: () => setState(() => _count++),
          child: const Text('Increment'),
        ),
      ],
    );
  }
}
