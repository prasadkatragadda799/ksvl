import 'package:flutter/material.dart';

import '../design/ksvl_tokens.dart';

/// Centres content and caps its width.
///
/// The storefront is a PWA that will be opened in a 1920px browser window;
/// without this, product rows stretch into an unscannable ribbon.
class KsvlPageWidth extends StatelessWidget {
  const KsvlPageWidth({
    super.key,
    required this.child,
    this.maxWidth = KsvlBreakpoint.maxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Sliver form of [KsvlPageWidth], for use inside a [CustomScrollView].
class KsvlSliverPageWidth extends StatelessWidget {
  const KsvlSliverPageWidth({
    super.key,
    required this.sliver,
    this.maxWidth = KsvlBreakpoint.maxContentWidth,
  });

  final Widget sliver;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final overflow = width - maxWidth;
    if (overflow <= 0) return sliver;

    final inset = overflow / 2;
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      sliver: sliver,
    );
  }
}

/// Shimmering placeholder block for loading states.
class KsvlSkeleton extends StatefulWidget {
  const KsvlSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.radius = KsvlRadius.xs,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<KsvlSkeleton> createState() => _KsvlSkeletonState();
}

class _KsvlSkeletonState extends State<KsvlSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(
              scheme.surfaceContainerHigh,
              scheme.surfaceContainerLow,
              _controller.value,
            ),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        );
      },
    );
  }
}
