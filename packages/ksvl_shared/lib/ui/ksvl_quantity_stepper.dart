import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';
import '../design/ksvl_typography.dart';

/// −/qty/+ control.
///
/// [KsvlStepperStyle.filled] is the in-card "this is in your cart" state;
/// [KsvlStepperStyle.outlined] is for lists where a row of solid blocks would
/// shout. Both keep 44px hit targets and tabular digits.
enum KsvlStepperStyle { filled, outlined }

class KsvlQuantityStepper extends StatelessWidget {
  const KsvlQuantityStepper({
    super.key,
    required this.quantity,
    required this.onDecrement,
    required this.onIncrement,
    this.style = KsvlStepperStyle.filled,
    this.height = 40,
    this.expand = false,
    this.label,
  });

  final int quantity;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  final KsvlStepperStyle style;
  final double height;

  /// Stretch to the parent's width — used as a full-width card action.
  final bool expand;

  /// Announced to screen readers, e.g. the product name.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final filled = style == KsvlStepperStyle.filled;
    final foreground = filled ? Colors.white : k.brand;

    final row = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      children: [
        _StepButton(
          icon: Icons.remove_rounded,
          color: foreground,
          size: height,
          tooltip: 'Decrease quantity',
          onTap: onDecrement,
        ),
        Flexible(
          flex: expand ? 1 : 0,
          child: Container(
            constraints: const BoxConstraints(minWidth: 32),
            alignment: Alignment.center,
            child: Text(
              '$quantity',
              style: TextStyle(
                color: foreground,
                fontWeight: FontWeight.w800,
                fontSize: 15,
                height: 1.2,
                fontFeatures: KsvlType.tabular,
              ),
            ),
          ),
        ),
        _StepButton(
          icon: Icons.add_rounded,
          color: foreground,
          size: height,
          tooltip: 'Increase quantity',
          onTap: onIncrement,
        ),
      ],
    );

    return Semantics(
      label: label == null ? 'Quantity' : 'Quantity of $label',
      value: '$quantity',
      child: AnimatedContainer(
        duration: KsvlMotion.fast,
        height: height,
        decoration: BoxDecoration(
          color: filled ? k.brand : Colors.transparent,
          borderRadius: KsvlRadius.allSm,
          border: Border.all(
            color: filled ? Colors.transparent : k.brand.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: row,
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final Color color;
  final double size;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allSm,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }
}
