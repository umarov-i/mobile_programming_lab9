import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'models/cart.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

/// Logs every Cubit change and every Bloc transition (Bloc also shows the event).
class CartObserver extends BlocObserver {
  @override
  void onChange(BlocBase<dynamic> bloc, Change<dynamic> change) {
    super.onChange(bloc, change);
    final c = change.currentState, n = change.nextState;
    if (c is CartState && n is CartState) {
      debugPrint('[${bloc.runtimeType}] onChange items ${c.itemCount} -> ${n.itemCount}, status ${n.status.name}');
    }
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition<dynamic, dynamic> t) {
    super.onTransition(bloc, t);
    debugPrint('[${bloc.runtimeType}] onTransition event: ${t.event.runtimeType}');
  }
}

void main() {
  Bloc.observer = CartObserver();
  runApp(const ProviderScope(child: CartApp()));
}

class CartApp extends StatelessWidget {
  const CartApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'One Cart, Four Ways',
        theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
        home: const HomePage(),
      );
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final pages = <(String, Widget)>[
      ('setState', const SetStateCartPage()),
      ('Riverpod', const RiverpodCartPage()),
      ('Cubit', const CubitCartPage()),
      ('Bloc', const BlocCartPage()),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('One Cart, Four Ways')),
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          for (final (label, page) in pages)
            Padding(
              padding: const EdgeInsets.all(6),
              child: FilledButton(
                onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)),
                child: Text(label),
              ),
            ),
        ]),
      ),
    );
  }
}
