import 'package:flutter_test/flutter_test.dart';
import 'package:customer_app/main.dart';

void main() {
  testWidgets('Storefront loads with catalogue and location chip', (tester) async {
    await tester.pumpWidget(const KsvlStoreApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('KSVL Naturals'), findsOneWidget);
    expect(find.textContaining('Set location'), findsWidgets);
    expect(find.text('All'), findsOneWidget);
  });
}
