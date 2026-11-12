import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cart_four_ways/setstate/cart_page_setstate.dart';

void main() {
  testWidgets('two keyboards + SAVE10 totals 88.20', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SetStateCartPage()));

    await tester.tap(find.text('Keyboard · 49'));
    await tester.pump();
    await tester.tap(find.text('Keyboard · 49'));
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'SAVE10');
    await tester.tap(find.text('Apply'));
    await tester.pump();

    expect(find.text('88.20'), findsOneWidget);
  });
}
