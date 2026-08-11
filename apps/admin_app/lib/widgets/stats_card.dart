import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// A single figure from the dashboard.
///
/// The value is the largest thing in the tile and the label sits under it —
/// a manager glancing at this screen is looking for numbers, not captions.
class StatsCard extends StatelessWidget {
  const StatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.tone = KsvlTone.brand,
    this.caption,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final KsvlTone tone;

  /// Optional supporting line, e.g. "needs packing".
  final String? caption;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final colors = tone.resolve(context);
    final text = Theme.of(context).textTheme;

    return KsvlCard(
      onTap: onTap,
      semanticLabel: '$title: $value',
      padding: const EdgeInsets.all(KsvlSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.background,
                  borderRadius: KsvlRadius.allSm,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(icon, size: 19, color: colors.foreground),
              ),
              const Spacer(),
              if (onTap != null)
                Icon(
                  Icons.arrow_outward_rounded,
                  size: 16,
                  color: k.textDisabled,
                ),
            ],
          ),
          const SizedBox(height: KsvlSpace.md),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: text.headlineMedium?.copyWith(
                fontFeatures: KsvlType.tabular,
              ),
            ),
          ),
          const SizedBox(height: KsvlSpace.xxs),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: text.labelMedium?.copyWith(color: k.textSecondary),
          ),
          if (caption != null)
            Text(
              caption!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: text.bodySmall?.copyWith(color: colors.foreground),
            ),
        ],
      ),
    );
  }
}
