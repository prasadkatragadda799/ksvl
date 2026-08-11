import 'package:flutter/foundation.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

class ProductProvider extends ChangeNotifier {
  ProductProvider() {
    AppCatalog.instance.addListener(_onCatalogChanged);
  }

  final AppCatalog _catalog = AppCatalog.instance;

  void _onCatalogChanged() => notifyListeners();

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    super.dispose();
  }

  List<Product> get products => _catalog.products;
  List<CatalogCategory> get categories => _catalog.categories;
  List<CatalogCategory> get activeCategories => _catalog.activeCategories;

  String _searchQuery = '';
  String? _selectedCategoryId;

  String get searchQuery => _searchQuery;
  String? get selectedCategoryId => _selectedCategoryId;

  int get outOfStockCount => products.where((p) => !p.isAvailable).length;

  int get featuredCount => products.where((p) => p.isFeatured).length;

  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final product in products) {
      counts[product.categoryId] = (counts[product.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  bool get hasActiveFilters =>
      _selectedCategoryId != null || _searchQuery.trim().isNotEmpty;

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    notifyListeners();
  }

  List<Product> get filteredProducts {
    return products.where((product) {
      final matchesCategory = _selectedCategoryId == null ||
          product.categoryId == _selectedCategoryId;
      final query = _searchQuery.trim().toLowerCase();
      final matchesSearch = query.isEmpty ||
          product.name.toLowerCase().contains(query) ||
          product.categoryLabel.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setCategoryFilter(String? categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void toggleProductAvailability(String productId, bool value) {
    final product = getById(productId);
    if (product == null) return;
    final updatedVariants = product.variants
        .map((v) => v.copyWith(isAvailable: value))
        .toList();
    _catalog.upsertProduct(
      product.copyWith(isAvailable: value, variants: updatedVariants),
    );
  }

  void toggleFeatured(String productId, bool value) {
    final product = getById(productId);
    if (product == null) return;
    _catalog.upsertProduct(product.copyWith(isFeatured: value));
  }

  void toggleVariantAvailability(
    String productId,
    String variantId,
    bool value,
  ) {
    final product = getById(productId);
    if (product == null) return;
    final variants = product.variants.map((v) {
      if (v.id != variantId) return v;
      return v.copyWith(isAvailable: value);
    }).toList();
    final anyAvailable = variants.any((v) => v.isAvailable);
    _catalog.upsertProduct(
      product.copyWith(variants: variants, isAvailable: anyAvailable),
    );
  }

  void updateVariantPrices({
    required String productId,
    required String variantId,
    required double regularPrice,
    required double specialPrice,
  }) {
    final product = getById(productId);
    if (product == null) return;
    final variants = product.variants.map((v) {
      if (v.id != variantId) return v;
      return v.copyWith(
        regularPrice: regularPrice,
        specialPrice: specialPrice,
      );
    }).toList();
    _catalog.upsertProduct(product.copyWith(variants: variants));
  }

  void addProduct(Product product) => _catalog.upsertProduct(product);

  void updateProduct(Product product) => _catalog.upsertProduct(product);

  void deleteProduct(String id) => _catalog.deleteProduct(id);

  void upsertCategory(CatalogCategory category) =>
      _catalog.upsertCategory(category);

  Future<bool> deleteCategory(String id) => _catalog.deleteCategory(id);

  Product? getById(String id) {
    try {
      return products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
