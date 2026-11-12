import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  final keyboard = catalog.first;
  late MockCheckoutApi api;

  setUp(() => api = MockCheckoutApi());

  blocTest<CartCubit, CartState>(
    'add, add, coupon emits exactly three states',
    build: () => CartCubit(api),
    act: (c) {
      c
        ..add(keyboard)
        ..add(keyboard)
        ..applyCoupon('SAVE10');
    },
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting then failure and keeps lines',
    setUp: () => when(() => api.submit(any()))
        .thenAnswer((_) async => throw const CheckoutException('Card declined')),
    build: () => CartCubit(api),
    act: (c) async {
      c.add(keyboard);
      await c.checkout();
    },
    expect: () => [
      isA<CartState>().having((s) => s.lines.length, 'lines', 1),
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines.length, 'lines', 1),
    ],
  );
}
