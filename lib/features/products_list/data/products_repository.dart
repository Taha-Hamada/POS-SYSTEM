import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';

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

  Future<Product> setActiveState(String id, {required bool isActive}) async {
    final ApiResponse response = await _api.patch(
      '/products/$id/active',
      body: <String, bool>{'isActive': isActive},
    );

    return Product.fromJson(response.object);
  }
}
