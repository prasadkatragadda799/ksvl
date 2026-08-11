import 'package:cloud_firestore/cloud_firestore.dart' hide Order;

import '../../models/order.dart';

class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('orders');

  Order _fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final data = Map<String, dynamic>.from(d.data());
    final ts = data['createdAt'];
    data['createdAt'] =
        ts is Timestamp ? ts.toDate().toIso8601String() : (ts ?? '');
    data['id'] = d.id;
    return Order.fromJson(data);
  }

  Map<String, dynamic> _toDoc(Order order) {
    final json = order.toJson();
    json['createdAt'] = Timestamp.fromDate(order.createdAt);
    return json;
  }

  /// All orders, newest first — used by the admin app.
  Stream<List<Order>> watchAll() {
    return _col.orderBy('createdAt', descending: true).snapshots().map(
          (snap) => snap.docs.map(_fromDoc).toList(),
        );
  }

  /// Only the given customer's orders, matched by phone (not device/uid) so
  /// order history follows the phone number across devices — used by the
  /// customer app's history.
  Stream<List<Order>> watchForPhone(String phone) {
    return _col
        .where('phone', isEqualTo: '+91 $phone')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(_fromDoc).toList());
  }

  Future<void> create(Order order) {
    return _col.doc(order.id).set(_toDoc(order));
  }

  Future<void> updateStatus(String orderId, OrderStatus status) {
    return _col.doc(orderId).update({'status': status.name});
  }
}
