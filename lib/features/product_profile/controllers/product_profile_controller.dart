import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/product_branch_stock.dart';
import '../../inventory/models/stock_record.dart';
import '../../products_list/data/products_repository.dart';
import '../models/product_profile_tab.dart';

/// حالة شاشة تفاصيل المنتج: بياناته، أرصدته على الفروع، وآخر حركاته،
/// ومعاها حقول التعديل السريع اللي بتتحفظ من نفس الشاشة.
class ProductProfileController extends ChangeNotifier with LoadState {
  ProductProfileController(
    this._products,
    this._inventory, {
    required this.productId,
    required TickerProvider vsync,
  }) {
    tabController =
        TabController(length: ProductProfileTab.values.length, vsync: vsync)
          ..addListener(() {
            if (tabController.indexIsChanging) notifyListeners();
          });
  }

  final ProductsRepository _products;
  final InventoryRepository _inventory;
  final String productId;

  /// آخر حركات بتتعرض في تبويب الحركات.
  static const int _movementsLimit = 30;

  late final TabController tabController;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController barcodeController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController costController = TextEditingController();
  final TextEditingController minStockController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  Product? _product;
  List<Category> _categories = <Category>[];
  List<ProductBranchStock> _branchStock = <ProductBranchStock>[];
  List<StockMovement> _movements = <StockMovement>[];

  /// المتغيرات مش بتتعدّل من هنا، بس الحفظ بيبعتها زي ما هي عشان
  /// السيرفر بيستبدل القايمة بالكامل باللي بيوصله.
  List<ProductVariantInput> _variants = <ProductVariantInput>[];

  String? _categoryId;
  String _unit = '';

  /// آخر قيم اتحفظت — بنقارن بيها عشان نعرف إن فيه تعديل مش محفوظ.
  Map<String, String> _saved = <String, String>{};

  /// سبب رفض الحفظ من السيرفر، عشان الشاشة تعرضه جنب الزرار.
  String? saveError;

  Product? get product => _product;
  List<Category> get categories => _categories;
  List<ProductBranchStock> get branchStock => _branchStock;
  List<StockMovement> get movements => _movements;
  String? get categoryId => _categoryId;
  String get unit => _unit;

  int get currentTabIndex => tabController.index;

  /// إجمالي الرصيد على كل الفروع — الشاشة مش مقفولة على فرع واحد.
  double get totalOnHand => _branchStock.fold<double>(
    0,
    (double s, ProductBranchStock b) => s + b.quantity,
  );

  double get price => double.tryParse(priceController.text.trim()) ?? 0;
  double get cost => double.tryParse(costController.text.trim()) ?? 0;
  double get profit => price - cost;
  double get margin => price <= 0 ? 0 : (profit / price) * 100;

  /// قيمة المخزون بسعر البيع المكتوب دلوقتي.
  double get stockValue => totalOnHand * price;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      // الأربعة مستقلين، فبيتجابوا على التوازي.
      final List<Object> results = await Future.wait(<Future<Object>>[
        _products.fetchForEdit(productId),
        _products.fetchCategories(),
        _inventory.fetchBranchStock(productId),
        _inventory.fetchMovements(
          productId: productId,
          limit: _movementsLimit,
        ),
      ]);

      _categories = results[1] as List<Category>;
      _branchStock = results[2] as List<ProductBranchStock>;
      _movements = results[3] as List<StockMovement>;

      _fill(results[0] as ProductDraft);
    });
  }

  Future<void> retry() => load();

  void _fill(ProductDraft draft) {
    final Product p = draft.product;

    _product = p;
    _variants = draft.variants;
    _categoryId = p.category?.id;
    _unit = p.unit;

    nameController.text = p.name;
    skuController.text = p.sku;
    barcodeController.text = p.barcode ?? '';
    brandController.text = p.brand;
    priceController.text = _number(p.price);
    costController.text = _number(p.cost);
    minStockController.text = p.minStock.toString();
    descriptionController.text = draft.description;

    _saved = _snapshot();
    saveError = null;
  }

  /// 12.0 بتتكتب 12 عشان الخانة متبانش غريبة.
  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  Map<String, String> _snapshot() => <String, String>{
    'name': nameController.text.trim(),
    'sku': skuController.text.trim(),
    'barcode': barcodeController.text.trim(),
    'brand': brandController.text.trim(),
    'price': priceController.text.trim(),
    'cost': costController.text.trim(),
    'minStock': minStockController.text.trim(),
    'description': descriptionController.text.trim(),
    'category': _categoryId ?? '',
    'unit': _unit,
  };

  bool get isDirty {
    final Map<String, String> now = _snapshot();
    return now.keys.any((String key) => now[key] != _saved[key]);
  }

  // ── التحقق قبل الحفظ ─────────────────────────────────────────────────────
  /// سبب منع الحفظ، أو `null` لو الحقول سليمة.
  ///
  /// السيرفر بيرفض نفس الحالات دي، فبنمسكها هنا عشان المستخدم يعرف السبب
  /// من غير ما يستنى رد الشبكة.
  String? get problem {
    if (nameController.text.trim().length < 2) return 'اسم المنتج قصير جدًا';
    if (skuController.text.trim().length < 2) return 'كود المنتج قصير جدًا';
    if (_categoryId == null) return 'اختار القسم';

    final String barcode = barcodeController.text.trim();
    if (barcode.isNotEmpty && barcode.length < 4) {
      return 'الباركود لازم يكون 4 أرقام على الأقل';
    }

    if (double.tryParse(priceController.text.trim()) == null) {
      return 'اكتب سعر بيع صحيح';
    }
    if (double.tryParse(costController.text.trim()) == null) {
      return 'اكتب تكلفة صحيحة';
    }
    if (price < 0 || cost < 0) return 'السعر والتكلفة مينفعش يكونوا بالسالب';
    if (cost > price) return 'التكلفة أعلى من سعر البيع';

    return null;
  }

  bool get canSave => problem == null && isDirty && !isLoading;

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// أي تغيير في حقل نصي بيعيد بناء الأجزاء اللي بتعتمد عليه (الهامش، الأزرار).
  void fieldChanged([String? _]) => notifyListeners();

  void setCategory(String id) {
    _categoryId = id;
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    notifyListeners();
  }

  /// بيرجّع الحقول لآخر قيم محفوظة.
  void discardChanges() {
    final Product? p = _product;
    if (p == null) return;

    nameController.text = _saved['name'] ?? p.name;
    skuController.text = _saved['sku'] ?? p.sku;
    barcodeController.text = _saved['barcode'] ?? '';
    brandController.text = _saved['brand'] ?? '';
    priceController.text = _saved['price'] ?? '';
    costController.text = _saved['cost'] ?? '';
    minStockController.text = _saved['minStock'] ?? '';
    descriptionController.text = _saved['description'] ?? '';
    _categoryId = (_saved['category'] ?? '').isEmpty ? null : _saved['category'];
    _unit = _saved['unit'] ?? '';

    saveError = null;
    notifyListeners();
  }

  /// بيحفظ التعديلات على السيرفر. بيرجّع `null` لو نجح، ورسالة الخطأ لو فشل.
  Future<String?> save() async {
    final String? blocked = problem;
    if (blocked != null) {
      saveError = blocked;
      notifyListeners();
      return blocked;
    }

    saveError = null;
    final String barcode = barcodeController.text.trim();

    final ApiException? failure = await runAction(() async {
      final Product updated = await _products.update(
        productId,
        name: nameController.text.trim(),
        sku: skuController.text.trim(),
        categoryId: _categoryId!,
        price: price,
        cost: cost,
        unit: _unit,
        brand: brandController.text.trim(),
        description: descriptionController.text.trim(),
        minStock: int.tryParse(minStockController.text.trim()) ?? 0,
        // null بتشيل الباركود لو المستخدم مسحه.
        barcode: barcode.isEmpty ? null : barcode,
        variants: _variants,
      );

      // رد التعديل مفيهوش رصيد الفرع، فبنحتفظ باللي عندنا.
      _product = updated.copyWith(stock: _product?.stock);
      _saved = _snapshot();
    });

    if (failure != null) {
      // خطأ الحقل أدق من الرسالة العامة لما السيرفر يحدّده.
      saveError =
          failure.fieldErrors['sku'] ??
          failure.fieldErrors['barcode'] ??
          failure.fieldErrors['name'] ??
          failure.message;
      notifyListeners();
      return saveError;
    }

    return null;
  }

  /// تعطيل المنتج أو رجوعه للبيع. بيرجّع رسالة الخطأ لو فشل.
  Future<String?> toggleActive() async {
    final Product? current = _product;
    if (current == null) return null;

    final ApiException? failure = await runAction(() async {
      final Product updated = await _products.setActiveState(
        productId,
        isActive: !current.isActive,
      );

      _product = current.copyWith(isActive: updated.isActive);
    });

    return failure?.message;
  }

  @override
  void dispose() {
    tabController.dispose();
    nameController.dispose();
    skuController.dispose();
    barcodeController.dispose();
    brandController.dispose();
    priceController.dispose();
    costController.dispose();
    minStockController.dispose();
    descriptionController.dispose();
    super.dispose();
  }
}
