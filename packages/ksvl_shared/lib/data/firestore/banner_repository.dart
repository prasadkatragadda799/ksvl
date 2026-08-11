import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/banner_item.dart';

class BannerRepository {
  BannerRepository._();
  static final BannerRepository instance = BannerRepository._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('banners');

  Stream<List<BannerItem>> watchAll() {
    return _col.snapshots().map(
          (snap) => snap.docs
              .map((d) => BannerItem.fromJson({...d.data(), 'id': d.id}))
              .toList(),
        );
  }

  Future<void> upsert(BannerItem banner) {
    return _col.doc(banner.id).set(banner.toJson());
  }

  Future<void> delete(String id) => _col.doc(id).delete();
}
