enum OrderStatus {
  pending('Pending'),
  inProgress('In Progress'),
  completed('Completed'),
  cancelled('Cancelled');

  const OrderStatus(this.label);
  final String label;

  static OrderStatus fromName(String? name) {
    for (final s in OrderStatus.values) {
      if (s.name == name) return s;
    }
    return OrderStatus.pending;
  }
}

enum PaymentType {
  cod('COD'),
  online('Online');

  const PaymentType(this.label);
  final String label;

  static PaymentType fromName(String? name) {
    for (final p in PaymentType.values) {
      if (p.name == name) return p;
    }
    return PaymentType.cod;
  }
}

class OrderItem {
  const OrderItem({
    required this.productName,
    required this.variantTitle,
    required this.quantity,
    required this.unitPrice,
  });

  final String productName;
  final String variantTitle;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  String get displayLine =>
      '$productName ($variantTitle) x $quantity — ₹${_format(lineTotal)}';

  Map<String, dynamic> toJson() => {
        'productName': productName,
        'variantTitle': variantTitle,
        'quantity': quantity,
        'unitPrice': unitPrice,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['productName'] as String? ?? '',
      variantTitle: json['variantTitle'] as String? ?? '',
      quantity: json['quantity'] as int? ?? 0,
      unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
    );
  }

  static String _format(double value) {
    final s = value.toStringAsFixed(0);
    if (s.length <= 3) return s;
    final last3 = s.substring(s.length - 3);
    final rest = s.substring(0, s.length - 3);
    final withCommas = rest.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{2})+(?!\d))'),
      (m) => '${m[1]},',
    );
    return '$withCommas,$last3';
  }
}

class Order {
  Order({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.customerName,
    required this.phone,
    required this.address,
    required this.pincode,
    required this.locationTag,
    required this.items,
    required this.paymentType,
    this.deliverySlot = '',
    this.uid = '',
    this.receiptUrl = '',
  });

  final String id;
  final DateTime createdAt;
  OrderStatus status;
  final String customerName;
  final String phone;
  final String address;
  final String pincode;
  final String locationTag;
  final List<OrderItem> items;
  final PaymentType paymentType;
  final String deliverySlot;

  /// Firebase Auth uid of the customer who placed this order.
  final String uid;

  /// Cloudinary URL of the payment screenshot, when [paymentType] is
  /// [PaymentType.online]. Empty for cash-on-delivery orders.
  final String receiptUrl;

  double get totalAmount =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  Order copyWith({
    OrderStatus? status,
    String? deliverySlot,
  }) {
    return Order(
      id: id,
      createdAt: createdAt,
      status: status ?? this.status,
      customerName: customerName,
      phone: phone,
      address: address,
      pincode: pincode,
      locationTag: locationTag,
      items: items,
      paymentType: paymentType,
      deliverySlot: deliverySlot ?? this.deliverySlot,
      uid: uid,
      receiptUrl: receiptUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'status': status.name,
        'customerName': customerName,
        'phone': phone,
        'address': address,
        'pincode': pincode,
        'locationTag': locationTag,
        'items': items.map((i) => i.toJson()).toList(),
        'paymentType': paymentType.name,
        'deliverySlot': deliverySlot,
        'uid': uid,
        'receiptUrl': receiptUrl,
      };

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return Order(
      id: json['id'] as String,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      status: OrderStatus.fromName(json['status'] as String?),
      customerName: json['customerName'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      pincode: json['pincode'] as String? ?? '',
      locationTag: json['locationTag'] as String? ?? '',
      items: [
        for (final item in rawItems)
          OrderItem.fromJson(Map<String, dynamic>.from(item as Map)),
      ],
      paymentType: PaymentType.fromName(json['paymentType'] as String?),
      deliverySlot: json['deliverySlot'] as String? ?? '',
      uid: json['uid'] as String? ?? '',
      receiptUrl: json['receiptUrl'] as String? ?? '',
    );
  }
}
