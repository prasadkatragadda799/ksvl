import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';

/// A premium branded loader for KSVL Naturals.
///
/// Three sizes cover every loading context in the app:
///
///  * [KsvlLoader.page] — full-centre page loader shown during first load or
///    route transitions. Includes a subtle brand-tinted glow.
///  * [KsvlLoader.inline] — sits alongside content (e.g. "Checking location…").
///  * [KsvlLoader.button] — replaces button text while an action is in flight.
///    Designed to occupy the same optical weight as a label.
class KsvlLoader extends StatefulWidget {
  const KsvlLoader({
    super.key,
    this.size = 36,
    this.strokeWidth = 3.0,
    this.color,
  });

  /// Full-page centred loader — 48px with glow.
  const KsvlLoader.page({super.key})
      : size = 48,
        strokeWidth = 3.2,
        color = null;

  /// Inline loader that sits beside text — 24px, thinner.
  const KsvlLoader.inline({super.key})
      : size = 24,
        strokeWidth = 2.4,
        color = null;

  /// Button-replacement spinner — 20px, white by default.
  const KsvlLoader.button({super.key, this.color = Colors.white})
      : size = 20,
        strokeWidth = 2.4;

  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  State<KsvlLoader> createState() => _KsvlLoaderState();
}

class _KsvlLoaderState extends State<KsvlLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final brandColor = widget.color ?? k.brand;

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return CustomPaint(
            painter: _BrandSpinnerPainter(
              progress: _controller.value,
              color: brandColor,
              strokeWidth: widget.strokeWidth,
              trackColor: brandColor.withValues(alpha: 0.13),
            ),
          );
        },
      ),
    );
  }
}

/// Draws a smooth brand-coloured arc spinner with a subtle track and
/// a gradient tail that fades to transparent — much more premium than
/// the default Material spinner.
class _BrandSpinnerPainter extends CustomPainter {
  _BrandSpinnerPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final double strokeWidth;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Track ring.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 0.6
        ..color = trackColor,
    );

    // Spinning arc with sweep animation.
    // The arc length oscillates between short and long as it spins.
    final rotation = progress * math.pi * 2;

    // Sweep oscillates: short → long → short over the cycle.
    final sweepPhase = (math.sin(progress * math.pi * 2 - math.pi / 2) + 1) / 2;
    final sweepAngle = _lerpDouble(0.4, 1.4, sweepPhase) * math.pi;

    // Start angle advances faster than the sweep so the head races ahead.
    final startAngle = rotation * 2.6 - math.pi / 2;

    // Gradient sweep: solid at the head, fades at the tail.
    final sweepGradient = SweepGradient(
      startAngle: startAngle,
      endAngle: startAngle + sweepAngle,
      colors: [
        color.withValues(alpha: 0.0),
        color.withValues(alpha: 0.3),
        color,
      ],
      stops: const [0.0, 0.3, 1.0],
    );

    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = sweepGradient.createShader(rect);

    canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

    // Bright dot at the leading tip for extra premium feel.
    final tipAngle = startAngle + sweepAngle;
    final tipPoint = center +
        Offset(math.cos(tipAngle), math.sin(tipAngle)) * radius;
    canvas.drawCircle(
      tipPoint,
      strokeWidth * 0.65,
      Paint()..color = color,
    );
  }

  static double _lerpDouble(double a, double b, double t) => a + (b - a) * t;

  @override
  bool shouldRepaint(_BrandSpinnerPainter old) =>
      old.progress != progress || old.color != color;
}

/// A three-dot pulsing loader — used beneath content for a lighter visual
/// weight than a full spinner (e.g. "Loading your order…").
class KsvlDotsLoader extends StatefulWidget {
  const KsvlDotsLoader({super.key, this.size = 8, this.color});

  final double size;
  final Color? color;

  @override
  State<KsvlDotsLoader> createState() => _KsvlDotsLoaderState();
}

class _KsvlDotsLoaderState extends State<KsvlDotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final dotColor = widget.color ?? k.brand;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            // Each dot is offset by 0.2 of the cycle.
            final phase = (_controller.value + i * 0.2) % 1.0;
            final scale = _bounce(phase);
            final alpha = 0.35 + 0.65 * scale;

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: widget.size * 0.35),
              child: Transform.scale(
                scale: 0.6 + 0.4 * scale,
                child: Container(
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: dotColor.withValues(alpha: alpha),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Smooth bounce curve: peaks at phase 0.5, rests at 0 and 1.
  static double _bounce(double t) {
    return math.sin(t * math.pi).clamp(0.0, 1.0);
  }
}

/// Full-page loading overlay — centred spinner with optional message.
///
/// Used as a placeholder while the initial catalogue loads.
class KsvlPageLoader extends StatelessWidget {
  const KsvlPageLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Glow behind the spinner.
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: k.brand.withValues(alpha: 0.12),
                  blurRadius: 32,
                  spreadRadius: 8,
                ),
              ],
            ),
            child: const KsvlLoader.page(),
          ),
          if (message != null) ...[
            const SizedBox(height: KsvlSpace.xl),
            Text(
              message!,
              style: text.bodySmall?.copyWith(
                color: k.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
