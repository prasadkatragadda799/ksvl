import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';

/// Swipeable promo banners with a page indicator.
///
/// These are the banners the shop creates in the admin app. Until now the
/// storefront never rendered them, so every banner the manager made went
/// nowhere; tapping one applies its category redirect.
class PromoBannerRail extends StatefulWidget {
  const PromoBannerRail({super.key, required this.banners});

  final List<BannerItem> banners;

  @override
  State<PromoBannerRail> createState() => _PromoBannerRailState();
}

class _PromoBannerRailState extends State<PromoBannerRail> {
  late final PageController _controller;
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88)
      ..addListener(() {
        final page = _controller.page ?? 0;
        if (page != _page) setState(() => _page = page);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    final width = MediaQuery.sizeOf(context).width;
    final single = widget.banners.length == 1;
    final height = width >= KsvlBreakpoint.tablet ? 168.0 : 132.0;

    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            padEnds: !single,
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: KsvlSpace.sm,
                ),
                child: _BannerTile(banner: widget.banners[index]),
              );
            },
          ),
        ),
        if (!single) ...[
          const SizedBox(height: KsvlSpace.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.banners.length; i++)
                AnimatedContainer(
                  duration: KsvlMotion.fast,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  // The active dot stretches instead of just recolouring, so
                  // position is readable even at a glance.
                  width: (_page.round() == i) ? 20 : 6,
                  decoration: BoxDecoration(
                    color: (_page.round() == i) ? k.brand : k.borderStrong,
                    borderRadius: KsvlRadius.allPill,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _BannerTile extends StatelessWidget {
  const _BannerTile({required this.banner});

  final BannerItem banner;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: KsvlRadius.allLg,
        onTap: () {
          context.read<CatalogProvider>().applyBanner(banner);
        },
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: KsvlRadius.allLg,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: k.brandGradient,
            ),
            boxShadow: KsvlShadow.sm,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (banner.hasImage)
                ClipRRect(
                  borderRadius: KsvlRadius.allLg,
                  child: Image.network(
                    banner.imageUrl!,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                  ),
                )
              else
                Positioned(
                  right: -12,
                  bottom: -28,
                  child: Opacity(
                    opacity: 0.22,
                    child: Text(
                      banner.imageEmoji,
                      style: const TextStyle(fontSize: 132, height: 1),
                    ),
                  ),
                ),
              // Scrim keeps text legible over uploaded artwork.
              if (banner.hasImage)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: KsvlRadius.allLg,
                      gradient: LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.15),
                        ],
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(KsvlSpace.xl),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (banner.subtitle.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KsvlSpace.sm,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: KsvlRadius.allPill,
                        ),
                        child: Text(
                          banner.subtitle,
                          style: text.labelSmall?.copyWith(
                            color: Colors.white,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ),
                      const SizedBox(height: KsvlSpace.sm),
                    ],
                    Text(
                      banner.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.headlineSmall?.copyWith(color: Colors.white),
                    ),
                    const SizedBox(height: KsvlSpace.md),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Shop now',
                          style: text.labelMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: KsvlSpace.xs),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
