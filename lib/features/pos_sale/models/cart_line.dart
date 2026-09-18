import '../../../core/models/product.dart';

/// سطر واحد في السلة.
///
/// الكمية بكسور عشان الأصناف اللي بتتباع بالكيلو أو اللتر — السيرفر
/// بيقبلها كده أصلًا، والسلة كانت بتقفلها على أعداد صحيحة من غير سبب.
class CartLine {
  CartLine({required this.product, this.quantity = 1});

  final Product product;
  double quantity;

  double get total => product.price * quantity;
}
