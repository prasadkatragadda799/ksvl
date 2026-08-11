import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';

/// Up to three nutrition highlights shown on customer product cards/details.
class KsvlVitaminChips extends StatelessWidget {
  const KsvlVitaminChips({
    super.key,
    required this.vitamins,
    this.dense = false,
    this.max = 3,
  });

  final List<String> vitamins;
  final bool dense;
  final int max;

  @override
  Widget build(BuildContext context) {
    final items = vitamins
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .take(max)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();

    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Wrap(
      spacing: dense ? 4 : 6,
      runSpacing: dense ? 4 : 6,
      children: [
        for (final vitamin in items)
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: dense ? 7 : 9,
              vertical: dense ? 3 : 5,
            ),
            decoration: BoxDecoration(
              color: k.successSoft,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: k.success.withValues(alpha: 0.28)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.eco_rounded,
                  size: dense ? 11 : 13,
                  color: k.success,
                ),
                SizedBox(width: dense ? 3 : 4),
                Text(
                  vitamin,
                  style: (dense ? text.labelSmall : text.labelMedium)?.copyWith(
                    color: k.success,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                    fontSize: dense ? 10 : 12,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
