import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/product.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');

  Stream<List<Product>> watchAll() {
    return _col.snapshots().map(
          (snap) => snap.docs
              .map((d) => Product.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  Future<void> upsert(Product product) {
    return _col.doc(product.id).set(product.toJson());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
