import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';
import 'ksvl_tone.dart';

/// "There is nothing here" done properly: an icon with weight, a sentence that
/// says why, and — where one exists — the action that fixes it.
class KsvlEmptyState extends StatelessWidget {
  const KsvlEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = KsvlTone.neutral,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? message;
  final KsvlTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  /// Tightens the vertical rhythm for use inside a sheet or a short panel.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final colors = tone.resolve(context);
    final text = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: KsvlSpace.xxl,
          vertical: compact ? KsvlSpace.xl : KsvlSpace.huge,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 56 : 72,
              height: compact ? 56 : 72,
              decoration: BoxDecoration(
                color: colors.background,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                icon,
                size: compact ? 26 : 32,
                color: colors.foreground,
              ),
            ),
            SizedBox(height: compact ? KsvlSpace.md : KsvlSpace.lg),
            Text(
              title,
              textAlign: TextAlign.center,
              style: text.titleMedium,
            ),
            if (message != null) ...[
              const SizedBox(height: KsvlSpace.xs),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: k.textMuted),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: KsvlSpace.xl),
              OutlinedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
