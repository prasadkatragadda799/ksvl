import 'package:ksvl_shared/ksvl_shared.dart';

class CartItem {
  const CartItem({
    required this.product,
    required this.variant,
    required this.quantity,
  });

  final Product product;
  final ProductVariant variant;
  final int quantity;

  String get key => '${product.id}_${variant.id}';

  double get unitPrice => variant.specialPrice;
  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      product: product,
      variant: variant,
      quantity: quantity ?? this.quantity,
    );
  }
}
