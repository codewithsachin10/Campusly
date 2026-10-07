import 'package:flutter/material.dart';

/// Efficient IndexedStack that lazily inflates children only when first visited
/// and disables animation tickers on inactive tabs.
class LazyIndexedStack extends StatefulWidget {
  final int index;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final AlignmentGeometry alignment;
  final TextDirection? textDirection;
  final StackFit sizing;

  const LazyIndexedStack({
    super.key,
    required this.index,
    required this.itemCount,
    required this.itemBuilder,
    this.alignment = AlignmentDirectional.topStart,
    this.textDirection,
    this.sizing = StackFit.loose,
  });

  @override
  State<LazyIndexedStack> createState() => _LazyIndexedStackState();
}

class _LazyIndexedStackState extends State<LazyIndexedStack> {
  final Set<int> _activatedIndices = <int>{};

  @override
  void initState() {
    super.initState();
    _activatedIndices.add(widget.index);
  }

  @override
  void didUpdateWidget(covariant LazyIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    _activatedIndices.add(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = List<Widget>.generate(
      widget.itemCount,
      (i) {
        if (!_activatedIndices.contains(i)) {
          return const SizedBox.shrink();
        }

        final isSelected = i == widget.index;
        return KeyedSubtree(
          key: ValueKey<int>(i),
          child: TickerMode(
            enabled: isSelected,
            child: widget.itemBuilder(context, i),
          ),
        );
      },
      growable: false,
    );

    return IndexedStack(
      index: widget.index,
      alignment: widget.alignment,
      textDirection: widget.textDirection,
      sizing: widget.sizing,
      children: children,
    );
  }
}
