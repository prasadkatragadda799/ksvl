import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Open/closed control for the whole shop.
///
/// This used to be a switch crammed into the app bar next to a badge. It is
/// the single most consequential control in the admin app, so it now owns the
/// top of the dashboard and states its consequence in words.
class StoreStatusCard extends StatelessWidget {
  const StoreStatusCard({
    super.key,
    required this.isOpen,
    required this.onChanged,
  });

  final bool isOpen;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final tone = isOpen ? KsvlTone.success : KsvlTone.danger;
    final colors = tone.resolve(context);

    return KsvlCard(
      padding: const EdgeInsets.all(KsvlSpace.lg),
      borderColor: colors.border,
      color: colors.background,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              isOpen ? Icons.storefront_rounded : Icons.nightlight_round,
              color: colors.foreground,
              size: 22,
            ),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOpen ? 'Store is open' : 'Store is closed',
                      style: text.titleMedium?.copyWith(
                        color: colors.foreground,
                      ),
                    ),
                    const SizedBox(width: KsvlSpace.sm),
                    _LiveDot(color: colors.foreground, pulse: isOpen),
                  ],
                ),
                const SizedBox(height: KsvlSpace.xxs),
                Text(
                  isOpen
                      ? 'Customers can browse and place orders'
                      : 'Customers cannot place new orders',
                  style: text.bodySmall?.copyWith(color: k.textSecondary),
                ),
              ],
            ),
          ),
          Switch(
            value: isOpen,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// Slow breathing dot — a quiet signal that the status is live, not a snapshot.
class _LiveDot extends StatefulWidget {
  const _LiveDot({required this.color, required this.pulse});

  final Color color;
  final bool pulse;

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  );

  @override
  void initState() {
    super.initState();
    if (widget.pulse) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _LiveDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulse && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.pulse && _controller.isAnimating) {
      _controller.stop();
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final opacity = widget.pulse ? 0.35 + (_controller.value * 0.65) : 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: opacity),
            shape: BoxShape.circle,
          ),
        );
      },
    );
  }
}
