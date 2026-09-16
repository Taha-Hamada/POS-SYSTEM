import '../../products_list/data/products_repository.dart';

/// صف في جدول المتغيرات (مقاس/لون/SKU/سعر خاص).
///
/// السيرفر بيخزّن سعر خاص للمتغير، مش رصيد؛ الرصيد بيتمسك للمنتج في كل فرع.
class ProductVariant {
  ProductVariant({
    this.size = '',
    this.color = '',
    this.sku = '',
    this.price = '',
  });

  String size;
  String color;
  String sku;

  /// نص عشان الخانة فاضية لحد ما المستخدم يكتب سعر.
  String price;

  bool get isEmpty =>
      size.isEmpty && color.isEmpty && sku.isEmpty && price.isEmpty;

  ProductVariantInput toInput() => ProductVariantInput(
    size: size,
    color: color,
    sku: sku,
    priceOverride: double.tryParse(price.trim()),
  );
}
