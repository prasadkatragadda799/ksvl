import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

/// The single reason a customer cannot place an order, if there is one.
///
/// Kept as one value rather than a pile of booleans so every surface that has
/// to explain the situation — the header, the home notice, the product sheet,
/// the cart button — tells the customer the *same* story.
enum StorefrontBlocker { none, storeClosed, noLocation, outOfZone }

/// How the grid is ordered.
///
/// [recommended] is the shop's own order — featured first — and stays the
/// default, because a shopkeeper's shelf beats an alphabet.
enum ProductSort { recommended, priceLowHigh, priceHighLow, biggestSaving, nameAZ }

extension ProductSortLabel on ProductSort {
  String get label => switch (this) {
        ProductSort.recommended => 'Recommended',
        ProductSort.priceLowHigh => 'Price: low to high',
        ProductSort.priceHighLow => 'Price: high to low',
        ProductSort.biggestSaving => 'Biggest saving',
        ProductSort.nameAZ => 'Name: A to Z',
      };

  /// Fits the control in the section header, where "Price: low to high" would
  /// push the product count off the line.
  String get shortLabel => switch (this) {
        ProductSort.recommended => 'Sort',
        ProductSort.priceLowHigh => 'Price ↑',
        ProductSort.priceHighLow => 'Price ↓',
        ProductSort.biggestSaving => 'Saving',
        ProductSort.nameAZ => 'A–Z',
      };

  IconData get icon => switch (this) {
        ProductSort.recommended => Icons.auto_awesome_outlined,
        ProductSort.priceLowHigh => Icons.arrow_upward_rounded,
        ProductSort.priceHighLow => Icons.arrow_downward_rounded,
        ProductSort.biggestSaving => Icons.local_offer_outlined,
        ProductSort.nameAZ => Icons.sort_by_alpha_rounded,
      };
}

class CatalogProvider extends ChangeNotifier {
  CatalogProvider() {
    AppCatalog.instance.addListener(_onCatalogChanged);
  }

  final AppCatalog _catalog = AppCatalog.instance;

  void _onCatalogChanged() => notifyListeners();

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    super.dispose();
  }

  String? _selectedCategoryId;
  String _searchQuery = '';
  ProductSort _sort = ProductSort.recommended;
  bool _offersOnly = false;
  bool _inStockOnly = false;
  String _areaLabel = 'Near store';
  double? _customerLat;
  double? _customerLng;
  bool _serviceable = false;
  double? _distanceKm;

  DeliverySettings get deliverySettings => _catalog.deliverySettings;
  double get freeDeliveryThreshold =>
      _catalog.deliverySettings.freeDeliveryThreshold;
  double get deliveryFee => _catalog.deliverySettings.deliveryFee;
  String get upiId => _catalog.upiId;

  String get storeName => _catalog.storeName;
  StoreLocation get storeLocation => _catalog.storeLocation;
  bool get storeOpen => _catalog.isStoreOpen;
  String get areaLabel => _areaLabel;

  /// Can this customer order right now? Both the shutter and the map have to
  /// agree, which is why the two reasons below exist separately — the customer
  /// needs to be told *which* one is blocking them.
  bool get serviceable => _serviceable && _catalog.isStoreOpen;

  /// Location is set and inside the radius. Independent of opening hours.
  bool get inDeliveryZone => _serviceable;

  /// The shop is shut. Nothing the customer can do about it, so it must never
  /// be phrased as a location problem.
  bool get storeClosed => !_catalog.isStoreOpen;

  bool get isLoading => _catalog.isLoading;
  bool get hasLocation => _customerLat != null && _customerLng != null;
  double? get distanceKm => _distanceKm;
  String? get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  ProductSort get sort => _sort;
  bool get offersOnly => _offersOnly;
  bool get inStockOnly => _inStockOnly;

  /// Why the customer cannot check out, in the order they can act on it.
  StorefrontBlocker get blocker {
    if (storeClosed) return StorefrontBlocker.storeClosed;
    if (!hasLocation) return StorefrontBlocker.noLocation;
    if (!_serviceable) return StorefrontBlocker.outOfZone;
    return StorefrontBlocker.none;
  }

  List<CatalogCategory> get categories => _catalog.activeCategories;

  String get locationChipLabel {
    if (!hasLocation) return 'Set location';
    if (!_serviceable) {
      return 'Outside ${storeLocation.radiusKm.toStringAsFixed(0)} km';
    }
    final d = _distanceKm;
    if (d == null) return _areaLabel;
    return '${d.toStringAsFixed(1)} km away';
  }

  /// Headline for the delivery bar — where we are sending the order.
  String get deliveryHeadline =>
      hasLocation ? _areaLabel : 'Where should we deliver?';

  /// Supporting line for the delivery bar — the promise or the problem.
  String get deliveryDetail {
    final radius = storeLocation.radiusKm.toStringAsFixed(0);
    return switch (blocker) {
      StorefrontBlocker.storeClosed => 'Store is closed right now',
      StorefrontBlocker.noLocation => 'Tap to set your delivery address',
      StorefrontBlocker.outOfZone =>
        '${_distanceKm!.toStringAsFixed(1)} km away · we deliver within $radius km',
      StorefrontBlocker.none =>
        'Delivering here · ${_distanceKm!.toStringAsFixed(1)} km from the store',
    };
  }

  List<BannerItem> get banners =>
      _catalog.banners.where((b) => b.isActive).toList(growable: false);

  /// Anything that hides products from the customer.
  ///
  /// Sort is deliberately not in here: reordering a shelf is a view
  /// preference, and offering to "clear" it would imply items are missing.
  bool get hasActiveFilters =>
      _selectedCategoryId != null ||
      _searchQuery.trim().isNotEmpty ||
      _offersOnly ||
      _inStockOnly;

  /// How many of the sheet's toggles are on — drives the dot on the filter
  /// button so the customer can see, from the grid, that a filter is hiding
  /// things.
  int get activeRefinementCount =>
      (_selectedCategoryId != null ? 1 : 0) +
      (_offersOnly ? 1 : 0) +
      (_inStockOnly ? 1 : 0) +
      (_sort != ProductSort.recommended ? 1 : 0);

  int get totalProductCount => _catalog.products.length;

  List<Product> get featuredProducts => _catalog.featuredProducts;

  Map<String, int> get categoryCounts {
    final counts = <String, int>{};
    for (final product in _catalog.products) {
      counts[product.categoryId] = (counts[product.categoryId] ?? 0) + 1;
    }
    return counts;
  }

  List<Product> get products {
    final query = _searchQuery.trim().toLowerCase();
    final list = _catalog.products.where((p) {
      final matchesCategory =
          _selectedCategoryId == null || p.categoryId == _selectedCategoryId;
      final matchesQuery = query.isEmpty ||
          p.name.toLowerCase().contains(query) ||
          p.categoryLabel.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query);
      final matchesOffer = !_offersOnly || _discountOf(p) > 0;
      final matchesStock = !_inStockOnly || p.isAvailable;
      return matchesCategory && matchesQuery && matchesOffer && matchesStock;
    }).toList();

    list.sort((a, b) {
      // Whatever the sort, a product that cannot be bought sinks — offering an
      // out-of-stock item as the cheapest result is a wasted tap.
      if (a.isAvailable != b.isAvailable) return a.isAvailable ? -1 : 1;
      return switch (_sort) {
        ProductSort.recommended => a.isFeatured == b.isFeatured
            ? 0
            : (a.isFeatured ? -1 : 1),
        ProductSort.priceLowHigh => _priceOf(a).compareTo(_priceOf(b)),
        ProductSort.priceHighLow => _priceOf(b).compareTo(_priceOf(a)),
        ProductSort.biggestSaving => _discountOf(b).compareTo(_discountOf(a)),
        ProductSort.nameAZ =>
          a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      };
    });
    return list;
  }

  /// Cheapest sellable variant — the number the card actually shows, so the
  /// order the customer sees matches the order they were promised.
  static double _priceOf(Product product) {
    if (product.variants.isEmpty) return 0;
    var lowest = double.infinity;
    for (final v in product.variants) {
      if (v.specialPrice < lowest) lowest = v.specialPrice;
    }
    return lowest.isFinite ? lowest : 0;
  }

  static int _discountOf(Product product) {
    var best = 0;
    for (final v in product.variants) {
      final percent = discountPercent(v.regularPrice, v.specialPrice);
      if (percent > best) best = percent;
    }
    return best;
  }

  void setCategory(String? categoryId) {
    if (_selectedCategoryId == categoryId) return;
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    notifyListeners();
  }

  void setSort(ProductSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    notifyListeners();
  }

  void setOffersOnly(bool value) {
    if (_offersOnly == value) return;
    _offersOnly = value;
    notifyListeners();
  }

  void setInStockOnly(bool value) {
    if (_inStockOnly == value) return;
    _inStockOnly = value;
    notifyListeners();
  }

  void clearFilters() {
    _selectedCategoryId = null;
    _searchQuery = '';
    _offersOnly = false;
    _inStockOnly = false;
    notifyListeners();
  }

  /// Everything the refine sheet owns, including the sort — used by its own
  /// "Reset" action, where the customer does expect the order to go back too.
  void resetRefinements() {
    _selectedCategoryId = null;
    _offersOnly = false;
    _inStockOnly = false;
    _sort = ProductSort.recommended;
    notifyListeners();
  }

  void applyBanner(BannerItem banner) {
    _searchQuery = '';
    switch (banner.linkType) {
      case BannerLinkType.category:
        _selectedCategoryId = banner.categoryId;
      case BannerLinkType.offers:
      case BannerLinkType.home:
        _selectedCategoryId = null;
    }
    notifyListeners();
  }

  bool setCustomerLocation({
    required double latitude,
    required double longitude,
    String? label,
  }) {
    final store = storeLocation;
    final km = haversineKm(
      lat1: store.latitude,
      lon1: store.longitude,
      lat2: latitude,
      lon2: longitude,
    );
    _customerLat = latitude;
    _customerLng = longitude;
    _distanceKm = km;
    _serviceable = km <= store.radiusKm;
    _areaLabel = label?.trim().isNotEmpty == true
        ? label!.trim()
        : (_serviceable ? 'Inside delivery zone' : 'Outside delivery zone');
    notifyListeners();
    return _serviceable;
  }

  bool useStoreHubLocation() {
    final store = storeLocation;
    return setCustomerLocation(
      latitude: store.latitude,
      longitude: store.longitude,
      label: store.label,
    );
  }
}
