/// Shared domain models, mock catalogue and the KSVL design system.
library;

export 'data/app_catalog.dart';
export 'data/firestore/category_repository.dart';
export 'data/firestore/product_repository.dart';
export 'data/firestore/banner_repository.dart';
export 'data/firestore/store_config_repository.dart';
export 'data/firestore/order_repository.dart';
export 'data/firestore/user_repository.dart';
export 'models/banner_item.dart';
export 'models/catalog_category.dart';
export 'models/delivery_settings.dart';
export 'models/order.dart';
export 'models/product.dart';
export 'models/saved_address.dart';
export 'models/store_location.dart';
export 'services/auth_service.dart';
export 'services/cloudinary_service.dart';
export 'utils/delivery_slots.dart';
export 'utils/geo_utils.dart';
export 'utils/price_format.dart';

// Design system — tokens, semantics and the shared ThemeData builder.
export 'design/ksvl_palette.dart';
export 'design/ksvl_semantics.dart';
export 'design/ksvl_theme.dart';
export 'design/ksvl_tokens.dart';
export 'design/ksvl_typography.dart';

// Shared UI primitives.
export 'ui/ksvl_badge.dart';
export 'ui/ksvl_card.dart';
export 'ui/ksvl_category_style.dart';
export 'ui/ksvl_empty_state.dart';
export 'ui/ksvl_filter_chips.dart';
export 'ui/ksvl_layout.dart';
export 'ui/ksvl_loader.dart';
export 'ui/ksvl_price_text.dart';
export 'ui/ksvl_product_thumb.dart';
export 'ui/ksvl_quantity_stepper.dart';
export 'ui/ksvl_section_header.dart';
export 'ui/ksvl_sheet.dart';
export 'ui/ksvl_tone.dart';
export 'ui/ksvl_vitamin_chips.dart';
