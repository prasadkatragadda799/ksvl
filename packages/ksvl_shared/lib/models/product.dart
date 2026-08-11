class ProductVariant {
  ProductVariant({
    required this.id,
    required this.title,
    required this.regularPrice,
    required this.specialPrice,
    this.isAvailable = true,
  });

  final String id;
  String title;
  double regularPrice;
  double specialPrice;
  bool isAvailable;

  ProductVariant copyWith({
    String? id,
    String? title,
    double? regularPrice,
    double? specialPrice,
    bool? isAvailable,
  }) {
    return ProductVariant(
      id: id ?? this.id,
      title: title ?? this.title,
      regularPrice: regularPrice ?? this.regularPrice,
      specialPrice: specialPrice ?? this.specialPrice,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'regularPrice': regularPrice,
        'specialPrice': specialPrice,
        'isAvailable': isAvailable,
      };

  factory ProductVariant.fromJson(Map<String, dynamic> json) {
    return ProductVariant(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      regularPrice: (json['regularPrice'] as num?)?.toDouble() ?? 0,
      specialPrice: (json['specialPrice'] as num?)?.toDouble() ?? 0,
      isAvailable: json['isAvailable'] as bool? ?? true,
    );
  }
}

class Product {
  Product({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.categoryLabel,
    required this.description,
    required this.imageEmoji,
    required this.variants,
    this.categoryStyleIndex = 0,
    this.isAvailable = true,
    this.isFeatured = false,
    this.imageUrl,
    List<String>? vitamins,
  }) : vitamins = _normalizeVitamins(vitamins);

  final String id;
  String name;

  /// Links to [CatalogCategory.id] so admin-added categories work everywhere.
  String categoryId;

  /// Denormalized label for display even if the category is later renamed.
  String categoryLabel;

  /// Style kit index copied from the category at save time.
  int categoryStyleIndex;

  String description;
  String imageEmoji;

  /// Cloudinary-hosted photo URL, if the admin uploaded one.
  String? imageUrl;

  List<String> vitamins;
  List<ProductVariant> variants;
  bool isAvailable;
  bool isFeatured;

  bool get hasPhoto => imageUrl != null && imageUrl!.trim().isNotEmpty;

  bool get hasOutOfStockVariant => variants.any((v) => !v.isAvailable);

  int get availableVariantCount =>
      variants.where((v) => v.isAvailable).length;

  Product copyWith({
    String? id,
    String? name,
    String? categoryId,
    String? categoryLabel,
    int? categoryStyleIndex,
    String? description,
    String? imageEmoji,
    String? imageUrl,
    bool clearImageUrl = false,
    List<String>? vitamins,
    List<ProductVariant>? variants,
    bool? isAvailable,
    bool? isFeatured,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      categoryStyleIndex: categoryStyleIndex ?? this.categoryStyleIndex,
      description: description ?? this.description,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      imageUrl: clearImageUrl ? null : (imageUrl ?? this.imageUrl),
      vitamins: vitamins ?? this.vitamins,
      variants: variants ?? this.variants,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'categoryId': categoryId,
        'categoryLabel': categoryLabel,
        'categoryStyleIndex': categoryStyleIndex,
        'description': description,
        'imageEmoji': imageEmoji,
        'imageUrl': imageUrl,
        'vitamins': vitamins,
        'variants': variants.map((v) => v.toJson()).toList(),
        'isAvailable': isAvailable,
        'isFeatured': isFeatured,
      };

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawVariants = json['variants'] as List<dynamic>? ?? const [];
    return Product(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryLabel: json['categoryLabel'] as String? ?? '',
      categoryStyleIndex: (json['categoryStyleIndex'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      imageEmoji: json['imageEmoji'] as String? ?? '🛒',
      imageUrl: json['imageUrl'] as String?,
      vitamins: (json['vitamins'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      variants: [
        for (final v in rawVariants)
          ProductVariant.fromJson(Map<String, dynamic>.from(v as Map)),
      ],
      isAvailable: json['isAvailable'] as bool? ?? true,
      isFeatured: json['isFeatured'] as bool? ?? false,
    );
  }

  static List<String> _normalizeVitamins(List<String>? raw) {
    if (raw == null) return const [];
    return raw
        .map((v) => v.trim())
        .where((v) => v.isNotEmpty)
        .take(3)
        .toList(growable: false);
  }
}
