import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/store_provider.dart';
import '../widgets/banner_card.dart';
import '../widgets/order_card.dart';
import '../widgets/stats_card.dart';
import '../widgets/store_status_card.dart';
import 'delivery_settings_screen.dart';
import 'delivery_zone_screen.dart';
import 'payment_settings_screen.dart';

/// Opening screen: is the shop trading, what happened today, what is waiting.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onViewOrders,
    required this.onViewProducts,
  });

  /// Jumps to the orders tab, optionally pre-filtered to a status.
  final void Function(OrderStatus? status) onViewOrders;

  final VoidCallback onViewProducts;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<StoreProvider>();
    final orders = context.watch<OrderProvider>();
    final products = context.watch<ProductProvider>();
    final text = Theme.of(context).textTheme;
    final recent = orders.recentOrders(3);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            toolbarHeight: 68,
            backgroundColor: Theme.of(context).colorScheme.surface,
            title: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_greeting(), style: text.bodySmall),
                Text(store.storeName, style: text.titleLarge),
              ],
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              KsvlSpace.lg,
              KsvlSpace.md,
              KsvlSpace.lg,
              KsvlSpace.xxxl,
            ),
            sliver: SliverList.list(
              children: [
                StoreStatusCard(
                  isOpen: store.isStoreOpen,
                  onChanged: (value) {
                    store.toggleStoreOpen(value);
                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Store opened — customers can order'
                                : 'Store closed — new orders are paused',
                          ),
                        ),
                      );
                  },
                ),
                const SizedBox(height: KsvlSpace.md),
                KsvlCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeliveryZoneScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.radar_rounded,
                          color: KsvlColors.of(context).brand),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Delivery zone · ${store.storeLocation.radiusKm.toStringAsFixed(0)} km',
                              style: text.titleSmall,
                            ),
                            Text(
                              store.storeLocation.label,
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: KsvlSpace.md),
                KsvlCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const DeliverySettingsScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.local_shipping_outlined,
                          color: KsvlColors.of(context).brand),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Delivery fee & slots', style: text.titleSmall),
                            Text(
                              '₹${store.deliverySettings.deliveryFee.toStringAsFixed(0)} fee · '
                              'free over ₹${store.deliverySettings.freeDeliveryThreshold.toStringAsFixed(0)} · '
                              '${store.deliverySettings.slotOpenHour}:00–${store.deliverySettings.slotCloseHour}:00',
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: KsvlSpace.md),
                KsvlCard(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PaymentSettingsScreen(),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.qr_code_2_rounded,
                          color: KsvlColors.of(context).brand),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment settings', style: text.titleSmall),
                            Text(
                              store.upiId.isEmpty
                                  ? 'UPI not set up · COD only'
                                  : 'UPI: ${store.upiId}',
                              style: text.bodySmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                ),
                const SizedBox(height: KsvlSpace.xxl),
                const KsvlSectionHeader(
                  title: 'Today at a glance',
                  caption: 'Live figures for the current day',
                ),
                const SizedBox(height: KsvlSpace.md),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: KsvlSpace.md,
                  crossAxisSpacing: KsvlSpace.md,
                  childAspectRatio: 1.1,
                  children: [
                    StatsCard(
                      title: "Today's orders",
                      value: '${orders.todaysOrdersCount}',
                      icon: Icons.shopping_bag_outlined,
                      tone: KsvlTone.brand,
                      onTap: () => onViewOrders(null),
                    ),
                    StatsCard(
                      title: 'Pending orders',
                      value: '${orders.pendingOrdersCount}',
                      icon: Icons.schedule_rounded,
                      tone: orders.pendingOrdersCount > 0
                          ? KsvlTone.warning
                          : KsvlTone.neutral,
                      caption: orders.pendingOrdersCount > 0
                          ? 'Needs packing'
                          : 'All caught up',
                      onTap: () => onViewOrders(OrderStatus.pending),
                    ),
                    StatsCard(
                      title: 'Sales today',
                      value: formatRupee(orders.todaysSales),
                      icon: Icons.payments_outlined,
                      tone: KsvlTone.success,
                    ),
                    StatsCard(
                      title: 'Out of stock',
                      value: '${products.outOfStockCount}',
                      icon: Icons.inventory_2_outlined,
                      tone: products.outOfStockCount > 0
                          ? KsvlTone.danger
                          : KsvlTone.neutral,
                      caption: products.outOfStockCount > 0
                          ? 'Hidden from store'
                          : 'Everything listed',
                      onTap: onViewProducts,
                    ),
                  ],
                ),
                const SizedBox(height: KsvlSpace.xxl),
                KsvlSectionHeader(
                  title: 'Recent orders',
                  caption: recent.isEmpty
                      ? 'Nothing has come in yet'
                      : 'Latest ${recent.length} of ${orders.orders.length}',
                  actionLabel: 'View all',
                  onActionTap: () => onViewOrders(null),
                ),
                const SizedBox(height: KsvlSpace.md),
                if (recent.isEmpty)
                  KsvlCard(
                    child: const KsvlEmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'No orders yet',
                      message: 'New customer orders will appear here.',
                      compact: true,
                    ),
                  )
                else
                  for (final order in recent)
                    OrderCard(
                      order: order,
                      compact: true,
                      onTap: () => onViewOrders(order.status),
                    ),
                const SizedBox(height: KsvlSpace.xl),
                KsvlSectionHeader(
                  title: 'Promotional banners',
                  caption:
                      '${store.activeBanners.length} live of ${store.banners.length}',
                  trailing: TextButton.icon(
                    onPressed: () => _showBannerSheet(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add'),
                  ),
                ),
                const SizedBox(height: KsvlSpace.md),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(
              height: BannerCard.height,
              child: store.banners.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: KsvlSpace.lg,
                      ),
                      child: KsvlCard(
                        child: KsvlEmptyState(
                          icon: Icons.campaign_outlined,
                          title: 'No banners yet',
                          message: 'Promote a category on the storefront.',
                          compact: true,
                          actionLabel: 'Create banner',
                          onAction: () => _showBannerSheet(context),
                        ),
                      ),
                    )
                  : ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: KsvlSpace.lg,
                      ),
                      itemCount: store.banners.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: KsvlSpace.md),
                      itemBuilder: (context, index) {
                        final banner = store.banners[index];
                        return BannerCard(
                          banner: banner,
                          onEdit: () =>
                              _showBannerSheet(context, banner: banner),
                          onDelete: () => _confirmDelete(context, banner),
                          onToggleActive: (value) =>
                              store.toggleBannerActive(banner.id, value),
                        );
                      },
                    ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: KsvlSpace.xxxl)),
        ],
      ),
    );
  }

  static String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _confirmDelete(BuildContext context, BannerItem banner) async {
    final k = KsvlColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: k.danger, size: 28),
        title: const Text('Delete this banner?'),
        content: Text(
          '“${banner.title}” will be removed from the storefront '
          'immediately. This cannot be undone.',
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          KsvlSpace.lg,
          0,
          KsvlSpace.lg,
          KsvlSpace.lg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep it'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: k.danger),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      context.read<StoreProvider>().deleteBanner(banner.id);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Deleted “${banner.title}”')));
    }
  }

  Future<void> _showBannerSheet(
    BuildContext context, {
    BannerItem? banner,
  }) {
    return showKsvlSheet<void>(
      context,
      builder: (_) => BannerFormSheet(banner: banner),
    );
  }
}

/// Create / edit a promo banner.
class BannerFormSheet extends StatefulWidget {
  const BannerFormSheet({super.key, this.banner});

  final BannerItem? banner;

  @override
  State<BannerFormSheet> createState() => _BannerFormSheetState();
}

class _BannerFormSheetState extends State<BannerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late BannerLinkType _linkType;
  String? _categoryId;
  late bool _isActive;
  late String _emoji;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;
  bool _saving = false;

  static const _emojiOptions = [
    '🏷️',
    '🎁',
    '🥜',
    '🌶️',
    '🫐',
    '🍘',
    '🫙',
    '✨',
    '🔥',
  ];

  bool get _isEdit => widget.banner != null;
  bool get _hasImage => _pickedImageBytes != null || _existingImageUrl != null;

  @override
  void initState() {
    super.initState();
    final b = widget.banner;
    _titleController = TextEditingController(text: b?.title ?? '');
    _subtitleController = TextEditingController(text: b?.subtitle ?? '');
    _linkType = b?.linkType ?? BannerLinkType.offers;
    _categoryId = b?.categoryId;
    _isActive = b?.isActive ?? true;
    _emoji = b?.imageEmoji ?? _emojiOptions.first;
    _existingImageUrl = b?.imageUrl;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() => _pickedImageBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open camera/gallery. Check permissions.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlSheetScaffold(
      title: _isEdit ? 'Edit banner' : 'New banner',
      subtitle: 'Shown at the top of the customer storefront',
      footer: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_isEdit ? 'Save changes' : 'Create banner'),
            ),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Live preview — the fastest way to know what you are making.
            ClipRRect(
              borderRadius: KsvlRadius.allMd,
              child: SizedBox(
                height: 132,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (_pickedImageBytes != null)
                      Image.memory(_pickedImageBytes!, fit: BoxFit.cover)
                    else if (_existingImageUrl != null)
                      Image.network(_existingImageUrl!, fit: BoxFit.cover)
                    else
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: _isActive
                                ? k.brandGradient
                                : [k.surfaceSubtle, k.borderStrong],
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(right: KsvlSpace.lg),
                            child: Text(
                              _emoji,
                              style: const TextStyle(fontSize: 46),
                            ),
                          ),
                        ),
                      ),
                    if (_hasImage)
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.black.withValues(alpha: 0.55),
                              Colors.black.withValues(alpha: 0.1),
                            ],
                          ),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.all(KsvlSpace.lg),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _titleController.text.trim().isEmpty
                                ? 'Banner title'
                                : _titleController.text.trim(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleMedium?.copyWith(
                              color: _isActive || _hasImage
                                  ? Colors.white
                                  : k.textMuted,
                            ),
                          ),
                          if (_subtitleController.text.trim().isNotEmpty)
                            Text(
                              _subtitleController.text.trim(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall?.copyWith(
                                color: _isActive || _hasImage
                                    ? Colors.white.withValues(alpha: 0.85)
                                    : k.textMuted,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.photo_camera_outlined, size: 18),
                    label: const Text('Camera'),
                  ),
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined, size: 18),
                    label: const Text('Gallery'),
                  ),
                ),
              ],
            ),
            if (_hasImage)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => setState(() {
                    _pickedImageBytes = null;
                    _existingImageUrl = null;
                  }),
                  icon: const Icon(Icons.hide_image_outlined, size: 18),
                  label: const Text('Remove image (use emoji)'),
                ),
              ),
            const SizedBox(height: KsvlSpace.lg),
            const KsvlOverline('Fallback artwork'),
            const SizedBox(height: KsvlSpace.sm),
            Wrap(
              spacing: KsvlSpace.sm,
              runSpacing: KsvlSpace.sm,
              children: [
                for (final emoji in _emojiOptions)
                  _EmojiChoice(
                    emoji: emoji,
                    selected: emoji == _emoji,
                    onTap: () => setState(() => _emoji = emoji),
                  ),
              ],
            ),
            const SizedBox(height: KsvlSpace.xl),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Banner title',
                hintText: 'e.g. Festive Dry Fruit Combo',
              ),
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Give the banner a title';
                if (value.length < 3) return 'Use at least 3 characters';
                return null;
              },
            ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: _subtitleController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Subtitle',
                hintText: 'e.g. Up to 25% OFF',
                helperText: 'Optional',
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
            DropdownButtonFormField<BannerLinkType>(
              initialValue: _linkType,
              decoration: const InputDecoration(
                labelText: 'Tapping this banner opens',
              ),
              items: [
                for (final r in BannerLinkType.values)
                  DropdownMenuItem(value: r, child: Text(r.label)),
              ],
              onChanged: (v) {
                if (v == null) return;
                setState(() {
                  _linkType = v;
                  if (v != BannerLinkType.category) _categoryId = null;
                });
              },
            ),
            if (_linkType == BannerLinkType.category) ...[
              const SizedBox(height: KsvlSpace.md),
              DropdownButtonFormField<String>(
                initialValue: _categoryId ??
                    (AppCatalog.instance.activeCategories.isEmpty
                        ? null
                        : AppCatalog.instance.activeCategories.first.id),
                decoration: const InputDecoration(
                  labelText: 'Category',
                ),
                items: [
                  for (final c in AppCatalog.instance.activeCategories)
                    DropdownMenuItem(value: c.id, child: Text(c.name)),
                ],
                onChanged: (v) => setState(() => _categoryId = v),
                validator: (v) {
                  if (_linkType == BannerLinkType.category &&
                      (v == null || v.isEmpty)) {
                    return 'Pick a category';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: KsvlSpace.lg),
            KsvlCard(
              padding: const EdgeInsets.symmetric(
                horizontal: KsvlSpace.lg,
                vertical: KsvlSpace.sm,
              ),
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show on storefront'),
                subtitle: Text(
                  _isActive
                      ? 'Customers will see this banner now'
                      : 'Saved as a draft, hidden from customers',
                  style: text.bodySmall,
                ),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    String? imageUrl = _existingImageUrl;
    if (_pickedImageBytes != null) {
      try {
        imageUrl = await CloudinaryService.instance.uploadImage(
          _pickedImageBytes!,
          folder: 'banners',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Image upload failed. Try again.')),
          );
        return;
      }
    }
    if (!mounted) return;

    final store = context.read<StoreProvider>();
    final existing = widget.banner;
    final item = BannerItem(
      id: existing?.id ?? 'b${DateTime.now().millisecondsSinceEpoch}',
      title: _titleController.text.trim(),
      subtitle: _subtitleController.text.trim(),
      imageEmoji: _emoji,
      linkType: _linkType,
      categoryId: _linkType == BannerLinkType.category ? _categoryId : null,
      isActive: _isActive,
      imageUrl: imageUrl,
    );

    if (existing == null) {
      store.addBanner(item);
    } else {
      store.updateBanner(item);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(existing == null ? 'Banner created' : 'Banner updated'),
        ),
      );
  }
}

class _EmojiChoice extends StatelessWidget {
  const _EmojiChoice({
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);

    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: KsvlRadius.allSm,
          child: AnimatedContainer(
            duration: KsvlMotion.fast,
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? k.brandSoft : k.surfaceSubtle,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(
                color: selected ? k.brand : k.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 24)),
          ),
        ),
      ),
    );
  }
}
