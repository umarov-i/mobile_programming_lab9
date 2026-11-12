import 'package:bloc_test/bloc_test.dart';
import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  final keyboard = catalog.first;
  late MockCheckoutApi api;

  setUp(() => api = MockCheckoutApi());

  blocTest<CartBloc, CartState>(
    'add, add, coupon emits exactly three states',
    build: () => CartBloc(api),
    act: (b) => b
      ..add(CartProductAdded(keyboard))
      ..add(CartProductAdded(keyboard))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 1),
      isA<CartState>().having((s) => s.itemCount, 'itemCount', 2),
      isA<CartState>().having((s) => s.total, 'total', closeTo(88.2, 0.001)),
    ],
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting then failure and keeps lines',
    setUp: () => when(() => api.submit(any()))
        .thenAnswer((_) async => throw const CheckoutException('Card declined')),
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (b) => b.add(const CartCheckoutRequested()),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.failure)
          .having((s) => s.lines.length, 'lines', 1),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable(): two checkout taps emit a single submitting state',
    setUp: () => when(() => api.submit(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      return 'ORD-1';
    }),
    build: () => CartBloc(api),
    seed: () => CartState(lines: [CartLine(product: keyboard, qty: 1)]),
    act: (b) => b
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 150),
    expect: () => [
      isA<CartState>().having((s) => s.status, 'status', CheckoutStatus.submitting),
      isA<CartState>()
          .having((s) => s.status, 'status', CheckoutStatus.success)
          .having((s) => s.orderId, 'orderId', 'ORD-1'),
    ],
    verify: (_) => verify(() => api.submit(any())).called(1),
  );
}
