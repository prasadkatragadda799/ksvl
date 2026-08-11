import 'package:flutter/foundation.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

class StoreProvider extends ChangeNotifier {
  StoreProvider() {
    AppCatalog.instance.addListener(_onCatalogChanged);
  }

  final AppCatalog _catalog = AppCatalog.instance;

  void _onCatalogChanged() => notifyListeners();

  @override
  void dispose() {
    _catalog.removeListener(_onCatalogChanged);
    super.dispose();
  }

  bool get isStoreOpen => _catalog.isStoreOpen;
  String get storeName => _catalog.storeName;
  StoreLocation get storeLocation => _catalog.storeLocation;
  DeliverySettings get deliverySettings => _catalog.deliverySettings;
  String get upiId => _catalog.upiId;
  List<BannerItem> get banners => _catalog.banners;
  List<BannerItem> get activeBanners =>
      banners.where((b) => b.isActive).toList();

  void toggleStoreOpen(bool value) => _catalog.setStoreOpen(value);

  void setStoreLocation(StoreLocation location) =>
      _catalog.setStoreLocation(location);

  void setDeliverySettings(DeliverySettings settings) =>
      _catalog.setDeliverySettings(settings);

  void setUpiId(String upiId) => _catalog.setUpiId(upiId);

  void addBanner(BannerItem banner) => _catalog.upsertBanner(banner);

  void updateBanner(BannerItem banner) => _catalog.upsertBanner(banner);

  void deleteBanner(String id) => _catalog.deleteBanner(id);

  void toggleBannerActive(String id, bool value) {
    BannerItem? banner;
    for (final b in banners) {
      if (b.id == id) {
        banner = b;
        break;
      }
    }
    if (banner == null) return;
    _catalog.upsertBanner(banner.copyWith(isActive: value));
  }
}
