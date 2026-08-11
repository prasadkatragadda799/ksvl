import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// Promo banner tile in the dashboard rail.
///
/// An inactive banner is drawn in neutrals rather than the brand gradient, so
/// "this is not live right now" is legible from across the room instead of
/// depending on reading a small badge.
class BannerCard extends StatelessWidget {
  const BannerCard({
    super.key,
    required this.banner,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleActive,
  });

  final BannerItem banner;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleActive;

  static const double width = 248;
  static const double height = 220;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final active = banner.isActive;

    return SizedBox(
      width: width,
      height: height,
      child: KsvlCard(
        padding: EdgeInsets.zero,
        onTap: onEdit,
        semanticLabel: 'Banner ${banner.title}, '
            '${active ? 'active' : 'inactive'}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Media(banner: banner, active: active),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  KsvlSpace.md,
                  KsvlSpace.sm,
                  KsvlSpace.xs,
                  KsvlSpace.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      banner.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        height: 1.2,
                        color: active ? k.textPrimary : k.textMuted,
                      ),
                    ),
                    if (banner.subtitle.isNotEmpty)
                      Text(
                        banner.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(height: 1.2),
                      ),
                    const Spacer(flex: 1),
                    Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 14,
                          color: k.textMuted,
                        ),
                        const SizedBox(width: KsvlSpace.xs),
                        Expanded(
                          child: Text(
                            banner.linkType == BannerLinkType.category
                                ? (AppCatalog.instance
                                        .categoryById(banner.categoryId ?? '')
                                        ?.name ??
                                    'Category')
                                : banner.linkType.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.labelSmall?.copyWith(
                              height: 1.1,
                              letterSpacing: 0.1,
                              color: k.textMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Transform.scale(
                          scale: 0.78,
                          alignment: Alignment.centerLeft,
                          child: Switch(
                            value: active,
                            onChanged: onToggleActive,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit banner',
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                        IconButton(
                          onPressed: onDelete,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          tooltip: 'Delete banner',
                          color: k.danger,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 36,
                            minHeight: 36,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Media extends StatelessWidget {
  const _Media({required this.banner, required this.active});

  final BannerItem banner;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return SizedBox(
      height: 100,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: active
                ? k.brandGradient
                : [k.surfaceSubtle, k.borderStrong],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (banner.hasImage)
              Opacity(
                opacity: active ? 1 : 0.5,
                child: Image.network(banner.imageUrl!, fit: BoxFit.cover),
              )
            else ...[
              Positioned(
                right: -18,
                bottom: -22,
                child: Opacity(
                  opacity: active ? 0.20 : 0.14,
                  child: Text(
                    banner.imageEmoji,
                    style: const TextStyle(fontSize: 96, height: 1),
                  ),
                ),
              ),
              Center(
                child: Opacity(
                  opacity: active ? 1 : 0.55,
                  child: Text(
                    banner.imageEmoji,
                    style: const TextStyle(fontSize: 40, height: 1),
                  ),
                ),
              ),
            ],
            Positioned(
              top: KsvlSpace.sm,
              left: KsvlSpace.sm,
              child: KsvlBadge(
                label: active ? 'Live' : 'Hidden',
                tone: active ? KsvlTone.success : KsvlTone.neutral,
                icon: active
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                dense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
