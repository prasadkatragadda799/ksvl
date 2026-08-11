import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';

/// Title (+ optional caption) on the left, an action or counter on the right.
///
/// Every list on both apps is introduced by one of these, which is what makes
/// long scrolling screens feel sectioned rather than stacked.
class KsvlSectionHeader extends StatelessWidget {
  const KsvlSectionHeader({
    super.key,
    required this.title,
    this.caption,
    this.trailing,
    this.onActionTap,
    this.actionLabel,
    this.padding = EdgeInsets.zero,
  });

  final String title;
  final String? caption;
  final Widget? trailing;
  final VoidCallback? onActionTap;
  final String? actionLabel;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: text.titleMedium),
                if (caption != null) ...[
                  const SizedBox(height: KsvlSpace.xxs),
                  Text(
                    caption!,
                    style: text.bodySmall?.copyWith(color: k.textMuted),
                  ),
                ],
              ],
            ),
          ),
          ?trailing,
          if (trailing == null && actionLabel != null && onActionTap != null)
            TextButton(
              onPressed: onActionTap,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

/// Small all-caps rule used inside cards to separate blocks of detail.
class KsvlOverline extends StatelessWidget {
  const KsvlOverline(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: KsvlColors.of(context).textMuted,
            letterSpacing: 0.8,
          ),
    );
  }
}
