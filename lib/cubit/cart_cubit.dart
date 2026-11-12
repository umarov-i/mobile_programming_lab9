import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  void _change(CartState next) {
    if (next == state) return;
    emit(state.record(next)); // history lives inside the state, so BlocBuilder sees canUndo
  }

  void add(Product p) => _change(state.copyWith(lines: state.lines.withProduct(p)));
  void changeQty(String id, int delta) =>
      _change(state.copyWith(lines: state.lines.changeQty(id, delta)));
  void applyCoupon(String code) => _change(state.withCoupon(code));
  void undo() => emit(state.undone());

  Future<void> checkout() async {
    if (state.status == CheckoutStatus.submitting || state.lines.isEmpty) return;
    emit(state.copyWith(status: CheckoutStatus.submitting, clearCheckoutError: true));
    try {
      final id = await _api.submit(state.total);
      if (isClosed) return; // emit after close() throws
      emit(CartState(status: CheckoutStatus.success, orderId: id));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
  }
}
