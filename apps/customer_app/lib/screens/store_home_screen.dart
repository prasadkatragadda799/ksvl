import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/cart_provider.dart';
import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';
import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/widgets/cart_bar.dart';
import 'package:customer_app/widgets/delivery_bar.dart';
import 'package:customer_app/widgets/dry_fruit_backdrop.dart';
import 'package:customer_app/widgets/location_sheet.dart';
import 'package:customer_app/widgets/promo_banner_rail.dart';
import 'package:customer_app/widgets/refine_sheet.dart';
import 'package:customer_app/widgets/store_product_card.dart';
import 'package:customer_app/widgets/trust_strip.dart';

/// The storefront.
///
/// Layout contract, top to bottom:
///
///  * a pinned identity block — mark, shop name, and the delivery answer as a
///    single line directly beneath it. Everything about "can I order here"
///    lives in that line: it is permanently visible because the header is
///    pinned, so an unserviceable location can no longer be scrolled past, and
///    it costs one text line instead of the full-width card it replaced;
///  * a pinned search row with a refine button, because search is how people
///    find one item in a shop this size;
///  * pinned category chips;
///  * the grid, closing with the shop's promises.
///
/// Behind all of it, [DryFruitBackdrop] paints and parallaxes independently of
/// the list — that is the whole reason the scroll view sits in a [Stack] on a
/// transparent [Scaffold] rather than owning the page colour itself.
class StoreHomeScreen extends StatefulWidget {
  const StoreHomeScreen({super.key});

  @override
  State<StoreHomeScreen> createState() => _StoreHomeScreenState();
}

class _StoreHomeScreenState extends State<StoreHomeScreen> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  final _scrollController = ScrollController();

  /// Scroll position, published to the backdrop only.
  ///
  /// A [ValueNotifier] rather than setState: the backdrop repaints on every
  /// scroll frame, and rebuilding the entire storefront at that rate to move
  /// some background shapes would be indefensible.
  final _scrollOffset = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_publishOffset);
  }

  void _publishOffset() {
    if (_scrollController.hasClients) {
      _scrollOffset.value = _scrollController.position.pixels;
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_publishOffset)
      ..dispose();
    _scrollOffset.dispose();
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _clearSearch(CatalogProvider catalog) {
    _searchController.clear();
    catalog.setSearchQuery('');
    _searchFocus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final account = context.watch<UserAccountProvider>();
    final cartQuantity = context.select<CartProvider, int>(
      (c) => c.totalQuantity,
    );
    final k = KsvlColors.of(context);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final width = MediaQuery.sizeOf(context).width;
    final columns = KsvlBreakpoint.productColumns(width);
    final imageHeight = width >= KsvlBreakpoint.tablet ? 148.0 : 124.0;
    final loading = catalog.isLoading;
    final products = catalog.products;
    final showBanners =
        catalog.banners.isNotEmpty && !catalog.hasActiveFilters && !loading;

    // Keep the search box in sync when a filter is cleared from elsewhere.
    if (catalog.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: catalog.searchQuery,
        selection: TextSelection.collapsed(offset: catalog.searchQuery.length),
      );
    }

    // Cart dock is overlaid (not Scaffold.bottomNavigationBar) so floating
    // SnackBars still have room on short / web viewports.
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: DryFruitBackdrop(
              scrollOffset: _scrollOffset,
              seedCount: width >= KsvlBreakpoint.tablet ? 26 : 16,
            ),
          ),
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                pinned: true,
                titleSpacing: KsvlSpace.lg,
                backgroundColor: scheme.surface,
                toolbarHeight: 60,
                title: KsvlPageWidth(
                  child: Row(
                    children: [
                      const _BrandMark(),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              catalog.storeName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleMedium,
                            ),
                            const SizedBox(height: 3),
                            // The delivery answer, folded into the header. It
                            // used to be a full-width card below the search
                            // row; on a phone that band cost more vertical
                            // space than the first row of products.
                            Align(
                              alignment: Alignment.centerLeft,
                              child: DeliveryPill(
                                headline: catalog.deliveryHeadline,
                                detail: catalog.deliveryDetail,
                                blocker: catalog.blocker,
                                onTap: catalog.blocker ==
                                        StorefrontBlocker.storeClosed
                                    ? null
                                    : () => showLocationSheet(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: KsvlSpace.md),
                      _AccountButton(
                        loggedIn: account.isLoggedIn,
                        initials: account.initials,
                        onTap: () => context
                            .read<ShellProvider>()
                            .go(ShellTab.profile),
                      ),
                    ],
                  ),
                ),
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(60),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KsvlSpace.lg,
                      0,
                      KsvlSpace.lg,
                      KsvlSpace.md,
                    ),
                    child: KsvlPageWidth(
                      maxWidth: _searchMaxWidth,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              focusNode: _searchFocus,
                              onChanged: catalog.setSearchQuery,
                              textInputAction: TextInputAction.search,
                              decoration: InputDecoration(
                                hintText:
                                    'Search cashews, chilli powder, dates…',
                                prefixIcon:
                                    const Icon(Icons.search_rounded, size: 21),
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: KsvlSpace.lg,
                                  vertical: KsvlSpace.md,
                                ),
                                suffixIcon: catalog.searchQuery.isEmpty
                                    ? null
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          size: 19,
                                        ),
                                        tooltip: 'Clear search',
                                        onPressed: () => _clearSearch(catalog),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: KsvlSpace.sm),
                          _RefineButton(
                            activeCount: catalog.activeRefinementCount,
                            onTap: () => showRefineSheet(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              if (showBanners) ...[
                const SliverToBoxAdapter(child: SizedBox(height: KsvlSpace.lg)),
                SliverToBoxAdapter(
                  child: KsvlPageWidth(
                    child: PromoBannerRail(banners: catalog.banners),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: KsvlSpace.md)),

              SliverPersistentHeader(
                pinned: true,
                delegate: _StickyBar(
                  height: 56,
                  child: ColoredBox(
                    color: scheme.surface,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KsvlPageWidth(
                          child: loading
                              ? const _CategoryChipsSkeleton()
                              : KsvlFilterChips.categories(
                                  categories: catalog.categories,
                                  selectedId: catalog.selectedCategoryId,
                                  onSelected: catalog.setCategory,
                                  counts: catalog.categoryCounts,
                                ),
                        ),
                        Divider(height: 1, color: k.border),
                      ],
                    ),
                  ),
                ),
              ),

              SliverToBoxAdapter(
                child: KsvlPageWidth(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      KsvlSpace.md,
                    ),
                    child: loading
                        ? const _SectionHeaderSkeleton()
                        : KsvlSectionHeader(
                            title: _sectionTitle(catalog),
                            caption: _sectionCaption(catalog, products.length),
                            trailing: _SortControl(
                              sort: catalog.sort,
                              onSelected: catalog.setSort,
                            ),
                          ),
                  ),
                ),
              ),

              if (loading)
                _ProductGridSliver(
                  columns: columns,
                  imageHeight: imageHeight,
                  itemCount: columns * 2,
                  builder: (_, _) =>
                      StoreProductCardSkeleton(imageHeight: imageHeight),
                )
              else if (products.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: catalog.hasActiveFilters
                      ? KsvlEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'Nothing matched that',
                          message: 'Try a different spelling, or browse '
                              'another category.',
                          actionLabel: 'Show everything',
                          onAction: () {
                            _searchController.clear();
                            catalog.clearFilters();
                          },
                        )
                      : const KsvlEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'The shelves are being stocked',
                          message: 'There is nothing listed just yet. Check '
                              'back in a little while.',
                        ),
                )
              else ...[
                _ProductGridSliver(
                  columns: columns,
                  imageHeight: imageHeight,
                  itemCount: products.length,
                  builder: (context, index) => StoreProductCard(
                    key: ValueKey(products[index].id),
                    product: products[index],
                    imageHeight: imageHeight,
                  ),
                ),
                if (catalog.hasActiveFilters)
                  SliverToBoxAdapter(
                    child: KsvlPageWidth(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: KsvlSpace.lg,
                        ),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () {
                              _searchController.clear();
                              catalog.clearFilters();
                            },
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Clear filters'),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: KsvlPageWidth(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        KsvlSpace.lg,
                        KsvlSpace.md,
                        KsvlSpace.lg,
                        // Clear the floating cart dock when it is out.
                        cartQuantity > 0 ? 128 : KsvlSpace.xxl,
                      ),
                      child: const TrustStrip(),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CartBar(),
          ),
        ],
      ),
    );
  }

  /// A search field the full 1180px of the content column is a ribbon, not an
  /// input. Reading a query back is easier when the line is short.
  static const double _searchMaxWidth = 720;

  static String _sectionTitle(CatalogProvider catalog) {
    if (catalog.searchQuery.trim().isNotEmpty) return 'Search results';
    final id = catalog.selectedCategoryId;
    if (id == null) return 'All products';
    return AppCatalog.instance.categoryById(id)?.name ?? 'Category';
  }

  static String _sectionCaption(CatalogProvider catalog, int shown) {
    final total = catalog.totalProductCount;
    if (!catalog.hasActiveFilters) {
      return total == 1 ? '1 item' : '$total items';
    }
    return '$shown of $total items';
  }
}

/// Grid geometry lives in one place so the skeleton and the real grid cannot
/// drift apart — a skeleton that reflows on load is worse than none.
class _ProductGridSliver extends StatelessWidget {
  const _ProductGridSliver({
    required this.columns,
    required this.imageHeight,
    required this.itemCount,
    required this.builder,
  });

  final int columns;
  final double imageHeight;
  final int itemCount;
  final NullableIndexedWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return KsvlSliverPageWidth(
      sliver: SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.lg),
        sliver: SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: KsvlSpace.md,
            crossAxisSpacing: KsvlSpace.md,
            mainAxisExtent: StoreProductCard.extentFor(imageHeight),
          ),
          itemCount: itemCount,
          itemBuilder: builder,
        ),
      ),
    );
  }
}

/// Opens sort and filtering. The dot is the only way to tell, from the grid,
/// that something is being hidden on purpose.
class _RefineButton extends StatelessWidget {
  const _RefineButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final active = activeCount > 0;

    return Tooltip(
      message: active ? '$activeCount filters applied' : 'Sort & filter',
      child: Material(
        color: active ? k.brand : Theme.of(context).colorScheme.surface,
        borderRadius: KsvlRadius.allSm,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Ink(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              borderRadius: KsvlRadius.allSm,
              border: Border.all(color: active ? k.brand : k.border),
            ),
            child: Icon(
              Icons.tune_rounded,
              size: 20,
              color: active ? Colors.white : k.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

/// Reordering the shelf, from the section header.
class _SortControl extends StatelessWidget {
  const _SortControl({required this.sort, required this.onSelected});

  final ProductSort sort;
  final ValueChanged<ProductSort> onSelected;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final active = sort != ProductSort.recommended;

    return PopupMenuButton<ProductSort>(
      initialValue: sort,
      onSelected: onSelected,
      tooltip: 'Sort products',
      position: PopupMenuPosition.under,
      itemBuilder: (context) => [
        for (final option in ProductSort.values)
          PopupMenuItem<ProductSort>(
            value: option,
            child: Row(
              children: [
                Icon(option.icon, size: 17, color: k.textMuted),
                const SizedBox(width: KsvlSpace.md),
                Text(option.label),
              ],
            ),
          ),
      ],
      child: Container(
        padding: const EdgeInsets.fromLTRB(KsvlSpace.md, 7, KsvlSpace.sm, 7),
        decoration: BoxDecoration(
          color: active ? k.brandSoft : Colors.transparent,
          borderRadius: KsvlRadius.allPill,
          border: Border.all(color: active ? k.brand : k.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              sort.shortLabel,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.2,
                fontWeight: FontWeight.w700,
                color: active ? k.onBrandSoft : k.textSecondary,
              ),
            ),
            const SizedBox(width: 2),
            Icon(
              Icons.expand_more_rounded,
              size: 17,
              color: active ? k.onBrandSoft : k.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        borderRadius: KsvlRadius.allSm,
        boxShadow: [
          BoxShadow(
            color: KsvlPalette.brand500.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: KsvlRadius.allSm,
        child: Image.asset(
          'assets/logo.png',
          width: 38,
          height: 38,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}

class _CategoryChipsSkeleton extends StatelessWidget {
  const _CategoryChipsSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: KsvlSpace.lg),
        children: const [
          KsvlSkeleton(width: 68, height: 34, radius: KsvlRadius.pill),
          SizedBox(width: KsvlSpace.sm),
          KsvlSkeleton(width: 96, height: 34, radius: KsvlRadius.pill),
          SizedBox(width: KsvlSpace.sm),
          KsvlSkeleton(width: 84, height: 34, radius: KsvlRadius.pill),
          SizedBox(width: KsvlSpace.sm),
          KsvlSkeleton(width: 104, height: 34, radius: KsvlRadius.pill),
        ],
      ),
    );
  }
}

class _SectionHeaderSkeleton extends StatelessWidget {
  const _SectionHeaderSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        KsvlSkeleton(width: 132, height: 18),
        SizedBox(height: KsvlSpace.sm),
        KsvlSkeleton(width: 74, height: 12),
      ],
    );
  }
}

/// Pins the category bar under the app bar while the grid scrolls past.
class _StickyBar extends SliverPersistentHeaderDelegate {
  const _StickyBar({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return SizedBox(height: height, child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyBar oldDelegate) =>
      oldDelegate.child != child || oldDelegate.height != height;
}

class _AccountButton extends StatelessWidget {
  const _AccountButton({
    required this.loggedIn,
    required this.initials,
    required this.onTap,
  });

  final bool loggedIn;
  final String initials;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    return Tooltip(
      message: loggedIn ? 'My account' : 'Sign in',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: loggedIn ? k.brandSoft : k.surfaceSubtle,
              border: Border.all(color: loggedIn ? k.brand : k.border),
            ),
            child: loggedIn
                ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: k.onBrandSoft,
                      ),
                    ),
                  )
                : Icon(
                    Icons.person_outline_rounded,
                    size: 20,
                    color: k.textSecondary,
                  ),
          ),
        ),
      ),
    );
  }
}
