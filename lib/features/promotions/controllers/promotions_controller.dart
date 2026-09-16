import 'package:flutter/foundation.dart' hide Category;

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../../core/models/promotion.dart';
import '../../products_list/data/products_repository.dart';
import '../data/promotions_repository.dart';
import '../models/promotion_input.dart';

/// حالة شاشة العروض: القايمة وفلاترها، والأقسام والمنتجات لحوار العرض.
class PromotionsController extends ChangeNotifier with LoadState {
  PromotionsController(
    this._repository,
    this._products, {
    this.canManage = false,
  });

  final PromotionsRepository _repository;
  final ProductsRepository _products;

  /// من غير صلاحية إدارة العروض الشاشة بتبقى للعرض بس.
  final bool canManage;

  List<Promotion> _all = <Promotion>[];

  PromotionStatus? _statusFilter;
  PromotionType? _typeFilter;

  PromotionStatus? get statusFilter => _statusFilter;
  PromotionType? get typeFilter => _typeFilter;

  List<Promotion> get rows => _all
      .where((Promotion p) {
        if (_statusFilter != null && p.status != _statusFilter) return false;
        if (_typeFilter != null && p.type != _typeFilter) return false;
        return true;
      })
      .toList(growable: false);

  int get visibleCount => rows.length;

  int countByStatus(PromotionStatus status) =>
      _all.where((Promotion p) => p.status == status).length;

  bool get isEmpty => !isLoading && !hasFailed && _all.isEmpty;

  Future<void> load() async {
    await runLoad(() async {
      _all = await _repository.fetchAll();
    });
  }

  Future<void> retry() => load();

  /// الضغط على نفس الشريحة تاني بيلغي الفلتر.
  void toggleStatusFilter(PromotionStatus status) {
    _statusFilter = _statusFilter == status ? null : status;
    notifyListeners();
  }

  void setTypeFilter(PromotionType? type) {
    _typeFilter = type;
    notifyListeners();
  }

  // ── الأقسام والمنتجات لحوار العرض ───────────────────────────────────────
  List<Category> _categories = <Category>[];
  List<Product> _catalog = <Product>[];
  bool _lookupsLoaded = false;

  List<Category> get categories => _categories;
  List<Product> get catalog => _catalog;

  /// بتتحمّل أول مرة الحوار يتفتح بس — الشاشة نفسها مش محتاجاها.
  Future<void> ensureLookups() async {
    if (_lookupsLoaded) return;

    try {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _products.fetchCategories(),
        _products.fetchAll(),
      ]);

      _categories = results[0] as List<Category>;
      _catalog = (results[1] as List<Product>)
          .where((Product p) => p.isActive)
          .toList(growable: false);
      _lookupsLoaded = true;
    } on ApiException {
      // الحوار بيشتغل برضه على «كل المنتجات» لو القوايم فشلت.
    }

    notifyListeners();
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────
  /// إنشاء عرض أو تعديله. بترجّع رسالة الخطأ لو فشل.
  Future<String?> save(PromotionInput input, {Promotion? existing}) async {
    final ApiException? failure = await runAction(() async {
      if (existing == null) {
        await _repository.create(input);
      } else {
        await _repository.update(existing.id, input);
      }
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<String?> setActive(
    Promotion promotion, {
    required bool isActive,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.setActive(promotion.id, isActive: isActive);
    });

    if (failure == null) await load();

    return failure?.message;
  }
}
