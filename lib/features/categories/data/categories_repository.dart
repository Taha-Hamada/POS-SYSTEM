import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';

/// بيانات قسم رايحة للسيرفر.
class CategoryInput {
  const CategoryInput({
    required this.name,
    required this.iconName,
    required this.colorHex,
    this.parentId,
    this.isActive = true,
  });

  final String name;
  final String iconName;

  /// #RRGGBB زي ما السيرفر بيقبله.
  final String colorHex;
  final String? parentId;
  final bool isActive;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'icon': iconName,
    'color': colorHex,
    // null بتشيل القسم الأب لو كان متحدد.
    'parent': parentId,
    'isActive': isActive,
  };
}

/// نتيجة حذف قسم: بيتمسح لو فاضي، وبيتعطّل لو عليه منتجات.
typedef CategoryRemoval = ({bool deleted, bool deactivated, int productsCount});

/// إدارة أقسام المنتجات.
class CategoriesRepository {
  const CategoriesRepository(this._api);

  final ApiClient _api;

  /// كل الأقسام بما فيها المعطّلة، ومعاها عدد منتجات كل قسم.
  Future<List<Category>> fetchAll() async {
    final ApiResponse response = await _api.get(
      '/categories',
      query: <String, dynamic>{
        'limit': 100,
        'withProductCount': 'true',
        'sort': 'sortOrder name',
      },
    );
    return response.list.map(Category.fromJson).toList();
  }

  Future<Category> create(CategoryInput input) async {
    final ApiResponse response = await _api.post(
      '/categories',
      body: input.toJson(),
    );
    return Category.fromJson(response.object);
  }

  Future<Category> update(String id, CategoryInput input) async {
    final ApiResponse response = await _api.patch(
      '/categories/$id',
      body: input.toJson(),
    );
    return Category.fromJson(response.object);
  }

  Future<CategoryRemoval> remove(String id) async {
    final ApiResponse response = await _api.delete('/categories/$id');
    return (
      deleted: response.object['deleted'] as bool? ?? false,
      deactivated: response.object['deactivated'] as bool? ?? false,
      productsCount: (response.object['productsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
