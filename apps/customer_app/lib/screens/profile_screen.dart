import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import 'package:customer_app/providers/catalog_provider.dart';
import 'package:customer_app/providers/shell_provider.dart';
import 'package:customer_app/providers/user_account_provider.dart';
import 'package:customer_app/providers/wishlist_provider.dart';
import 'package:customer_app/widgets/address_form_sheet.dart';
import 'package:customer_app/widgets/location_sheet.dart';
import 'package:customer_app/widgets/login_sheet.dart';
import 'package:customer_app/widgets/product_detail_sheet.dart';

/// Everything that belongs to the customer rather than to the shop: who they
/// are, where we deliver, what they saved, and the way out.
///
/// Orders used to live here behind a tab. They have their own destination now,
/// because "where is my order" is the single most common reason a customer
/// reopens a shop and it should never be two taps deep.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        titleSpacing: KsvlSpace.lg,
        actions: [
          if (account.isLoggedIn)
            IconButton(
              tooltip: 'Sign out',
              onPressed: () => _confirmSignOut(context),
              icon: const Icon(Icons.logout_rounded),
            ),
          const SizedBox(width: KsvlSpace.xs),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          KsvlSpace.lg,
          KsvlSpace.lg,
          KsvlSpace.lg,
          KsvlSpace.xxxl,
        ),
        children: [
          KsvlPageWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _IdentityCard(),
                const SizedBox(height: KsvlSpace.xl),
                const _DeliveryCard(),
                const SizedBox(height: KsvlSpace.xl),
                if (account.isLoggedIn) ...[
                  const _AddressesSection(),
                  const SizedBox(height: KsvlSpace.xl),
                ],
                const _SavedSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context) async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text(
          'You’ll need to verify your number again to see order history on '
          'this device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
    if (leave == true && context.mounted) {
      await context.read<UserAccountProvider>().logout();
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard();

  @override
  Widget build(BuildContext context) {
    final account = context.watch<UserAccountProvider>();
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    if (!account.isLoggedIn) {
      return KsvlCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: k.surfaceSubtle,
                    shape: BoxShape.circle,
                    border: Border.all(color: k.border),
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: k.textSecondary,
                  ),
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Not signed in', style: text.titleMedium),
                      Text(
                        'Sign in to keep addresses and order history.',
                        style: text.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: KsvlSpace.md),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => showLoginSheet(context),
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Sign in with mobile number'),
              ),
            ),
          ],
        ),
      );
    }

    return KsvlCard(
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: k.brandSoft,
            child: Text(
              account.initials,
              style: text.titleMedium?.copyWith(color: k.onBrandSoft),
            ),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(account.displayName, style: text.titleMedium),
                Text('+91 ${account.phone}', style: text.bodySmall),
              ],
            ),
          ),
          KsvlBadge(
            label: 'Verified',
            tone: KsvlTone.success,
            icon: Icons.verified_user_outlined,
            dense: true,
          ),
        ],
      ),
    );
  }
}

class _DeliveryCard extends StatelessWidget {
  const _DeliveryCard();

  @override
  Widget build(BuildContext context) {
    final catalog = context.watch<CatalogProvider>();
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return KsvlCard(
      onTap: catalog.blocker == StorefrontBlocker.storeClosed
          ? null
          : () => showLocationSheet(context),
      semanticLabel: 'Delivery location',
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: k.brandSoft,
              borderRadius: KsvlRadius.allSm,
            ),
            child: Icon(Icons.pin_drop_outlined, color: k.onBrandSoft,
                size: 20),
          ),
          const SizedBox(width: KsvlSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(catalog.deliveryHeadline, style: text.titleSmall),
                const SizedBox(height: 1),
                Text(
                  catalog.deliveryDetail,
                  style: text.bodySmall?.copyWith(color: k.textMuted),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: k.textMuted),
        ],
      ),
    );
  }
}

class _AddressesSection extends StatelessWidget {
  const _AddressesSection();

  @override
  Widget build(BuildContext context) {
    final addresses = context.watch<UserAccountProvider>().addresses;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KsvlSectionHeader(
          title: 'Saved addresses',
          caption: addresses.isEmpty
              ? 'Add one so checkout is faster'
              : '${addresses.length} saved',
          trailing: TextButton.icon(
            onPressed: () => showAddressFormSheet(context),
            icon: const Icon(Icons.add_rounded, size: 16),
            label: const Text('Add'),
          ),
        ),
        const SizedBox(height: KsvlSpace.sm),
        for (final address in addresses)
          Padding(
            padding: const EdgeInsets.only(bottom: KsvlSpace.md),
            child: KsvlCard(
              onTap: () => showAddressFormSheet(context, existing: address),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: k.brandSoft,
                      borderRadius: KsvlRadius.allSm,
                    ),
                    child: Icon(
                      Icons.place_outlined,
                      color: k.brand,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address.label, style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(address.composedLine, style: text.bodySmall),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Delete',
                    onPressed: () => _confirmDelete(context, address),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: k.danger,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context, SavedAddress a) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete address?'),
        content: Text('Remove “${a.label}” from your saved addresses?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: KsvlColors.of(ctx).danger,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<UserAccountProvider>().deleteAddress(a.id);
    }
  }
}

/// What the heart on a product card adds up to.
class _SavedSection extends StatelessWidget {
  const _SavedSection();

  @override
  Widget build(BuildContext context) {
    final saved = context.watch<WishlistProvider>().productIds;
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;

    // A saved id whose product has since been unpublished — or left with no
    // sizes by the admin — simply drops out rather than crashing the tab.
    final products = AppCatalog.instance.products
        .where((p) => saved.contains(p.id) && p.variants.isNotEmpty)
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        KsvlSectionHeader(
          title: 'Saved items',
          caption: products.isEmpty
              ? 'Tap the heart on anything you want to come back to'
              : '${products.length} saved',
          trailing: products.isEmpty
              ? null
              : TextButton(
                  onPressed: () =>
                      context.read<WishlistProvider>().clear(),
                  child: const Text('Clear'),
                ),
        ),
        const SizedBox(height: KsvlSpace.sm),
        if (products.isEmpty)
          KsvlCard(
            child: Row(
              children: [
                Icon(
                  Icons.favorite_border_rounded,
                  size: 20,
                  color: k.textMuted,
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: Text(
                    'Nothing saved yet.',
                    style: text.bodySmall?.copyWith(color: k.textMuted),
                  ),
                ),
                TextButton(
                  onPressed: () =>
                      context.read<ShellProvider>().go(ShellTab.home),
                  child: const Text('Browse'),
                ),
              ],
            ),
          )
        else
          for (final product in products)
            Padding(
              padding: const EdgeInsets.only(bottom: KsvlSpace.md),
              child: KsvlCard(
                padding: const EdgeInsets.all(KsvlSpace.md),
                onTap: () => showProductDetailSheet(
                  context,
                  product: product,
                  initialVariant: product.variants.first,
                ),
                semanticLabel: product.name,
                child: Row(
                  children: [
                    KsvlProductThumb(
                      emoji: product.imageEmoji,
                      imageUrl: product.imageUrl,
                      styleIndex: product.categoryStyleIndex,
                      size: 46,
                      glyphSize: 24,
                      animate: false,
                    ),
                    const SizedBox(width: KsvlSpace.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall,
                          ),
                          const SizedBox(height: 2),
                          KsvlPriceText(
                            regularPrice: product.variants.first.regularPrice,
                            specialPrice: product.variants.first.specialPrice,
                            size: KsvlPriceSize.small,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Remove from saved',
                      onPressed: () => context
                          .read<WishlistProvider>()
                          .toggle(product.id),
                      icon: Icon(Icons.favorite_rounded, color: k.danger),
                    ),
                  ],
                ),
              ),
            ),
      ],
    );
  }
}
