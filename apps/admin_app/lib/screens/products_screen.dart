import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';
import '../widgets/product_card.dart';
import 'categories_screen.dart';
import 'product_form_screen.dart';

/// Catalogue management: search, filter, toggle stock, edit pricing.
class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final products = provider.filteredProducts;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          IconButton(
            tooltip: 'Manage categories',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const CategoriesScreen(),
              ),
            ),
            icon: const Icon(Icons.category_outlined),
          ),
          Padding(
            padding: const EdgeInsets.only(right: KsvlSpace.lg),
            child: Center(
              child: Text(
                '${provider.products.length} total',
                style: text.bodySmall,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add product'),
      ),
      body: Column(
        children: [
          // Search and filters sit in a fixed header so they stay reachable
          // however far down the catalogue the user has scrolled.
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(bottom: BorderSide(color: k.border)),
            ),
            padding: const EdgeInsets.only(bottom: KsvlSpace.md),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    KsvlSpace.lg,
                    0,
                    KsvlSpace.lg,
                    KsvlSpace.md,
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: provider.setSearchQuery,
                    textInputAction: TextInputAction.search,
                    decoration: InputDecoration(
                      hintText: 'Search products or categories',
                      prefixIcon: const Icon(Icons.search_rounded, size: 21),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: KsvlSpace.lg,
                        vertical: KsvlSpace.md,
                      ),
                      suffixIcon: provider.searchQuery.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.close_rounded, size: 19),
                              tooltip: 'Clear search',
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                                FocusScope.of(context).unfocus();
                              },
                            ),
                    ),
                  ),
                ),
                KsvlFilterChips.categories(
                  categories: provider.categories,
                  selectedId: provider.selectedCategoryId,
                  onSelected: provider.setCategoryFilter,
                  counts: provider.categoryCounts,
                ),
              ],
            ),
          ),
          Expanded(
            child: products.isEmpty
                ? KsvlEmptyState(
                    icon: provider.hasActiveFilters
                        ? Icons.search_off_rounded
                        : Icons.inventory_2_outlined,
                    title: provider.hasActiveFilters
                        ? 'No matching products'
                        : 'Your catalogue is empty',
                    message: provider.hasActiveFilters
                        ? 'Try a different search term or category.'
                        : 'Add your first product to start selling.',
                    actionLabel:
                        provider.hasActiveFilters ? 'Clear filters' : null,
                    onAction: provider.hasActiveFilters
                        ? () {
                            _searchController.clear();
                            provider.clearFilters();
                          }
                        : null,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      KsvlSpace.lg,
                      96,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        onToggleProduct: (value) {
                          provider.toggleProductAvailability(
                            product.id,
                            value,
                          );
                          ScaffoldMessenger.of(context)
                            ..hideCurrentSnackBar()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '${product.name} is back in stock'
                                      : '${product.name} hidden from store',
                                ),
                              ),
                            );
                        },
                        onToggleVariant: (variantId, value) =>
                            provider.toggleVariantAvailability(
                          product.id,
                          variantId,
                          value,
                        ),
                        onEditVariant: (variant) =>
                            _showVariantQuickEdit(context, product, variant),
                        onEditProduct: () =>
                            _openForm(context, product: product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm(BuildContext context, {Product? product}) {
    return Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductFormScreen(product: product)),
    );
  }

  Future<void> _showVariantQuickEdit(
    BuildContext context,
    Product product,
    ProductVariant variant,
  ) {
    return showKsvlSheet<void>(
      context,
      builder: (_) => _VariantQuickEditSheet(
        product: product,
        variant: variant,
      ),
    );
  }
}

/// Change one variant's pricing without opening the full product form — the
/// single most frequent edit a shop makes.
class _VariantQuickEditSheet extends StatefulWidget {
  const _VariantQuickEditSheet({required this.product, required this.variant});

  final Product product;
  final ProductVariant variant;

  @override
  State<_VariantQuickEditSheet> createState() => _VariantQuickEditSheetState();
}

class _VariantQuickEditSheetState extends State<_VariantQuickEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _regular = TextEditingController(
    text: widget.variant.regularPrice.toStringAsFixed(0),
  );
  late final TextEditingController _special = TextEditingController(
    text: widget.variant.specialPrice.toStringAsFixed(0),
  );

  @override
  void dispose() {
    _regular.dispose();
    _special.dispose();
    super.dispose();
  }

  int get _discount {
    final regular = double.tryParse(_regular.text.trim()) ?? 0;
    final special = double.tryParse(_special.text.trim()) ?? 0;
    return discountPercent(regular, special);
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: 'Quick price edit',
      subtitle: '${widget.product.name} · ${widget.variant.title}',
      leading: KsvlProductThumb(
        emoji: widget.product.imageEmoji,
        imageUrl: widget.product.imageUrl,
        styleIndex: widget.product.categoryStyleIndex,
        size: 44,
        glyphSize: 22,
        animate: false,
      ),
      footer: ElevatedButton(
        onPressed: _save,
        child: const Text('Save prices'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regular,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Regular price',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Enter a price';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: TextFormField(
                    controller: _special,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Selling price',
                      prefixText: '₹ ',
                    ),
                    validator: (v) {
                      final special = double.tryParse(v?.trim() ?? '');
                      final regular = double.tryParse(_regular.text.trim());
                      if (special == null || special <= 0) {
                        return 'Enter a price';
                      }
                      if (regular != null && special > regular) {
                        return 'Above regular price';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: KsvlSpace.lg),
            Container(
              padding: const EdgeInsets.all(KsvlSpace.md),
              decoration: BoxDecoration(
                color: _discount > 0 ? k.successSoft : k.surfaceSubtle,
                borderRadius: KsvlRadius.allSm,
                border: Border.all(
                  color: _discount > 0
                      ? k.success.withValues(alpha: 0.22)
                      : k.border,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _discount > 0
                        ? Icons.sell_outlined
                        : Icons.info_outline_rounded,
                    size: 18,
                    color: _discount > 0 ? k.success : k.textMuted,
                  ),
                  const SizedBox(width: KsvlSpace.sm),
                  Expanded(
                    child: Text(
                      _discount > 0
                          ? 'Customers see $_discount% off this variant'
                          : 'No discount shown at these prices',
                      style: text.labelMedium?.copyWith(
                        color: _discount > 0 ? k.success : k.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    context.read<ProductProvider>().updateVariantPrices(
          productId: widget.product.id,
          variantId: widget.variant.id,
          regularPrice: double.parse(_regular.text.trim()),
          specialPrice: double.parse(_special.text.trim()),
        );
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('${widget.variant.title} pricing updated'),
        ),
      );
  }
}
