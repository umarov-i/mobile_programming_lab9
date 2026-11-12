import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[];

  @override
  CartState build() {
    _history.clear(); 
    return const CartState();
  }

  bool get canUndo => _history.isNotEmpty;

  void _change(CartState next) {
    if (next == state) return;
    _history.add(state);
    state = next;
  }

  void add(Product p) => _change(state.copyWith(lines: state.lines.withProduct(p)));
  void changeQty(String id, int delta) =>
      _change(state.copyWith(lines: state.lines.changeQty(id, delta)));
  void applyCoupon(String code) => _change(state.withCoupon(code));

  void undo() {
    if (_history.isEmpty) return;
    state = state.restoredFrom(_history.removeLast());
  }

  Future<void> checkout() async {
    if (state.status == CheckoutStatus.submitting || state.lines.isEmpty) return;
    state = state.copyWith(status: CheckoutStatus.submitting, clearCheckoutError: true);
    try {
      final id = await ref.read(checkoutApiProvider).submit(state.total);
      _history.clear();
      state = CartState(status: CheckoutStatus.success, orderId: id);
    } on CheckoutException catch (e) {
      state = state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message);
    }
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final canUndoProvider = Provider<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});
