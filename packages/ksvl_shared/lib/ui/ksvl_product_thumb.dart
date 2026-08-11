import 'package:flutter/material.dart';

import '../design/ksvl_semantics.dart';
import '../design/ksvl_tokens.dart';
import '../models/catalog_category.dart';
import 'ksvl_category_style.dart';

/// Product visual: photo when available, otherwise emoji on a tinted tile.
class KsvlProductThumb extends StatefulWidget {
  const KsvlProductThumb({
    super.key,
    required this.emoji,
    this.imageUrl,
    this.category,
    this.styleIndex = 0,
    this.size,
    this.glyphSize,
    this.radius = KsvlRadius.sm,
    this.animate = true,
    this.fit = BoxFit.cover,
  });

  final String emoji;
  final String? imageUrl;
  final CatalogCategory? category;
  final int styleIndex;

  final double? size;
  final double? glyphSize;
  final double radius;
  final bool animate;
  final BoxFit fit;

  bool get hasPhoto => imageUrl != null && imageUrl!.trim().isNotEmpty;

  @override
  State<KsvlProductThumb> createState() => _KsvlProductThumbState();
}

class _KsvlProductThumbState extends State<KsvlProductThumb> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (!widget.animate) {
      _visible = true;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  void didUpdateWidget(covariant KsvlProductThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    final emojiChanged = oldWidget.emoji != widget.emoji;
    final photoChanged = oldWidget.imageUrl != widget.imageUrl;
    if ((emojiChanged || photoChanged) && widget.animate) {
      setState(() => _visible = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _visible = true);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final style = widget.category != null
        ? KsvlCategoryStyle.of(widget.category!)
        : KsvlCategoryStyle.ofIndex(widget.styleIndex);

    final background = isDark
        ? Color.alphaBlend(
            style.accent.withValues(alpha: 0.22),
            k.surfaceSubtle,
          )
        : style.tint;

    Widget content;
    if (widget.hasPhoto) {
      content = ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Image.network(
          widget.imageUrl!,
          fit: widget.fit,
          gaplessPlayback: true,
          // Without this the browser paints the JPEG progressively and the
          // customer watches a half-decoded smear resolve into a product.
          // Hold the tinted tile until the bytes are in, then cross-fade.
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: KsvlMotion.normal,
              curve: KsvlMotion.standard,
              child: child,
            );
          },
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return _fallback(style.accent);
          },
          errorBuilder: (_, _, _) => _fallback(style.accent),
        ),
      );
    } else {
      content = _fallback(style.accent);
    }

    Widget tile = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: KsvlMotion.normal,
        curve: KsvlMotion.standard,
        child: AnimatedScale(
          scale: _visible ? 1 : 0.92,
          duration: KsvlMotion.normal,
          curve: KsvlMotion.standard,
          child: content,
        ),
      ),
    );

    if (widget.size != null) {
      tile = SizedBox.square(dimension: widget.size, child: tile);
    }
    return tile;
  }

  /// What fills the tile when there is no photo, the photo is still arriving,
  /// or it failed.
  ///
  /// A product whose emoji was never filled in used to leave a blank coloured
  /// rectangle, which reads as a broken image rather than as a product. Falling
  /// back to a basket glyph in the category accent keeps the tile looking
  /// deliberate whatever the shop has entered.
  Widget _fallback(Color accent) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded =
            constraints.hasBoundedHeight && constraints.hasBoundedWidth;
        final shortest = bounded
            ? (constraints.maxHeight < constraints.maxWidth
                ? constraints.maxHeight
                : constraints.maxWidth)
            : (widget.size ?? 64);
        final glyph = widget.glyphSize ?? (shortest * 0.44);

        if (widget.emoji.trim().isEmpty) {
          return Center(
            child: Icon(
              Icons.shopping_basket_outlined,
              size: glyph * 0.86,
              color: accent.withValues(alpha: 0.55),
            ),
          );
        }
        return Center(
          child: _EmojiGlyph(emoji: widget.emoji, glyphSize: glyph, size: null),
        );
      },
    );
  }
}

class _EmojiGlyph extends StatelessWidget {
  const _EmojiGlyph({
    required this.emoji,
    required this.glyphSize,
    required this.size,
  });

  final String emoji;
  final double? glyphSize;
  final double? size;

  @override
  Widget build(BuildContext context) {
    final child = Text(
      emoji,
      style: TextStyle(fontSize: glyphSize ?? 28, height: 1),
    );
    if (size != null) {
      return SizedBox.square(dimension: size, child: Center(child: child));
    }
    return child;
  }
}
