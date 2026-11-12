import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>((e, emit) =>
        _change(emit, state.copyWith(lines: state.lines.withProduct(e.product))));
    on<CartProductRemoved>((e, emit) =>
        _change(emit, state.copyWith(lines: state.lines.without(e.productId))));
    on<CartQtyChanged>((e, emit) =>
        _change(emit, state.copyWith(lines: state.lines.changeQty(e.productId, e.delta))));
    on<CartCouponApplied>((e, emit) => _change(emit, state.withCoupon(e.code)));
    on<CartUndone>((e, emit) => emit(state.undone()));
    on<CartCheckoutRequested>(_onCheckout, transformer: droppable());
  }

  final CheckoutApi _api;

  void _change(Emitter<CartState> emit, CartState next) {
    if (next == state) return;
    emit(state.record(next));
  }

  Future<void> _onCheckout(CartCheckoutRequested event, Emitter<CartState> emit) async {
    if (state.lines.isEmpty) return;
    emit(state.copyWith(status: CheckoutStatus.submitting, clearCheckoutError: true));
    try {
      final id = await _api.submit(state.total);
      if (emit.isDone) return; // bloc was closed during the await
      emit(CartState(status: CheckoutStatus.success, orderId: id));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
  }
}
