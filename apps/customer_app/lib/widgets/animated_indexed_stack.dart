import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// An [IndexedStack] that cross-fades and gently slides between its children
/// when [index] changes, instead of hard-cutting.
///
/// All children stay alive in the tree (like a plain [IndexedStack]), so scroll
/// positions, focus nodes and provider state are preserved across tab switches.
/// Only the visibility and the animation wrappers change.
class AnimatedIndexedStack extends StatefulWidget {
  const AnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
    this.duration = KsvlMotion.normal,
    this.curve = KsvlMotion.standard,
    this.slideOffset = 20,
  });

  /// Which child to show.
  final int index;

  /// The tab bodies. All remain mounted regardless of [index].
  final List<Widget> children;

  /// How long the crossfade takes.
  final Duration duration;

  /// The easing curve.
  final Curve curve;

  /// How many logical pixels the incoming tab slides up from below.
  final double slideOffset;

  @override
  State<AnimatedIndexedStack> createState() => _AnimatedIndexedStackState();
}

class _AnimatedIndexedStackState extends State<AnimatedIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _fadeOut;
  late final Animation<Offset> _slideIn;

  int _previousIndex = 0;
  int _currentIndex = 0;
  bool _isAnimating = false;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.index;
    _previousIndex = widget.index;

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    final curved = CurvedAnimation(
      parent: _controller,
      curve: widget.curve,
    );

    _fadeIn = Tween<double>(begin: 0, end: 1).animate(curved);
    _fadeOut = Tween<double>(begin: 1, end: 0).animate(curved);
    _slideIn = Tween<Offset>(
      begin: Offset(0, widget.slideOffset),
      end: Offset.zero,
    ).animate(curved);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _isAnimating = false);
      }
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _previousIndex = oldWidget.index;
      _currentIndex = widget.index;
      _isAnimating = true;
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: List.generate(widget.children.length, (i) {
        final isCurrent = i == _currentIndex;
        final isPrevious = i == _previousIndex && _isAnimating;
        final isVisible = isCurrent || isPrevious;

        Widget child = Offstage(
          offstage: !isVisible,
          child: TickerMode(
            enabled: isVisible,
            child: widget.children[i],
          ),
        );

        if (_isAnimating) {
          if (isCurrent) {
            child = AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.translate(
                  offset: _slideIn.value,
                  child: Opacity(
                    opacity: _fadeIn.value,
                    child: child,
                  ),
                );
              },
              child: child,
            );
          } else if (isPrevious) {
            child = AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Opacity(
                  opacity: _fadeOut.value,
                  child: child,
                );
              },
              child: child,
            );
          }
        }

        return child;
      }),
    );
  }
}
