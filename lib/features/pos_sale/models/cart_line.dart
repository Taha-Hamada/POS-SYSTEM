import '../../../core/models/product.dart';

/// سطر واحد في السلة.
///
/// الكمية بكسور عشان الأصناف اللي بتتباع بالكيلو أو اللتر — السيرفر
/// بيقبلها كده أصلًا، والسلة كانت بتقفلها على أعداد صحيحة من غير سبب.
class CartLine {
  CartLine({
    required this.product,
    this.quantity = 1,
    this.pricingMode = SalePricingMode.piece,
  });

  final Product product;
  double quantity;
  SalePricingMode pricingMode;

  double get quantityInPieces {
    if (product.piecesPerCarton <= 0) return quantity;
    return pricingMode == SalePricingMode.carton
        ? quantity * product.piecesPerCarton
        : quantity;
  }

  double get unitPrice => product.priceForMode(pricingMode);

  double get total => unitPrice * quantityInPieces;
}
