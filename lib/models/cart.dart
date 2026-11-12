import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({required this.id, required this.name, required this.price});
  final String id;
  final String name;
  final double price;

  @override
  List<Object?> get props => [id, name, price];
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine extends Equatable {
  const CartLine({required this.product, required this.qty});
  final Product product;
  final int qty;

  double get subtotal => product.price * qty;
  CartLine copyWith({int? qty}) => CartLine(product: product, qty: qty ?? this.qty);

  @override
  List<Object?> get props => [product, qty];
}

extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [for (final l in this) l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  List<CartLine> changeQty(String productId, int delta) {
    final out = <CartLine>[];
    for (final l in this) {
      if (l.product.id != productId) {
        out.add(l);
        continue;
      }
      final q = l.qty + delta;
      if (q > 0) out.add(l.copyWith(qty: q));
    }
    return out;
  }

  double get subtotal => fold<double>(0, (s, l) => s + l.subtotal);
  int get itemCount => fold<int>(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

typedef CartTotals = ({int itemCount, double subtotal, double discount, double total});

class CartState extends Equatable {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const [],
  });

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;

  final List<CartState> history;

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == 'SAVE10' ? subtotal * 0.10 : 0.0;
  double get total => subtotal - discount;
  bool get canUndo => history.isNotEmpty;
  CartTotals get totals =>
      (itemCount: itemCount, subtotal: subtotal, discount: discount, total: total);

  CartState copyWith({
    List<CartLine>? lines,
    String? coupon,
    String? couponError,
    bool clearCouponError = false,
    CheckoutStatus? status,
    String? orderId,
    String? checkoutError,
    bool clearCheckoutError = false,
    List<CartState>? history,
  }) =>
      CartState(
        lines: lines ?? this.lines,
        coupon: coupon ?? this.coupon,
        couponError: clearCouponError ? null : (couponError ?? this.couponError),
        status: status ?? this.status,
        orderId: orderId ?? this.orderId,
        checkoutError: clearCheckoutError ? null : (checkoutError ?? this.checkoutError),
        history: history ?? this.history,
      );

  CartState withCoupon(String code) {
    final c = code.trim().toUpperCase();
    if (c == 'SAVE10') return copyWith(coupon: c, clearCouponError: true);
    return copyWith(couponError: 'Invalid coupon code');
  }

  CartState restoredFrom(CartState prev, {List<CartState>? history}) => CartState(
        lines: prev.lines,
        coupon: prev.coupon,
        couponError: prev.couponError,
        status: status,
        orderId: orderId,
        checkoutError: checkoutError,
        history: history ?? this.history,
      );


  CartState record(CartState next) =>
      next.copyWith(history: [...history, copyWith(history: const [])]);

  CartState undone() => history.isEmpty
      ? this
      : restoredFrom(history.last, history: history.sublist(0, history.length - 1));

  @override
  List<Object?> get props =>
      [lines, coupon, couponError, status, orderId, checkoutError, history];
}
