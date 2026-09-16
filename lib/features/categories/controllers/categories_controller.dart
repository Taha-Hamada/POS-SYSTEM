import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' hide Category;

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../data/categories_repository.dart';

/// حالة شاشة الأقسام.
class CategoriesController extends ChangeNotifier with LoadState {
  CategoriesController(this._repository, {this.canManage = false});

  final CategoriesRepository _repository;

  /// من غير إدارة الأقسام الشاشة بتبقى للعرض بس.
  final bool canManage;

  List<Category> _all = <Category>[];

  /// الأقسام الرئيسية الأول وتحت كل واحد فروعه، عشان الشجرة تبان في القايمة.
  List<Category> get rows {
    final List<Category> roots = _all.where((Category c) => c.isRoot).toList();
    return <Category>[
      for (final Category root in roots) ...<Category>[
        root,
        ..._all.where((Category c) => c.parentId == root.id),
      ],
      // فرع أبوه مش في القايمة بيظهر في الآخر بدل ما يختفي.
      ..._all.where(
        (Category c) =>
            !c.isRoot && !roots.any((Category r) => r.id == c.parentId),
      ),
    ];
  }

  List<Category> get roots =>
      _all.where((Category c) => c.isRoot).toList(growable: false);

  int get activeCount => _all.where((Category c) => c.isActive).length;
  int get productsCount =>
      _all.fold<int>(0, (int s, Category c) => s + c.productsCount);

  String? nameOf(String? id) {
    for (final Category c in _all) {
      if (c.id == id) return c.name;
    }
    return null;
  }

  Future<void> load() async {
    await runLoad(() async {
      _all = await _repository.fetchAll();
    });
  }

  Future<void> retry() => load();

  Future<String?> save(CategoryInput input, {Category? existing}) async {
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

  Future<String?> setActive(Category category, {required bool isActive}) async {
    final ApiException? failure = await runAction(() async {
      await _repository.update(
        category.id,
        CategoryInput(
          name: category.name,
          iconName: category.iconName,
          colorHex: hexOf(category.color),
          parentId: category.parentId,
          isActive: isActive,
        ),
      );
    });

    if (failure == null) await load();
    return failure?.message;
  }

  /// بترجّع رسالة النتيجة للمستخدم، والخطأ في [ApiException] لو فشل.
  Future<({String message, bool isError})> remove(Category category) async {
    CategoryRemoval? result;

    final ApiException? failure = await runAction(() async {
      result = await _repository.remove(category.id);
    });

    if (failure != null) return (message: failure.message, isError: true);

    await load();

    final CategoryRemoval r = result!;
    return (
      message: r.deleted
          ? 'اتمسح قسم «${category.name}»'
          : 'قسم «${category.name}» عليه ${r.productsCount} منتج، فاتعطّل بدل ما يتمسح',
      isError: false,
    );
  }

  /// اللون بصيغة #RRGGBB اللي السيرفر بيقبلها.
  static String hexOf(Color color) {
    final int argb = color.toARGB32();
    return '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }
}
