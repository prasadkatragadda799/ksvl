import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';

/// Create or edit a product and its size variants.
class ProductFormScreen extends StatefulWidget {
  const ProductFormScreen({super.key, this.product});

  final Product? product;

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

/// Mutable editing state for one variant row.
class _VariantFormData {
  _VariantFormData({
    String? id,
    String title = '',
    String regular = '',
    String special = '',
    this.isAvailable = true,
  })  : id = id ?? 'v${DateTime.now().microsecondsSinceEpoch}',
        titleController = TextEditingController(text: title),
        regularController = TextEditingController(text: regular),
        specialController = TextEditingController(text: special);

  final String id;
  final TextEditingController titleController;
  final TextEditingController regularController;
  final TextEditingController specialController;
  bool isAvailable;

  void dispose() {
    titleController.dispose();
    regularController.dispose();
    specialController.dispose();
  }
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _descController;
  late final List<TextEditingController> _vitaminControllers;
  late CatalogCategory _category;
  late String _emoji;
  Uint8List? _pickedImageBytes;
  String? _existingImageUrl;
  bool _saving = false;
  late bool _isFeatured;
  late bool _isAvailable;
  final List<_VariantFormData> _variants = [];

  static const _emojiChoices = [
    '🥜',
    '🌰',
    '🥥',
    '🫘',
    '🌶️',
    '🧄',
    '🫚',
    '🫐',
    '🍇',
    '🍘',
    '🍿',
    '🫙',
  ];

  static const _vitaminHints = [
    'e.g. Vitamin E',
    'e.g. Magnesium',
    'e.g. Zinc',
  ];

  bool get _isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p?.name ?? '');
    _descController = TextEditingController(text: p?.description ?? '');
    final categories = AppCatalog.instance.activeCategories;
    if (p != null) {
      CatalogCategory? match;
      for (final c in categories) {
        if (c.id == p.categoryId) {
          match = c;
          break;
        }
      }
      _category = match ??
          CatalogCategory(
            id: p.categoryId,
            name: p.categoryLabel,
            shortLabel: p.categoryLabel,
            styleIndex: p.categoryStyleIndex,
          );
    } else {
      _category = categories.isNotEmpty
          ? categories.first
          : const CatalogCategory(
              id: 'dry_fruits',
              name: 'Dry Fruits',
              shortLabel: 'Dry Fruits',
            );
    }
    _emoji = p?.imageEmoji ?? _emojiChoices.first;
    _existingImageUrl = p?.imageUrl;
    _isFeatured = p?.isFeatured ?? false;
    _isAvailable = p?.isAvailable ?? true;
    final vitamins = p?.vitamins ?? const <String>[];
    _vitaminControllers = List.generate(
      3,
      (i) => TextEditingController(
        text: i < vitamins.length ? vitamins[i] : '',
      ),
    );

    if (p != null) {
      for (final v in p.variants) {
        _variants.add(
          _VariantFormData(
            id: v.id,
            title: v.title,
            regular: v.regularPrice.toStringAsFixed(0),
            special: v.specialPrice.toStringAsFixed(0),
            isAvailable: v.isAvailable,
          ),
        );
      }
    } else {
      _variants.add(_VariantFormData(title: '250g'));
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final c in _vitaminControllers) {
      c.dispose();
    }
    for (final v in _variants) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit product' : 'New product'),
        actions: [
          if (_isEdit)
            IconButton(
              onPressed: _confirmDelete,
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete product',
              color: k.danger,
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(top: BorderSide(color: k.border)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(KsvlSpace.lg),
            child: Row(
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
                        : Text(_isEdit ? 'Save changes' : 'Add product'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            KsvlSpace.lg,
            KsvlSpace.lg,
            KsvlSpace.lg,
            KsvlSpace.xxxl,
          ),
          children: [
            const KsvlSectionHeader(
              title: 'Product details',
              caption: 'What customers see on the storefront',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const KsvlOverline('Product photo'),
                  const SizedBox(height: KsvlSpace.sm),
                  Text(
                    'Capture with camera or pick from gallery. '
                    'Customers see this photo on the store.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: k.surfaceSubtle,
                        borderRadius: KsvlRadius.allMd,
                        border: Border.all(color: k.border),
                      ),
                      child: ClipRRect(
                        borderRadius: KsvlRadius.allMd,
                        child: _pickedImageBytes != null
                            ? Image.memory(_pickedImageBytes!,
                                fit: BoxFit.cover)
                            : KsvlProductThumb(
                                emoji: _emoji,
                                imageUrl: _existingImageUrl,
                                category: _category,
                                styleIndex: _category.styleIndex,
                                animate: false,
                                glyphSize: 56,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.camera),
                          icon: const Icon(Icons.photo_camera_outlined),
                          label: const Text('Camera'),
                        ),
                      ),
                      const SizedBox(width: KsvlSpace.md),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          icon: const Icon(Icons.photo_library_outlined),
                          label: const Text('Gallery'),
                        ),
                      ),
                    ],
                  ),
                  if (_pickedImageBytes != null || _existingImageUrl != null) ...[
                    const SizedBox(height: KsvlSpace.sm),
                    TextButton.icon(
                      onPressed: () => setState(() {
                        _pickedImageBytes = null;
                        _existingImageUrl = null;
                      }),
                      icon: const Icon(Icons.hide_image_outlined, size: 18),
                      label: const Text('Remove photo (use icon)'),
                    ),
                  ],
                  const SizedBox(height: KsvlSpace.md),
                  Text(
                    'Fallback icon (used when no photo)',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: KsvlSpace.sm),
                  SizedBox(
                    height: 48,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _emojiChoices.length,
                      separatorBuilder: (_, _) =>
                          const SizedBox(width: KsvlSpace.sm),
                      itemBuilder: (context, index) {
                        final emoji = _emojiChoices[index];
                        return _EmojiChoice(
                          emoji: emoji,
                          selected: emoji == _emoji,
                          onTap: () => setState(() => _emoji = emoji),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: KsvlSpace.lg),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                      hintText: 'e.g. W240 Cashews',
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Product name is required';
                      if (value.length < 2) return 'Enter a valid name';
                      return null;
                    },
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  DropdownButtonFormField<CatalogCategory>(
                    initialValue: _resolveDropdownValue(
                      context.watch<ProductProvider>().activeCategories,
                    ),
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: [
                      for (final c
                          in context.watch<ProductProvider>().activeCategories)
                        DropdownMenuItem(
                          value: c,
                          child: Row(
                            children: [
                              Icon(KsvlCategoryStyle.of(c).icon, size: 17),
                              const SizedBox(width: KsvlSpace.sm),
                              Text(c.name),
                            ],
                          ),
                        ),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _category = v);
                    },
                    validator: (v) =>
                        v == null ? 'Pick a category' : null,
                  ),
                  const SizedBox(height: KsvlSpace.md),
                  TextFormField(
                    controller: _descController,
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Short description shown to customers',
                      alignLabelWithHint: true,
                    ),
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Description is required';
                      if (value.length < 10) {
                        return 'Add a little more detail (10+ characters)';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xxl),
            const KsvlSectionHeader(
              title: 'Vitamins & highlights',
              caption: 'Up to 3 nutrition callouts shown to customers',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              child: Column(
                children: [
                  for (var i = 0; i < 3; i++) ...[
                    if (i > 0) const SizedBox(height: KsvlSpace.md),
                    TextFormField(
                      controller: _vitaminControllers[i],
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Highlight ${i + 1}',
                        hintText: _vitaminHints[i],
                        prefixIcon: const Icon(Icons.eco_outlined, size: 20),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xxl),
            const KsvlSectionHeader(
              title: 'Storefront visibility',
              caption: 'Control stock and featured placement',
            ),
            const SizedBox(height: KsvlSpace.md),
            KsvlCard(
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      _isAvailable
                          ? Icons.check_circle_outline
                          : Icons.hide_source_outlined,
                      color: _isAvailable ? k.success : k.danger,
                    ),
                    title: Text(
                      _isAvailable ? 'Available to customers' : 'Hidden / OOS',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isAvailable ? k.success : k.danger,
                      ),
                    ),
                    subtitle: const Text(
                      'Master switch — off hides this product from buying',
                    ),
                    value: _isAvailable,
                    onChanged: (v) => setState(() => _isAvailable = v),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(
                      Icons.star_rounded,
                      color: _isFeatured ? k.brand : k.textMuted,
                    ),
                    title: Text(
                      _isFeatured ? 'Featured on store' : 'Not featured',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: _isFeatured ? k.brand : k.textPrimary,
                      ),
                    ),
                    subtitle: const Text(
                      'Featured products get a star badge on the customer app',
                    ),
                    value: _isFeatured,
                    onChanged: (v) => setState(() => _isFeatured = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: KsvlSpace.xxl),
            KsvlSectionHeader(
              title: 'Sizes & pricing',
              caption: '${_variants.length} '
                  '${_variants.length == 1 ? 'variant' : 'variants'}',
              trailing: TextButton.icon(
                onPressed: () => setState(
                  () => _variants.add(_VariantFormData()),
                ),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add size'),
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
            for (var index = 0; index < _variants.length; index++)
              _VariantEditor(
                key: ValueKey(_variants[index].id),
                data: _variants[index],
                index: index,
                canRemove: _variants.length > 1,
                onRemove: () => setState(() {
                  _variants[index].dispose();
                  _variants.removeAt(index);
                }),
                onAvailabilityChanged: (value) => setState(
                  () => _variants[index].isAvailable = value,
                ),
                onPriceChanged: () => setState(() {}),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Check the highlighted fields')),
        );
      return;
    }

    setState(() => _saving = true);
    String? imageUrl = _existingImageUrl;
    if (_pickedImageBytes != null) {
      try {
        imageUrl = await CloudinaryService.instance.uploadImage(
          _pickedImageBytes!,
          folder: 'products',
        );
      } catch (_) {
        if (!mounted) return;
        setState(() => _saving = false);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Photo upload failed. Try again.')),
          );
        return;
      }
    }
    if (!mounted) return;

    List<ProductVariant> variants;
    try {
      variants = _variants
          .map(
            (v) => ProductVariant(
              id: v.id,
              title: v.titleController.text.trim(),
              regularPrice: double.parse(v.regularController.text.trim()),
              specialPrice: double.parse(v.specialController.text.trim()),
              isAvailable: v.isAvailable,
            ),
          )
          .toList();
    } catch (_) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Check the size prices — one looks invalid')),
        );
      return;
    }

    final vitamins = _vitaminControllers
        .map((c) => c.text.trim())
        .where((v) => v.isNotEmpty)
        .take(3)
        .toList();

    final product = Product(
      id: widget.product?.id ?? 'p${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      categoryId: _category.id,
      categoryLabel: _category.name,
      categoryStyleIndex: _category.styleIndex,
      description: _descController.text.trim(),
      imageEmoji: _emoji,
      imageUrl: imageUrl,
      vitamins: vitamins,
      variants: variants,
      isAvailable: _isAvailable && variants.any((v) => v.isAvailable),
      isFeatured: _isFeatured,
    );

    final provider = context.read<ProductProvider>();
    if (_isEdit) {
      provider.updateProduct(product);
    } else {
      provider.addProduct(product);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isEdit ? '${product.name} updated' : '${product.name} added',
          ),
        ),
      );
  }

  CatalogCategory? _resolveDropdownValue(List<CatalogCategory> active) {
    for (final c in active) {
      if (c.id == _category.id) return c;
    }
    return active.isEmpty ? null : active.first;
  }

  Future<void> _confirmDelete() async {
    final product = widget.product!;
    final k = KsvlColors.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.delete_outline_rounded, color: k.danger, size: 28),
        title: Text('Delete ${product.name}?'),
        content: const Text(
          'The product and all its sizes will be removed from the catalogue. '
          'This cannot be undone.',
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
    if (confirmed != true || !mounted) return;
    context.read<ProductProvider>().deleteProduct(product.id);
    Navigator.pop(context);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('${product.name} deleted')));
  }
}

class _VariantEditor extends StatelessWidget {
  const _VariantEditor({
    super.key,
    required this.data,
    required this.index,
    required this.canRemove,
    required this.onRemove,
    required this.onAvailabilityChanged,
    required this.onPriceChanged,
  });

  final _VariantFormData data;
  final int index;
  final bool canRemove;
  final VoidCallback onRemove;
  final ValueChanged<bool> onAvailabilityChanged;
  final VoidCallback onPriceChanged;

  @override
  Widget build(BuildContext context) {
    final k = KsvlColors.of(context);
    final text = Theme.of(context).textTheme;
    final regular = double.tryParse(data.regularController.text.trim()) ?? 0;
    final special = double.tryParse(data.specialController.text.trim()) ?? 0;
    final discount = discountPercent(regular, special);

    return Padding(
      padding: const EdgeInsets.only(bottom: KsvlSpace.md),
      child: KsvlCard(
        padding: const EdgeInsets.all(KsvlSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                KsvlOverline('Size ${index + 1}'),
                const Spacer(),
                if (discount > 0)
                  KsvlBadge(
                    label: '$discount% off',
                    tone: KsvlTone.success,
                    dense: true,
                  ),
                if (canRemove) ...[
                  const SizedBox(width: KsvlSpace.sm),
                  SizedBox(
                    width: 32,
                    height: 28,
                    child: IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close_rounded, size: 17),
                      color: k.danger,
                      padding: EdgeInsets.zero,
                      tooltip: 'Remove this size',
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: data.titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Size label',
                hintText: 'e.g. 500g',
                isDense: true,
              ),
              validator: (v) {
                if ((v?.trim() ?? '').isEmpty) return 'Size is required';
                return null;
              },
            ),
            const SizedBox(height: KsvlSpace.md),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: data.regularController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onPriceChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Regular',
                      prefixText: '₹ ',
                      isDense: true,
                    ),
                    validator: (v) {
                      final n = double.tryParse(v?.trim() ?? '');
                      if (n == null || n <= 0) return 'Required';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: KsvlSpace.md),
                Expanded(
                  child: TextFormField(
                    controller: data.specialController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => onPriceChanged(),
                    decoration: const InputDecoration(
                      labelText: 'Selling',
                      prefixText: '₹ ',
                      isDense: true,
                    ),
                    validator: (v) {
                      final value = double.tryParse(v?.trim() ?? '');
                      final reg =
                          double.tryParse(data.regularController.text.trim());
                      if (value == null || value <= 0) return 'Required';
                      if (reg != null && value > reg) return 'Above regular';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: KsvlSpace.xs),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              dense: true,
              title: Text(
                data.isAvailable ? 'Available to buy' : 'Out of stock',
                style: text.labelMedium?.copyWith(
                  color: data.isAvailable ? k.success : k.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
              value: data.isAvailable,
              onChanged: onAvailabilityChanged,
            ),
          ],
        ),
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
            width: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? k.brandSoft : k.surfaceSubtle,
              borderRadius: KsvlRadius.allSm,
              border: Border.all(
                color: selected ? k.brand : k.border,
                width: selected ? 1.8 : 1,
              ),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ),
      ),
    );
  }
}
