import 'package:flutter_test/flutter_test.dart';
import 'package:admin_app/main.dart';

void main() {
  testWidgets('Admin app loads the dashboard', (tester) async {
    await tester.pumpWidget(const KsvlAdminApp());
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('KSVL Naturals'), findsOneWidget);
    expect(find.text('Today at a glance'), findsOneWidget);
    expect(find.text('Store is open'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
  });
}
