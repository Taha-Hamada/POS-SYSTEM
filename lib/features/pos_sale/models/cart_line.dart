import '../../../core/models/product.dart';

/// سطر واحد في السلة.
class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  int quantity;

  double get total => product.price * quantity;
}
