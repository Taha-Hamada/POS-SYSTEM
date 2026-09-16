import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';

/// متغير منتج وهو رايح للسيرفر.
///
/// السيرفر مش بيمسك رصيد لكل متغير، بيمسك سعر خاص بس، فالمدخلات هنا هي
/// اللي السيرفر بيخزّنه فعلًا مش أكتر.
class ProductVariantInput {
  const ProductVariantInput({
    this.size = '',
    this.color = '',
    this.sku = '',
    this.priceOverride,
  });

  final String size;
  final String color;
  final String sku;
  final double? priceOverride;

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (size.isNotEmpty) 'size': size,
    if (color.isNotEmpty) 'color': color,
    if (sku.isNotEmpty) 'sku': sku,
    if (priceOverride != null) 'priceOverride': priceOverride,
  };
}

/// منتج بالحقول اللي شاشة التعديل محتاجاها ومش في [Product].
typedef ProductDraft = ({
  Product product,
  String description,
  List<ProductVariantInput> variants,
});

/// قراءة وكتابة المنتجات والأقسام من الـ API.
class ProductsRepository {
  const ProductsRepository(this._api);

  final ApiClient _api;

  /// أقصى عدد الباك اند بيرجّعه في الصفحة الواحدة.
  static const int _pageSize = 100;

  /// بيجيب كل المنتجات صفحة ورا صفحة.
  ///
  /// الشاشة بتفلتر وترتّب محليًا زي ما كانت، فمحتاجة القايمة كاملة.
  /// كفاية لكتالوج متجر واحد؛ لو الكتالوج كبر، الفلترة تتنقل للسيرفر.
  Future<List<Product>> fetchAll({String? branchId}) async {
    final List<Product> products = <Product>[];
    int page = 1;

    while (true) {
      final ApiResponse response = await _api.get(
        '/products',
        query: <String, dynamic>{
          'page': page,
          'limit': _pageSize,
          'branch': branchId,
        },
      );

      products.addAll(response.list.map(Product.fromJson));

      if (!response.hasNext) break;
      page += 1;
    }

    return products;
  }

  Future<List<Category>> fetchCategories() async {
    final ApiResponse response = await _api.get(
      '/categories',
      query: <String, dynamic>{'limit': _pageSize, 'withProductCount': 'true'},
    );

    return response.list.map(Category.fromJson).toList();
  }

  /// بينشئ منتج جديد، ومعاه رصيد افتتاحي اختياري لفرع واحد.
  ///
  /// الرصيد الافتتاحي بيتسجل كحركة مخزون على السيرفر، فبيبان في تقرير
  /// المخزون زي أي إضافة تانية.
  Future<Product> create({
    required String name,
    required String sku,
    required String categoryId,
    required double price,
    required double cost,
    String? unit,
    String? brand,
    String? description,
    String? barcode,
    int minStock = 0,
    int openingStock = 0,
    String? branchId,
    List<ProductVariantInput> variants = const <ProductVariantInput>[],
  }) async {
    final ApiResponse response = await _api.post(
      '/products',
      body: <String, dynamic>{
        'name': name,
        'sku': sku,
        'category': categoryId,
        'price': price,
        'cost': cost,
        if (unit != null && unit.isNotEmpty) 'unit': unit,
        if (brand != null && brand.isNotEmpty) 'brand': brand,
        if (description != null && description.isNotEmpty)
          'description': description,
        if (barcode != null && barcode.isNotEmpty) 'barcode': barcode,
        'minStock': minStock,
        if (variants.isNotEmpty)
          'variants': variants
              .map((ProductVariantInput v) => v.toJson())
              .toList(growable: false),
        // من غير فرع مفيش مكان يتحط فيه الرصيد، فبنبعت المنتج لوحده.
        if (branchId != null && openingStock > 0)
          'openingStock': <String, dynamic>{
            'branch': branchId,
            'quantity': openingStock,
          },
      },
    );

    return Product.fromJson(response.object);
  }

  /// المنتج بكل حقوله عشان شاشة التعديل تتملى بيه.
  ///
  /// موديل [Product] مبيشيلش الوصف والمتغيرات لأن باقي الشاشات مش محتاجاهم،
  /// فبيرجعوا جنبه هنا.
  Future<ProductDraft> fetchForEdit(String id) async {
    final ApiResponse response = await _api.get('/products/$id');
    final Map<String, dynamic> data = response.object;

    return (
      product: Product.fromJson(data),
      description: data['description'] as String? ?? '',
      variants: (data['variants'] as List<dynamic>? ?? <dynamic>[])
          .whereType<Map<String, dynamic>>()
          .map(
            (Map<String, dynamic> v) => ProductVariantInput(
              size: v['size'] as String? ?? '',
              color: v['color'] as String? ?? '',
              sku: v['sku'] as String? ?? '',
              priceOverride: (v['priceOverride'] as num?)?.toDouble(),
            ),
          )
          .toList(growable: false),
    );
  }

  /// بيعدّل بيانات المنتج. الرصيد مش هنا — بيتغير بحركات المخزون بس.
  Future<Product> update(
    String id, {
    required String name,
    required String sku,
    required String categoryId,
    required double price,
    required double cost,
    required String unit,
    required String brand,
    required String description,
    required int minStock,
    String? barcode,
    List<ProductVariantInput> variants = const <ProductVariantInput>[],
  }) async {
    final ApiResponse response = await _api.patch(
      '/products/$id',
      body: <String, dynamic>{
        'name': name,
        'sku': sku,
        'category': categoryId,
        'price': price,
        'cost': cost,
        'unit': unit,
        'brand': brand,
        'description': description,
        'minStock': minStock,
        // null بتشيل الباركود لو المستخدم مسحه.
        'barcode': barcode,
        'variants': variants
            .map((ProductVariantInput v) => v.toJson())
            .toList(growable: false),
      },
    );

    return Product.fromJson(response.object);
  }

  /// بيرفع صورة المنتج ويستبدل القديمة. السيرفر بيقبل PNG/JPG/WEBP لحد 2 ميجا.
  Future<Product> uploadImage(
    String id, {
    required List<int> bytes,
    required String filename,
  }) async {
    final ApiResponse response = await _api.upload(
      '/products/$id/image',
      field: 'image',
      bytes: bytes,
      filename: filename,
    );
    return Product.fromJson(response.object);
  }

  Future<Product> removeImage(String id) async {
    final ApiResponse response = await _api.delete('/products/$id/image');
    return Product.fromJson(response.object);
  }

  /// تعديل سعر جماعي بنسبة أو بمبلغ — على منتجات محددة أو قسم كامل.
  ///
  /// السيرفر بيقرّب لخانتين ومبينزّلش السعر تحت الصفر في التعديل بالمبلغ.
  Future<({int matched, int modified})> bulkUpdatePrices({
    List<String>? productIds,
    String? categoryId,
    required bool percentage,
    required double value,
  }) async {
    final ApiResponse response = await _api.patch(
      '/products/bulk-prices',
      body: <String, dynamic>{
        if (productIds != null && productIds.isNotEmpty)
          'productIds': productIds,
        'category': ?categoryId,
        'mode': percentage ? 'percentage' : 'fixed',
        'value': value,
      },
    );

    return (
      matched: (response.object['matched'] as num?)?.toInt() ?? 0,
      modified: (response.object['modified'] as num?)?.toInt() ?? 0,
    );
  }

  Future<Product> setActiveState(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/products/$id/active',
      body: <String, bool>{'isActive': isActive},
    );

    return Product.fromJson(response.object);
  }
}
