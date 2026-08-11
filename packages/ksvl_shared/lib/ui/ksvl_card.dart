import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';

/// The standard KSVL container: warm surface, hairline border, layered shadow.
///
/// Everything that reads as "a thing" — a product, an order, a stat — sits in
/// one of these, which is what gives both apps a single visual grammar.
class KsvlCard extends StatefulWidget {
  const KsvlCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(KsvlSpace.lg),
    this.onTap,
    this.color,
    this.borderColor,
    this.radius = KsvlRadius.md,
    this.elevated = false,
    this.clipContent = true,
    this.semanticLabel,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;
  final double radius;

  /// Raises the resting shadow — use for cards that float above a list.
  final bool elevated;

  final bool clipContent;
  final String? semanticLabel;

  @override
  State<KsvlCard> createState() => _KsvlCardState();
}

class _KsvlCardState extends State<KsvlCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final theme = Theme.of(context);
    final radius = BorderRadius.circular(widget.radius);
    final interactive = widget.onTap != null;
    final lifted = widget.elevated || (interactive && _hovered);

    final content = Padding(padding: widget.padding, child: widget.child);

    return AnimatedContainer(
      duration: KsvlMotion.fast,
      curve: KsvlMotion.standard,
      decoration: BoxDecoration(
        color: widget.color ?? theme.colorScheme.surface,
        borderRadius: radius,
        border: Border.all(
          color: widget.borderColor ??
              (interactive && _hovered
                  ? k.brand.withValues(alpha: 0.35)
                  : k.border),
        ),
        boxShadow: lifted ? KsvlShadow.md : KsvlShadow.sm,
      ),
      child: Material(
        type: MaterialType.transparency,
        borderRadius: radius,
        clipBehavior: widget.clipContent ? Clip.antiAlias : Clip.none,
        child: interactive
            ? InkWell(
                onTap: widget.onTap,
                borderRadius: radius,
                onHover: (value) => setState(() => _hovered = value),
                hoverColor: k.brand.withValues(alpha: 0.03),
                splashColor: k.brand.withValues(alpha: 0.06),
                highlightColor: k.brand.withValues(alpha: 0.04),
                child: Semantics(
                  label: widget.semanticLabel,
                  button: true,
                  child: content,
                ),
              )
            : content,
      ),
    );
  }
}
