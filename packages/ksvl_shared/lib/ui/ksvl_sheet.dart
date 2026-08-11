import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';

/// Opens a modal sheet with KSVL's shape, scrim and safe-area behaviour.
Future<T?> showKsvlSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    useSafeArea: false,
    backgroundColor: Theme.of(context).colorScheme.surface,
    barrierColor: KsvlColors.of(context).overlayScrim,
    shape: const RoundedRectangleBorder(borderRadius: KsvlRadius.topSheet),
    clipBehavior: Clip.antiAlias,
    constraints: const BoxConstraints(maxWidth: 560),
    builder: builder,
  );
}

/// Standard sheet layout: grabber, header, scrolling body, pinned footer.
///
/// The footer stays put while the body scrolls, so the primary action of a
/// checkout or a form is never something the user has to go looking for.
class KsvlSheetScaffold extends StatelessWidget {
  const KsvlSheetScaffold({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.footer,
    this.showClose = true,
    this.showGrabber = true,
    this.bodyPadding = const EdgeInsets.fromLTRB(
      KsvlSpace.xl,
      0,
      KsvlSpace.xl,
      KsvlSpace.xl,
    ),
    this.heightFactor = 0.92,
    this.leading,
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Pinned to the bottom, outside the scroll area.
  final Widget? footer;

  final bool showClose;
  final bool showGrabber;
  final EdgeInsetsGeometry bodyPadding;

  /// Fraction of screen height the sheet may occupy at most.
  final double heightFactor;

  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    final topPadding = media.padding.top;
    final bottomSafeArea = media.padding.bottom;

    // How far the sheet may be lifted so it clears the on-screen keyboard.
    //
    // This is clamped, and the clamp is the whole point. A phone browser that
    // *also* shrinks the layout viewport when the keyboard opens reports both
    // a smaller `size.height` and a non-zero `viewInsets.bottom`; lifting by
    // the raw inset in that case pushed the sheet — number field and all —
    // clean off the top of the screen. Never lift by more than the room that
    // exists, and always leave a usable sheet on screen.
    final minSheetHeight = math.min(200.0, screenHeight * 0.4);
    final maxLift = math.max(
      0.0,
      screenHeight - topPadding - minSheetHeight - 16.0,
    );
    final lift = math.min(media.viewInsets.bottom, maxLift);

    // What is left once the keyboard and the notch have taken their share.
    final visibleHeight = screenHeight - lift - topPadding - 16.0;
    final maxSheetHeight = visibleHeight > 0
        ? math.min(screenHeight * heightFactor, math.max(150.0, visibleHeight))
        : screenHeight * heightFactor;

    final effectiveBottomPadding = math.max(lift, bottomSafeArea);

    return AnimatedPadding(
      // The keyboard slides; a sheet that teleports to its new position while
      // it does reads as a glitch.
      duration: KsvlMotion.fast,
      curve: KsvlMotion.standard,
      padding: EdgeInsets.only(bottom: effectiveBottomPadding),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: maxSheetHeight,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showGrabber)
              Padding(
                padding: const EdgeInsets.only(top: KsvlSpace.md),
                child: Center(
                  child: Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: k.borderStrong,
                      borderRadius: KsvlRadius.allPill,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                KsvlSpace.xl,
                KsvlSpace.lg,
                showClose ? KsvlSpace.sm : KsvlSpace.xl,
                KsvlSpace.lg,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: KsvlSpace.md),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: text.headlineSmall),
                        if (subtitle != null) ...[
                          const SizedBox(height: KsvlSpace.xxs),
                          Text(
                            subtitle!,
                            style: text.bodyMedium?.copyWith(
                              color: k.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showClose)
                    IconButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.close_rounded),
                      tooltip: 'Close',
                      color: k.textMuted,
                    ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                // Anything the clamp above refused to lift still overlaps the
                // sheet, so the body carries it as padding instead. Flutter
                // scrolls a focused field into the visible part of its
                // scrollable, and this is what makes that part large enough —
                // the field ends up above the keyboard even on a browser that
                // never resizes its viewport.
                padding: bodyPadding.add(
                  EdgeInsets.only(
                    bottom: math.max(0.0, media.viewInsets.bottom - lift),
                  ),
                ),
                // Dragging the list is how people dismiss a keyboard they are
                // done with.
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: child,
              ),
            ),
            if (footer != null)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border(top: BorderSide(color: k.border)),
                ),
                padding: const EdgeInsets.fromLTRB(
                  KsvlSpace.xl,
                  KsvlSpace.lg,
                  KsvlSpace.xl,
                  KsvlSpace.xl,
                ),
                child: footer,
              ),
          ],
        ),
      ),
    );
  }
}
