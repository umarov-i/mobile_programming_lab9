import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(CheckoutApi()),
        child: const _BlocCartView(),
      );
}

class _BlocCartView extends StatelessWidget {
  const _BlocCartView();

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<CartBloc>();
    return BlocListener<CartBloc, CartState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) => showCheckoutFeedback(context, state),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart · Bloc'),
          actions: [
            BlocSelector<CartBloc, CartState, bool>(
              selector: (s) => s.canUndo,
              builder: (context, canUndo) =>
                  UndoButton(onPressed: canUndo ? () => bloc.add(const CartUndone()) : null),
            ),
          ],
        ),
        body: BlocSelector<CartBloc, CartState, List<CartLine>>(
          selector: (s) => s.lines,
          builder: (context, lines) => CartBody(
            lines: lines,
            onAdd: (p) => bloc.add(CartProductAdded(p)),
            onQtyChanged: (id, delta) => bloc.add(CartQtyChanged(id, delta)),
            footer: Column(children: [
              BlocSelector<CartBloc, CartState, String?>(
                selector: (s) => s.couponError,
                builder: (context, error) => CouponField(
                  errorText: error,
                  onApply: (code) => bloc.add(CartCouponApplied(code)),
                ),
              ),
              BlocSelector<CartBloc, CartState, CartTotals>(
                selector: (s) => s.totals,
                builder: (context, totals) {
                  debugPrint('Bloc summary card rebuilt');
                  return SummaryCard(totals: totals);
                },
              ),
              BlocSelector<CartBloc, CartState, bool>(
                selector: (s) => s.status == CheckoutStatus.submitting,
                builder: (context, busy) => CheckoutButton(
                  submitting: busy,
                  onPressed: () => bloc.add(const CartCheckoutRequested()),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
