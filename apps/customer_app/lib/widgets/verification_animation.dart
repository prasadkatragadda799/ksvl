import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Shows a full-attention verification result animation over the current UI.
///
/// Success auto-dismisses once the burst settles; failure waits for the user
/// to tap "Try again" so they register what happened.
Future<void> showVerificationResult(
  BuildContext context, {
  required bool success,
  String? title,
  String? message,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black.withValues(alpha: 0.62),
    builder: (_) => _VerificationDialog(
      success: success,
      title: title ?? (success ? 'Number verified' : 'Wrong code'),
      message: message ??
          (success
              ? 'Your mobile number is confirmed.'
              : 'That OTP didn’t match. Give it another go.'),
    ),
  );
}

class _VerificationDialog extends StatefulWidget {
  const _VerificationDialog({
    required this.success,
    required this.title,
    required this.message,
  });

  final bool success;
  final String title;
  final String message;

  @override
  State<_VerificationDialog> createState() => _VerificationDialogState();
}

class _VerificationDialogState extends State<_VerificationDialog>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.success
        ? const Duration(milliseconds: 1150)
        : const Duration(milliseconds: 820),
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    if (widget.success) {
      _controller.addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          Future<void>.delayed(const Duration(milliseconds: 420), () {
            if (mounted) Navigator.of(context).pop();
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final accent = widget.success ? k.success : k.danger;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(KsvlSpace.xl),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Material(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: KsvlRadius.allLg,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: KsvlSpace.xl,
                vertical: KsvlSpace.xxl,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 160,
                    height: 160,
                    child: AnimatedBuilder(
                      animation: _controller,
                      builder: (context, _) {
                        final t = _controller.value;
                        final shake = widget.success
                            ? 0.0
                            : math.sin(t * math.pi * 6) *
                                12 *
                                (1 - t).clamp(0.0, 1.0);
                        return Transform.translate(
                          offset: Offset(shake, 0),
                          child: CustomPaint(
                            painter: widget.success
                                ? _SuccessPainter(progress: t, color: accent)
                                : _FailurePainter(progress: t, color: accent),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: KsvlSpace.xl),
                  Text(
                    widget.title,
                    textAlign: TextAlign.center,
                    style: text.titleLarge?.copyWith(color: accent),
                  ),
                  const SizedBox(height: KsvlSpace.sm),
                  Text(
                    widget.message,
                    textAlign: TextAlign.center,
                    style: text.bodyMedium?.copyWith(color: k.textSecondary),
                  ),
                  if (!widget.success) ...[
                    const SizedBox(height: KsvlSpace.xl),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Try again'),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SuccessPainter extends CustomPainter {
  _SuccessPainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    // Expanding halo ring that fades as it grows.
    final ringT = Curves.easeOut.transform(progress.clamp(0.0, 1.0));
    if (ringT > 0) {
      final ringPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3 * (1 - ringT) + 0.5
        ..color = color.withValues(alpha: (1 - ringT) * 0.5);
      canvas.drawCircle(center, maxR * (0.55 + ringT * 0.7), ringPaint);
    }

    // Particle burst.
    final burstT = ((progress - 0.15) / 0.6).clamp(0.0, 1.0);
    if (burstT > 0 && burstT < 1) {
      final dotPaint = Paint()..color = color.withValues(alpha: 1 - burstT);
      const count = 10;
      for (var i = 0; i < count; i++) {
        final angle = (i / count) * math.pi * 2;
        final dist = maxR * (0.45 + burstT * 0.6);
        final p = center +
            Offset(math.cos(angle), math.sin(angle)) * dist;
        canvas.drawCircle(p, 3.2 * (1 - burstT) + 1, dotPaint);
      }
    }

    // Core circle scales in with an overshoot.
    final coreT = Curves.easeOutBack.transform(
      ((progress) / 0.55).clamp(0.0, 1.0),
    );
    final coreR = maxR * 0.5 * coreT;
    canvas.drawCircle(center, coreR, Paint()..color = color);
    canvas.drawCircle(
      center,
      coreR,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = color.withValues(alpha: 0.35 * coreT),
    );

    // Check mark stroke, drawn after the core has popped.
    final checkT = ((progress - 0.45) / 0.4).clamp(0.0, 1.0);
    if (checkT > 0) {
      final r = maxR * 0.5;
      final p1 = center + Offset(-r * 0.42, r * 0.02);
      final p2 = center + Offset(-r * 0.12, r * 0.34);
      final p3 = center + Offset(r * 0.45, -r * 0.32);
      final path = Path()..moveTo(p1.dx, p1.dy);
      final firstLen = 0.45;
      if (checkT <= firstLen) {
        final f = checkT / firstLen;
        path.lineTo(
          p1.dx + (p2.dx - p1.dx) * f,
          p1.dy + (p2.dy - p1.dy) * f,
        );
      } else {
        path.lineTo(p2.dx, p2.dy);
        final f = (checkT - firstLen) / (1 - firstLen);
        path.lineTo(
          p2.dx + (p3.dx - p2.dx) * f,
          p2.dy + (p3.dy - p2.dy) * f,
        );
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 6
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..color = Colors.white,
      );
    }
  }

  @override
  bool shouldRepaint(_SuccessPainter old) =>
      old.progress != progress || old.color != color;
}

class _FailurePainter extends CustomPainter {
  _FailurePainter({required this.progress, required this.color});

  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final maxR = size.shortestSide / 2;

    final coreT = Curves.easeOutBack.transform(
      (progress / 0.5).clamp(0.0, 1.0),
    );
    final coreR = maxR * 0.5 * coreT;
    canvas.drawCircle(center, coreR, Paint()..color = color);

    // Two strokes of the cross draw in sequence.
    final r = maxR * 0.5;
    final crossT = ((progress - 0.35) / 0.5).clamp(0.0, 1.0);
    final white = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final a1 = center + Offset(-r * 0.34, -r * 0.34);
    final a2 = center + Offset(r * 0.34, r * 0.34);
    final b1 = center + Offset(r * 0.34, -r * 0.34);
    final b2 = center + Offset(-r * 0.34, r * 0.34);

    final firstLen = 0.5;
    if (crossT > 0) {
      final f = (crossT / firstLen).clamp(0.0, 1.0);
      canvas.drawLine(
        a1,
        a1 + (a2 - a1) * f,
        white,
      );
    }
    if (crossT > firstLen) {
      final f = ((crossT - firstLen) / (1 - firstLen)).clamp(0.0, 1.0);
      canvas.drawLine(
        b1,
        b1 + (b2 - b1) * f,
        white,
      );
    }
  }

  @override
  bool shouldRepaint(_FailurePainter old) =>
      old.progress != progress || old.color != color;
}
