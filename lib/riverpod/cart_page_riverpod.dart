import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier); // handle only, no subscription
    final lines = ref.watch(cartProvider.select((s) => s.lines)); // rebuild on lines only
    final canUndo = ref.watch(canUndoProvider);

    ref.listen(cartProvider.select((s) => s.status), (prev, next) {
      showCheckoutFeedback(context, ref.read(cartProvider));
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [UndoButton(onPressed: canUndo ? cart.undo : null)],
      ),
      body: CartBody(
        lines: lines,
        onAdd: cart.add,
        onQtyChanged: cart.changeQty,
        footer: const Column(children: [_Coupon(), _Summary(), _Checkout()]),
      ),
    );
  }
}

class _Coupon extends ConsumerWidget {
  const _Coupon();

  @override
  Widget build(BuildContext context, WidgetRef ref) => CouponField(
        errorText: ref.watch(cartProvider.select((s) => s.couponError)),
        onApply: ref.read(cartProvider.notifier).applyCoupon,
      );
}

class _Summary extends ConsumerWidget {
  const _Summary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartProvider.select((s) => s.totals));
    debugPrint('Riverpod summary card rebuilt');
    return SummaryCard(totals: totals);
  }
}

class _Checkout extends ConsumerWidget {
  const _Checkout();

  @override
  Widget build(BuildContext context, WidgetRef ref) => CheckoutButton(
        submitting: ref.watch(
          cartProvider.select((s) => s.status == CheckoutStatus.submitting),
        ),
        onPressed: ref.read(cartProvider.notifier).checkout,
      );
}
