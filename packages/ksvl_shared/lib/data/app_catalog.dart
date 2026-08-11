import 'dart:async';

import 'package:flutter/foundation.dart';

import 'firestore/banner_repository.dart';
import 'firestore/category_repository.dart';
import 'firestore/product_repository.dart';
import 'firestore/store_config_repository.dart';
import '../models/banner_item.dart';
import '../models/catalog_category.dart';
import '../models/delivery_settings.dart';
import '../models/product.dart';
import '../models/store_location.dart';

/// Firestore-backed catalogue shared by admin + customer. Both apps read
/// (and admin writes) through this single in-memory cache, which stays in
/// sync with Firestore via live snapshot listeners.
class AppCatalog extends ChangeNotifier {
  AppCatalog._() {
    _categorySub = CategoryRepository.instance.watchAll().listen((v) {
      _categories = v;
      _categoriesLoaded = true;
      notifyListeners();
    });
    _productSub = ProductRepository.instance.watchAll().listen((v) {
      _products = v;
      _productsLoaded = true;
      notifyListeners();
    });
    _bannerSub = BannerRepository.instance.watchAll().listen((v) {
      _banners = v;
      notifyListeners();
    });
    _configSub = StoreConfigRepository.instance.watch().listen((v) {
      _config = v;
      notifyListeners();
    });
  }

  static final AppCatalog instance = AppCatalog._();

  late final StreamSubscription<List<CatalogCategory>> _categorySub;
  late final StreamSubscription<List<Product>> _productSub;
  late final StreamSubscription<List<BannerItem>> _bannerSub;
  late final StreamSubscription<StoreConfig> _configSub;

  List<CatalogCategory> _categories = const [];
  List<Product> _products = const [];
  List<BannerItem> _banners = const [];
  StoreConfig _config = StoreConfig.fallback;

  bool _categoriesLoaded = false;
  bool _productsLoaded = false;

  /// True until the first products *and* categories snapshot has arrived.
  ///
  /// Without this an empty `products` list is ambiguous — it means both "the
  /// stream has not answered yet" and "this shop genuinely sells nothing" —
  /// and the storefront ends up showing a no-results message during a perfectly
  /// normal cold start. Surfaces should render skeletons while this is true.
  bool get isLoading => !_productsLoaded || !_categoriesLoaded;

  List<CatalogCategory> get categories => List.unmodifiable(_categories);
  List<CatalogCategory> get activeCategories =>
      _categories.where((c) => c.isActive).toList(growable: false);
  List<Product> get products => List.unmodifiable(_products);
  List<BannerItem> get banners => List.unmodifiable(_banners);
  StoreLocation get storeLocation => _config.location;
  bool get isStoreOpen => _config.isStoreOpen;
  String get storeName => _config.storeName;
  DeliverySettings get deliverySettings => _config.deliverySettings;
  String get upiId => _config.upiId;

  List<Product> get featuredProducts =>
      _products.where((p) => p.isFeatured && p.isAvailable).toList();

  CatalogCategory? categoryById(String id) {
    for (final c in _categories) {
      if (c.id == id) return c;
    }
    return null;
  }

  void setStoreOpen(bool value) {
    StoreConfigRepository.instance.save(_config.copyWith(isStoreOpen: value));
  }

  void setStoreLocation(StoreLocation location) {
    StoreConfigRepository.instance.save(_config.copyWith(location: location));
  }

  void setDeliverySettings(DeliverySettings settings) {
    StoreConfigRepository.instance
        .save(_config.copyWith(deliverySettings: settings));
  }

  void setUpiId(String upiId) {
    StoreConfigRepository.instance.save(_config.copyWith(upiId: upiId));
  }

  void upsertCategory(CatalogCategory category) {
    final previous = categoryById(category.id);
    CategoryRepository.instance.upsert(category);
    // Keep product labels/styles in sync when admin renames a category.
    if (previous != null &&
        (previous.name != category.name ||
            previous.styleIndex != category.styleIndex)) {
      for (final p in _products) {
        if (p.categoryId != category.id) continue;
        ProductRepository.instance.upsert(p.copyWith(
          categoryLabel: category.name,
          categoryStyleIndex: category.styleIndex,
        ));
      }
    }
  }

  /// Soft-delete: deactivate so the storefront drops it immediately.
  /// Products keep their denormalized label.
  Future<bool> deactivateCategory(String id) async {
    if (_categories.length <= 1) return false;
    final category = categoryById(id);
    if (category == null) return false;
    await CategoryRepository.instance.upsert(category.copyWith(isActive: false));
    return true;
  }

  Future<bool> deleteCategory(String id) async {
    if (_categories.length <= 1) return false;
    final inUse = _products.any((p) => p.categoryId == id);
    if (inUse) {
      return deactivateCategory(id);
    }
    await CategoryRepository.instance.delete(id);
    return true;
  }

  void upsertProduct(Product product) {
    ProductRepository.instance.upsert(product);
  }

  void deleteProduct(String id) {
    ProductRepository.instance.delete(id);
  }

  void upsertBanner(BannerItem banner) {
    BannerRepository.instance.upsert(banner);
  }

  void deleteBanner(String id) {
    BannerRepository.instance.delete(id);
  }

  @override
  void dispose() {
    _categorySub.cancel();
    _productSub.cancel();
    _bannerSub.cancel();
    _configSub.cancel();
    super.dispose();
  }
}
