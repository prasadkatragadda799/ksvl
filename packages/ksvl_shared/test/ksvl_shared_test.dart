import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ksvl_shared/ksvl_shared.dart';

void main() {
  test('formats rupee amounts with Indian digit grouping', () {
    expect(formatRupee(1040), '₹1,040');
    expect(formatRupee(100000), '₹1,00,000');
  });

  test('10 km radius around hub', () {
    const hub = StoreLocation(
      label: 'Test hub',
      latitude: 17.7340,
      longitude: 83.3085,
      radiusKm: 10,
    );

    final inside = isWithinDeliveryRadius(
      store: hub,
      customerLat: hub.latitude + 0.01,
      customerLng: hub.longitude,
    );
    final outside = isWithinDeliveryRadius(
      store: hub,
      customerLat: hub.latitude + 0.5,
      customerLng: hub.longitude,
    );
    expect(inside, isTrue);
    expect(outside, isFalse);
  });

  test('product JSON round-trips through variants and vitamins', () {
    final product = Product(
      id: 'p1',
      name: 'W240 Cashews',
      categoryId: 'dry_fruits',
      categoryLabel: 'Dry Fruits',
      description: 'Premium cashews',
      imageEmoji: '🥜',
      isFeatured: true,
      vitamins: const ['Vitamin E', 'Magnesium', 'Zinc'],
      variants: [
        ProductVariant(
          id: 'p1v1',
          title: '250g',
          regularPrice: 320,
          specialPrice: 280,
        ),
      ],
    );

    final roundTripped = Product.fromJson(product.toJson());
    expect(roundTripped.name, product.name);
    expect(roundTripped.isFeatured, isTrue);
    expect(roundTripped.vitamins.length, 3);
    expect(roundTripped.variants.single.specialPrice, 280);
  });

  group('KsvlSheetScaffold and the soft keyboard', () {
    Future<({double titleTop, double bodyHeight})> layoutFor(
      WidgetTester tester, {
      required double screenHeight,
      required double keyboardInset,
      double topPadding = 24.0,
    }) async {
      // Drive the *view*, not a wrapped MediaQuery. MediaQueryData.size is
      // only data — it does not constrain layout — and MaterialApp rebuilds
      // its own MediaQuery from the view anyway, shadowing any wrapper. Sizing
      // the view is the only way this harness actually shrinks the screen.
      tester.view
        ..devicePixelRatio = 1.0
        ..physicalSize = Size(360, screenHeight)
        ..viewInsets = FakeViewPadding(bottom: keyboardInset)
        ..padding = FakeViewPadding(top: topPadding);
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        // No Scaffold: a Scaffold applies its own resizeToAvoidBottomInset
        // handling and would hide the geometry under test. A modal bottom
        // sheet hands its builder the full screen, bottom-aligned — which is
        // exactly this.
        const MaterialApp(
          home: Align(
            alignment: Alignment.bottomCenter,
            child: KsvlSheetScaffold(
              title: 'Enter OTP',
              child: SizedBox(
                height: 400,
                child: Text('OTP input body'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Enter OTP'), findsOneWidget);
      return (
        titleTop: tester.getTopLeft(find.text('Enter OTP')).dy,
        bodyHeight: tester.getSize(find.byType(SingleChildScrollView)).height,
      );
    }

    testWidgets('sits between the notch and the keyboard', (tester) async {
      final layout = await layoutFor(
        tester,
        screenHeight: 600,
        keyboardInset: 300,
      );

      // Clear of the notch…
      expect(layout.titleTop, greaterThanOrEqualTo(24.0));
      // …and clear of the keyboard.
      expect(layout.titleTop, lessThan(300.0));
      expect(layout.bodyHeight, greaterThan(0.0));
    });

    testWidgets(
      'keeps a usable sheet when the viewport shrinks and the inset is also '
      'reported',
      (tester) async {
        // Mobile web: the layout viewport is already down to 300px because the
        // keyboard opened, *and* viewInsets still reports those 300px.
        // Subtracting the inset from an already-shrunken viewport left the
        // sheet with nothing to lay out in, so the body collapsed to zero and
        // the number field was clipped out of existence.
        final layout = await layoutFor(
          tester,
          screenHeight: 300,
          keyboardInset: 300,
        );

        expect(tester.takeException(), isNull);
        expect(layout.titleTop, greaterThanOrEqualTo(0.0));
        // The point of the clamp: there is still a sheet to type into.
        expect(layout.bodyHeight, greaterThan(24.0));
      },
    );
  });
}
