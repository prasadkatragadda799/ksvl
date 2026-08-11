import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// The living surface the storefront sits on: dry-fruit silhouettes drifting
/// behind the product grid.
///
/// Three things make it survive a long scroll without becoming noise:
///
///  * it is painted *behind* the scroll view, not inside it, so it keeps
///    animating while the grid moves and never gets rebuilt by the list;
///  * it takes the scroll offset and moves the shapes at a fraction of that
///    speed, wrapping them around the viewport — the page reads as depth
///    rather than as a static wallpaper that betrays itself the moment you
///    scroll;
///  * the shapes are drawn at single-digit opacity in brand tints, so a
///    product photo always wins the eye.
///
/// It is one [CustomPaint] with one controller, not N animated widgets — a
/// grid on a mid-range phone cannot afford twenty layout-participating
/// particles.
class DryFruitBackdrop extends StatefulWidget {
  const DryFruitBackdrop({
    super.key,
    this.scrollOffset,
    this.seedCount = 22,
  });

  /// Live scroll position of the list in front of the backdrop, if there is
  /// one. Drives the parallax; the drift animation runs regardless.
  final ValueListenable<double>? scrollOffset;

  /// How many shapes to scatter. Tuned down automatically on small viewports.
  final int seedCount;

  @override
  State<DryFruitBackdrop> createState() => _DryFruitBackdropState();
}

class _DryFruitBackdropState extends State<DryFruitBackdrop>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 46),
  );

  List<_Seed> _seeds = const [];
  int _seedCount = 0;

  @override
  void initState() {
    super.initState();
    _seeds = _buildSeeds(widget.seedCount);
    _seedCount = widget.seedCount;
  }

  @override
  void didUpdateWidget(covariant DryFruitBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seedCount != widget.seedCount) {
      _seeds = _buildSeeds(widget.seedCount);
      _seedCount = widget.seedCount;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Honour the OS "reduce motion" switch: the texture stays, the drift stops.
    final reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) {
      _drift.stop();
    } else if (!_drift.isAnimating) {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Fixed seed so the scatter is identical across rebuilds and hot reloads —
  /// a background that reshuffles when the theme changes looks broken.
  static List<_Seed> _buildSeeds(int count) {
    final random = math.Random(20250811);
    return List<_Seed>.generate(count, (index) {
      return _Seed(
        x: random.nextDouble(),
        y: random.nextDouble(),
        scale: 44 + random.nextDouble() * 78,
        phase: random.nextDouble() * math.pi * 2,
        tilt: random.nextDouble() * math.pi * 2,
        spin: (random.nextDouble() - 0.5) * 0.9,
        depth: 0.25 + random.nextDouble() * 0.75,
        shape: index % _DryFruitPainter.shapeCount,
        tone: random.nextInt(4),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final offset = widget.scrollOffset;

    return RepaintBoundary(
      child: CustomPaint(
        isComplex: true,
        willChange: true,
        painter: _DryFruitPainter(
          repaint: offset == null
              ? _drift
              : Listenable.merge(<Listenable>[_drift, offset]),
          drift: _drift,
          scrollOffset: offset,
          seeds: _seeds,
          base: k.surfaceSunken,
          wash: k.brandSoft,
          tints: <Color>[k.brand, k.success, k.warning, k.brandStrong],
          shapeAlpha: isDark ? 0.11 : 0.075,
          size: _seedCount,
        ),
        size: Size.infinite,
      ),
    );
  }
}

/// One scattered silhouette. Immutable — the painter derives every frame from
/// these plus the two animation values.
@immutable
class _Seed {
  const _Seed({
    required this.x,
    required this.y,
    required this.scale,
    required this.phase,
    required this.tilt,
    required this.spin,
    required this.depth,
    required this.shape,
    required this.tone,
  });

  /// Resting position as a fraction of the viewport.
  final double x;
  final double y;

  /// Diameter in logical pixels.
  final double scale;

  /// Where in the bob cycle this shape starts, so they never move as a block.
  final double phase;

  final double tilt;
  final double spin;

  /// 0 = far away (barely moves), 1 = close (moves most). Also scales opacity.
  final double depth;

  final int shape;
  final int tone;
}

class _DryFruitPainter extends CustomPainter {
  _DryFruitPainter({
    required Listenable repaint,
    required this.drift,
    required this.scrollOffset,
    required this.seeds,
    required this.base,
    required this.wash,
    required this.tints,
    required this.shapeAlpha,
    required this.size,
  }) : super(repaint: repaint);

  static const int shapeCount = 4;

  final Animation<double> drift;
  final ValueListenable<double>? scrollOffset;
  final List<_Seed> seeds;
  final Color base;
  final Color wash;
  final List<Color> tints;
  final double shapeAlpha;
  final int size;

  @override
  void paint(Canvas canvas, Size canvasSize) {
    final bounds = Offset.zero & canvasSize;

    // The page colour itself, so the scroll view above can stay transparent.
    canvas.drawRect(bounds, Paint()..color = base);

    // A soft brand wash in the top corner keeps the empty upper gutter from
    // reading as flat paper.
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.7, -1.1),
          radius: 1.35,
          colors: <Color>[wash, base.withValues(alpha: 0)],
        ).createShader(bounds),
    );

    if (canvasSize.isEmpty) return;

    final t = drift.value;
    final scroll = scrollOffset?.value ?? 0;
    // Wrap over a band taller than the viewport so a shape leaving the top
    // re-enters from below instead of popping in mid-screen.
    final band = canvasSize.height + 240;

    for (final seed in seeds) {
      final bob = math.sin(t * math.pi * 2 + seed.phase);
      final sway = math.cos(t * math.pi * 2 * 0.6 + seed.phase);

      final dx = seed.x * canvasSize.width + sway * 16 * seed.depth;
      final rawY = seed.y * band +
          bob * 14 * seed.depth -
          scroll * 0.22 * seed.depth;
      final dy = rawY % band - 120;

      final paint = Paint()
        ..style = PaintingStyle.fill
        ..color = tints[seed.tone % tints.length].withValues(
          alpha: shapeAlpha * (0.55 + seed.depth * 0.45),
        );

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(seed.tilt + t * math.pi * 2 * seed.spin * 0.35);
      canvas.scale(seed.scale);
      canvas.drawPath(_pathFor(seed.shape), paint);
      canvas.restore();
    }
  }

  /// Silhouettes in a unit box centred on the origin, so a single `scale` call
  /// sizes them. Built from ovals and quadratics only — no [Path.combine], so
  /// they render identically on every Flutter web backend.
  static Path _pathFor(int shape) {
    switch (shape % shapeCount) {
      // Almond: a lens with two points.
      case 0:
        return Path()
          ..moveTo(0, -0.5)
          ..quadraticBezierTo(0.34, -0.16, 0.26, 0.24)
          ..quadraticBezierTo(0.16, 0.5, 0, 0.5)
          ..quadraticBezierTo(-0.16, 0.5, -0.26, 0.24)
          ..quadraticBezierTo(-0.34, -0.16, 0, -0.5)
          ..close();

      // Cashew: a full disc with a second disc punched out of one flank.
      case 1:
        return Path()
          ..fillType = PathFillType.evenOdd
          ..addOval(Rect.fromCircle(center: Offset.zero, radius: 0.5))
          ..addOval(
            Rect.fromCircle(center: const Offset(0.30, -0.12), radius: 0.40),
          );

      // Pistachio: an oval split by a hairline shell crack.
      case 2:
        return Path()
          ..fillType = PathFillType.evenOdd
          ..addOval(
            Rect.fromCenter(center: Offset.zero, width: 0.68, height: 1),
          )
          ..addOval(
            Rect.fromCenter(center: Offset.zero, width: 0.09, height: 0.74),
          );

      // Raisin cluster: three overlapping berries.
      default:
        return Path()
          ..addOval(
            Rect.fromCircle(center: const Offset(-0.16, 0.12), radius: 0.30),
          )
          ..addOval(
            Rect.fromCircle(center: const Offset(0.19, 0.19), radius: 0.24),
          )
          ..addOval(
            Rect.fromCircle(center: const Offset(0.06, -0.22), radius: 0.27),
          );
    }
  }

  @override
  bool shouldRepaint(covariant _DryFruitPainter old) {
    return old.base != base ||
        old.wash != wash ||
        old.shapeAlpha != shapeAlpha ||
        old.size != size ||
        !identical(old.seeds, seeds);
  }
}
