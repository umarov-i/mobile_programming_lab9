import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartCubit(CheckoutApi()), 
        child: const _CubitCartView(), 
      );
}

class _CubitCartView extends StatelessWidget {
  const _CubitCartView();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<CartCubit>();
    return BlocListener<CartCubit, CartState>(
      listenWhen: (p, c) => p.status != c.status,
      listener: (context, state) => showCheckoutFeedback(context, state),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Cart · Cubit'),
          actions: [
            BlocSelector<CartCubit, CartState, bool>(
              selector: (s) => s.canUndo,
              builder: (context, canUndo) => UndoButton(onPressed: canUndo ? cubit.undo : null),
            ),
          ],
        ),
        body: BlocSelector<CartCubit, CartState, List<CartLine>>(
          selector: (s) => s.lines,
          builder: (context, lines) => CartBody(
            lines: lines,
            onAdd: cubit.add,
            onQtyChanged: cubit.changeQty,
            footer: Column(children: [
              BlocSelector<CartCubit, CartState, String?>(
                selector: (s) => s.couponError,
                builder: (context, error) =>
                    CouponField(errorText: error, onApply: cubit.applyCoupon),
              ),
              BlocSelector<CartCubit, CartState, CartTotals>(
                selector: (s) => s.totals,
                builder: (context, totals) {
                  debugPrint('Cubit summary card rebuilt'); 
                  return SummaryCard(totals: totals);
                },
              ),
              BlocSelector<CartCubit, CartState, bool>(
                selector: (s) => s.status == CheckoutStatus.submitting,
                builder: (context, busy) =>
                    CheckoutButton(submitting: busy, onPressed: cubit.checkout),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
