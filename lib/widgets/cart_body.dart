import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartBody extends StatelessWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onQtyChanged,
    required this.footer,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final Widget footer;

  @override
  Widget build(BuildContext context) => Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(spacing: 8, children: [
            for (final p in catalog)
              ActionChip(
                label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                onPressed: () => onAdd(p),
              ),
          ]),
        ),
        Expanded(
          child: lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(children: [
                  for (final l in lines)
                    ListTile(
                      key: ValueKey(l.product.id),
                      title: Text(l.product.name),
                      subtitle: Text(l.subtotal.toStringAsFixed(2)),
                      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                          icon: const Icon(Icons.remove),
                          onPressed: () => onQtyChanged(l.product.id, -1),
                        ),
                        Text('${l.qty}'),
                        IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () => onQtyChanged(l.product.id, 1),
                        ),
                      ]),
                    ),
                ]),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(12, 0, 12, 12), child: footer),
      ]);
}

class UndoButton extends StatelessWidget {
  const UndoButton({super.key, required this.onPressed});
  final VoidCallback? onPressed; // null = disabled

  @override
  Widget build(BuildContext context) =>
      IconButton(icon: const Icon(Icons.undo), tooltip: 'Undo', onPressed: onPressed);
}

class CouponField extends StatefulWidget {
  const CouponField({super.key, required this.onApply, this.errorText});
  final void Function(String code) onApply;
  final String? errorText;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(
          child: TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'Coupon code',
              isDense: true,
              errorText: widget.errorText, 
            ),
            onSubmitted: widget.onApply,
          ),
        ),
        const SizedBox(width: 8),
        FilledButton.tonal(
          onPressed: () => widget.onApply(_controller.text),
          child: const Text('Apply'),
        ),
      ]);
}

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.totals});
  final CartTotals totals;

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String value, {bool bold = false}) {
      final style = bold ? const TextStyle(fontWeight: FontWeight.bold) : null;
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          row('Items', '${totals.itemCount}'),
          row('Subtotal', totals.subtotal.toStringAsFixed(2)),
          row('Discount', '-${totals.discount.toStringAsFixed(2)}'),
          row('Total', totals.total.toStringAsFixed(2), bold: true),
        ]),
      ),
    );
  }
}

class CheckoutButton extends StatelessWidget {
  const CheckoutButton({super.key, required this.submitting, required this.onPressed});
  final bool submitting;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: FilledButton(
          onPressed: submitting ? null : onPressed,
          child: submitting
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Checkout'),
        ),
      );
}

void showCheckoutFeedback(BuildContext context, CartState s) {
  final m = ScaffoldMessenger.of(context);
  switch (s.status) {
    case CheckoutStatus.submitting:
      m.hideCurrentMaterialBanner();
    case CheckoutStatus.success:
      m.hideCurrentMaterialBanner();
      m.showSnackBar(SnackBar(content: Text('Order ${s.orderId} placed')));
    case CheckoutStatus.failure:
      m
        ..hideCurrentMaterialBanner()
        ..showMaterialBanner(MaterialBanner(
          content: Text(s.checkoutError ?? 'Checkout failed'),
          actions: [TextButton(onPressed: m.hideCurrentMaterialBanner, child: const Text('Dismiss'))],
        ));
    case CheckoutStatus.idle:
      break;
  }
}
