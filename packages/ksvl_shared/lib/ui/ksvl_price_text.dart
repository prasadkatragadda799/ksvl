import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';
import '../design/ksvl_typography.dart';
import '../utils/price_format.dart';

enum KsvlPriceSize { small, medium, large }

/// Special price beside its struck-through regular price.
///
/// Digits are tabular so a price never shifts width when a variant changes,
/// and the struck price sits *before* the live one — the eye lands on the
/// number being charged, not the one being crossed out.
class KsvlPriceText extends StatelessWidget {
  const KsvlPriceText({
    super.key,
    required this.regularPrice,
    required this.specialPrice,
    this.size = KsvlPriceSize.medium,
    this.color,
    this.showStrikethrough = true,
  });

  final double regularPrice;
  final double specialPrice;
  final KsvlPriceSize size;
  final Color? color;
  final bool showStrikethrough;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final hasDiscount = specialPrice < regularPrice;

    final (double priceSize, double strikeSize) = switch (size) {
      KsvlPriceSize.small => (14, 11.5),
      KsvlPriceSize.medium => (16, 13),
      KsvlPriceSize.large => (22, 15),
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          formatRupee(specialPrice),
          style: TextStyle(
            fontSize: priceSize,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            height: 1.2,
            color: color ?? k.textPrimary,
            fontFeatures: KsvlType.tabular,
          ),
        ),
        if (hasDiscount && showStrikethrough) ...[
          const SizedBox(width: KsvlSpace.sm),
          Text(
            formatRupee(regularPrice),
            style: TextStyle(
              fontSize: strikeSize,
              fontWeight: FontWeight.w500,
              height: 1.2,
              color: k.textMuted,
              decoration: TextDecoration.lineThrough,
              decorationColor: k.textMuted,
              decorationThickness: 1.5,
              fontFeatures: KsvlType.tabular,
            ),
          ),
        ],
      ],
    );
  }
}

/// A money value on its own — totals, subtotals, stat figures.
class KsvlAmount extends StatelessWidget {
  const KsvlAmount(
    this.value, {
    super.key,
    this.fontSize = 16,
    this.fontWeight = FontWeight.w800,
    this.color,
  });

  final double value;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatRupee(value),
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: -0.3,
        height: 1.2,
        color: color ?? KsvlColors.of(context).textPrimary,
        fontFeatures: KsvlType.tabular,
      ),
    );
  }
}
