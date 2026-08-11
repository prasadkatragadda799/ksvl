import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/catalog_category.dart';

class CategoryRepository {
  CategoryRepository._();
  static final CategoryRepository instance = CategoryRepository._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('categories');

  Stream<List<CatalogCategory>> watchAll() {
    return _col.snapshots().map(
          (snap) => snap.docs
              .map((d) => CatalogCategory.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  Future<void> upsert(CatalogCategory category) {
    return _col.doc(category.id).set(category.toJson());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
