import 'package:flutter/material.dart';
import 'package:ksvl_shared/ksvl_shared.dart';
import 'package:provider/provider.dart';

import '../providers/product_provider.dart';

/// Admin CRUD for catalogue categories.
///
/// Anything saved here is immediately available on the customer storefront
/// through [AppCatalog] — no frontend release required.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProductProvider>();
    final categories = provider.categories;
    final counts = provider.categoryCounts;
    final text = Theme.of(context).textTheme;
    final k = KsvlColors.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Categories')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add category'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.fromLTRB(
          KsvlSpace.lg,
          KsvlSpace.lg,
          KsvlSpace.lg,
          KsvlSpace.xxxl,
        ),
        itemCount: categories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: KsvlSpace.lg),
              child: Text(
                'New categories show on the customer app automatically '
                'in filters and product forms.',
                style: text.bodySmall,
              ),
            );
          }
          final category = categories[index - 1];
          final style = KsvlCategoryStyle.of(category);
          final count = counts[category.id] ?? 0;

          return Padding(
            padding: const EdgeInsets.only(bottom: KsvlSpace.md),
            child: KsvlCard(
              onTap: () => _openEditor(context, category: category),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: style.tint,
                      borderRadius: KsvlRadius.allSm,
                    ),
                    child: Icon(style.icon, color: style.accent),
                  ),
                  const SizedBox(width: KsvlSpace.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(category.name, style: text.titleSmall),
                        Text(
                          '${category.shortLabel} · $count products'
                          '${category.isActive ? '' : ' · hidden'}',
                          style: text.bodySmall?.copyWith(
                            color: category.isActive ? null : k.danger,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: category.isActive,
                    onChanged: (value) {
                      provider.upsertCategory(
                        category.copyWith(isActive: value),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, {
    CatalogCategory? category,
  }) async {
    await showKsvlSheet<void>(
      context,
      builder: (_) => _CategoryEditorSheet(category: category),
    );
  }
}

class _CategoryEditorSheet extends StatefulWidget {
  const _CategoryEditorSheet({this.category});

  final CatalogCategory? category;

  @override
  State<_CategoryEditorSheet> createState() => _CategoryEditorSheetState();
}

class _CategoryEditorSheetState extends State<_CategoryEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _shortController;
  late int _styleIndex;
  late bool _isActive;

  bool get _isEdit => widget.category != null;

  @override
  void initState() {
    super.initState();
    final c = widget.category;
    _nameController = TextEditingController(text: c?.name ?? '');
    _shortController = TextEditingController(text: c?.shortLabel ?? '');
    _styleIndex = c?.styleIndex ??
        (AppCatalog.instance.categories.length %
            CategoryStyleKit.palette.length);
    _isActive = c?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final kit = CategoryStyleKit.ofIndex(_styleIndex);

    return KsvlSheetScaffold(
      title: _isEdit ? 'Edit category' : 'Add category',
      subtitle: 'Visible on the customer store as soon as you save',
      footer: SafeArea(
        top: false,
        child: Row(
          children: [
            if (_isEdit)
              TextButton(
                onPressed: _delete,
                child: const Text('Remove'),
              ),
            const Spacer(),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEdit ? 'Save' : 'Add category'),
            ),
          ],
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Category name',
                hintText: 'e.g. Seeds & Nuts',
              ),
              onChanged: (v) {
                if (!_isEdit && _shortController.text.trim().isEmpty) {
                  // leave short empty for user; optional auto-fill on save
                }
                setState(() {});
              },
              validator: (v) {
                if (v == null || v.trim().length < 2) {
                  return 'Enter a category name';
                }
                return null;
              },
            ),
            const SizedBox(height: KsvlSpace.md),
            TextFormField(
              controller: _shortController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Short label (chips)',
                hintText: 'e.g. Seeds',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Short label is required';
                }
                return null;
              },
            ),
            const SizedBox(height: KsvlSpace.lg),
            Text('Colour & icon', style: text.titleSmall),
            const SizedBox(height: KsvlSpace.sm),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: CategoryStyleKit.palette.length,
                separatorBuilder: (_, _) => const SizedBox(width: KsvlSpace.sm),
                itemBuilder: (context, index) {
                  final item = CategoryStyleKit.palette[index];
                  final selected = index == _styleIndex;
                  return InkWell(
                    onTap: () => setState(() => _styleIndex = index),
                    borderRadius: KsvlRadius.allSm,
                    child: AnimatedContainer(
                      duration: KsvlMotion.fast,
                      width: 56,
                      decoration: BoxDecoration(
                        color: item.tint,
                        borderRadius: KsvlRadius.allSm,
                        border: Border.all(
                          color: selected ? item.accent : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Icon(item.icon, color: item.accent),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: KsvlSpace.md),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Show on customer store'),
              subtitle: Text(
                _isActive
                    ? 'Appears in filters and product forms'
                    : 'Hidden from customers',
              ),
              value: _isActive,
              onChanged: (v) => setState(() => _isActive = v),
              secondary: Icon(kit.icon, color: kit.accent),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final name = _nameController.text.trim();
    final short = _shortController.text.trim();
    final existing = widget.category;
    final id = existing?.id ??
        name
            .toLowerCase()
            .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
            .replaceAll(RegExp(r'^_|_$'), '');

    final category = CatalogCategory(
      id: id.isEmpty
          ? 'cat_${DateTime.now().millisecondsSinceEpoch}'
          : id,
      name: name,
      shortLabel: short,
      styleIndex: _styleIndex,
      isActive: _isActive,
    );

    context.read<ProductProvider>().upsertCategory(category);
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            _isEdit
                ? '"${category.name}" updated — live on store'
                : '"${category.name}" added — live on store',
          ),
        ),
      );
  }

  Future<void> _delete() async {
    final category = widget.category!;
    final ok = await context.read<ProductProvider>().deleteCategory(category.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? (category.isActive
                    ? '"${category.name}" removed from store'
                    : '"${category.name}" deleted')
                : 'Keep at least one category',
          ),
        ),
      );
  }
}
