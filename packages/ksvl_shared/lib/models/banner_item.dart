enum BannerLinkType {
  category('Category'),
  offers('Special Offers'),
  home('Home');

  const BannerLinkType(this.label);
  final String label;

  static BannerLinkType fromName(String? name) {
    for (final t in BannerLinkType.values) {
      if (t.name == name) return t;
    }
    return BannerLinkType.home;
  }
}

class BannerItem {
  BannerItem({
    required this.id,
    required this.title,
    this.linkType = BannerLinkType.home,
    this.categoryId,
    this.imageEmoji = '🏷️',
    this.subtitle = '',
    this.isActive = true,
    this.imageUrl,
  });

  final String id;
  String title;
  String subtitle;
  String imageEmoji;
  BannerLinkType linkType;

  /// Cloudinary-hosted banner artwork, uploaded from the admin app. When set,
  /// it is shown instead of the emoji-on-gradient fallback.
  String? imageUrl;

  /// When [linkType] is [BannerLinkType.category], filters the store to this id.
  String? categoryId;

  bool isActive;

  bool get hasImage => imageUrl != null && imageUrl!.trim().isNotEmpty;

  BannerItem copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageEmoji,
    BannerLinkType? linkType,
    String? categoryId,
    bool clearCategoryId = false,
    bool? isActive,
    String? imageUrl,
    bool clearImage = false,
  }) {
    return BannerItem(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageEmoji: imageEmoji ?? this.imageEmoji,
      linkType: linkType ?? this.linkType,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      isActive: isActive ?? this.isActive,
      imageUrl: clearImage ? null : (imageUrl ?? this.imageUrl),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'imageEmoji': imageEmoji,
        'linkType': linkType.name,
        'categoryId': categoryId,
        'isActive': isActive,
        'imageUrl': imageUrl,
      };

  factory BannerItem.fromJson(Map<String, dynamic> json) {
    return BannerItem(
      id: json['id'] as String,
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageEmoji: json['imageEmoji'] as String? ?? '🏷️',
      linkType: BannerLinkType.fromName(json['linkType'] as String?),
      categoryId: json['categoryId'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      imageUrl: json['imageUrl'] as String?,
    );
  }
}
