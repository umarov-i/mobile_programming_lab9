import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key});

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  final _api = CheckoutApi();
  CartState _state = const CartState();
  final List<CartState> _history = []; 

  void _apply(CartState next) {
    if (next == _state) return;
    setState(() {
      _history.add(_state);
      _state = next;
    });
  }

  void _add(Product p) => _apply(_state.copyWith(lines: _state.lines.withProduct(p)));
  void _changeQty(String id, int delta) =>
      _apply(_state.copyWith(lines: _state.lines.changeQty(id, delta)));
  void _applyCoupon(String code) => _apply(_state.withCoupon(code));

  void _undo() {
    if (_history.isEmpty) return;
    setState(() => _state = _state.restoredFrom(_history.removeLast()));
  }

  Future<void> _checkout() async {
    if (_state.status == CheckoutStatus.submitting || _state.lines.isEmpty) return;
    setState(() => _state = _state.copyWith(status: CheckoutStatus.submitting, clearCheckoutError: true));
    showCheckoutFeedback(context, _state);
    try {
      final id = await _api.submit(_state.total);
      if (!mounted) return;
      setState(() {
        _history.clear();
        _state = CartState(status: CheckoutStatus.success, orderId: id);
      });
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(() => _state =
          _state.copyWith(status: CheckoutStatus.failure, checkoutError: e.message));
    }
    if (!mounted) return;
    showCheckoutFeedback(context, _state);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cart · setState'),
          actions: [UndoButton(onPressed: _history.isEmpty ? null : _undo)],
        ),
        body: CartBody(
          lines: _state.lines,
          onAdd: _add,
          onQtyChanged: _changeQty,
          footer: Column(children: [
            CouponField(onApply: _applyCoupon, errorText: _state.couponError),
            SummaryCard(totals: _state.totals),
            CheckoutButton(
              submitting: _state.status == CheckoutStatus.submitting,
              onPressed: _checkout,
            ),
          ]),
        ),
      );
}
