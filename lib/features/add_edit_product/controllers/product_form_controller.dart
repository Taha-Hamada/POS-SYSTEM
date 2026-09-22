import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/category.dart';
import '../../../core/models/product.dart';
import '../../products_list/data/products_repository.dart';
import '../models/product_form_tab.dart';
import '../models/product_variant.dart';

/// حالة نموذج المنتج كامل: كل الحقول + التبويب المفتوح.
class ProductFormController extends ChangeNotifier with LoadState {
  ProductFormController(
    this._repository, {
    required TickerProvider vsync,
    this.branchId,
    this.productId,
  }) {
    tabController =
        TabController(length: ProductFormTab.values.length, vsync: vsync)
          ..addListener(() {
            if (tabController.indexIsChanging) notifyListeners();
          });
  }

  final ProductsRepository _repository;

  /// فرع الرصيد الافتتاحي — فرع المستخدم.
  final String? branchId;

  /// المنتج اللي بيتعدّل، أو null لو بنضيف منتج جديد.
  final String? productId;

  bool get isEditing => productId != null;

  /// الوحدات المتاحة في تبويب المخزون
  static const List<String> units = <String>[
    'قطعة',
    'كيس',
    'علبة',
    'كرتونة',
    'زجاجة',
    'كيلو',
    'شريط',
  ];

  late final TabController tabController;

  // ── بيانات أساسية ────────────────────────────────────────────────────────
  final TextEditingController nameController = TextEditingController();
  final TextEditingController skuController = TextEditingController();
  final TextEditingController brandController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();

  List<Category> _categories = <Category>[];
  String? _categoryId;

  // ── التسعير ──────────────────────────────────────────────────────────────
  final TextEditingController costController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController cartonPriceController = TextEditingController(
    text: '0',
  );
  final TextEditingController piecesPerCartonController = TextEditingController(
    text: '1',
  );

  // ── المتغيرات ────────────────────────────────────────────────────────────
  final List<ProductVariant> _variants = <ProductVariant>[ProductVariant()];

  // ── المخزون ──────────────────────────────────────────────────────────────
  final TextEditingController reorderController = TextEditingController(
    text: '10',
  );
  final TextEditingController openingStockController = TextEditingController(
    text: '0',
  );
  String _unit = 'قطعة';

  // ── الباركود ─────────────────────────────────────────────────────────────
  String _barcode = '';

  // ── الصورة ───────────────────────────────────────────────────────────────
  static const int maxImageBytes = 2 * 1024 * 1024;

  /// الصورة المحفوظة على السيرفر (مسار نسبي).
  String? _imageUrl;

  /// صورة اتختارت ولسه ماترفعتش — بترتفع بعد حفظ المنتج.
  ({Uint8List bytes, String name})? _pendingImage;

  /// المستخدم شال الصورة المحفوظة.
  bool _removeImage = false;

  /// سبب رفض الصورة، أو تنبيه إن المنتج اتحفظ والصورة فشلت.
  String? imageError;

  String? get imageUrl => _removeImage ? null : _imageUrl;
  ({Uint8List bytes, String name})? get pendingImage => _pendingImage;
  bool get hasImage => _pendingImage != null || imageUrl != null;

  /// بيختار صورة جديدة. بيرجّع سبب الرفض لو فيه.
  String? setImage(Uint8List bytes, String name) {
    final String lower = name.toLowerCase();
    final bool allowed = <String>[
      '.png',
      '.jpg',
      '.jpeg',
      '.webp',
    ].any(lower.endsWith);

    imageError = !allowed
        ? 'الصورة لازم تكون PNG أو JPG أو WEBP'
        : bytes.length > maxImageBytes
        ? 'الصورة أكبر من 2 ميجابايت'
        : null;

    if (imageError == null) {
      _pendingImage = (bytes: bytes, name: name);
      _removeImage = false;
    }
    notifyListeners();
    return imageError;
  }

  void clearImage() {
    _pendingImage = null;
    _removeImage = _imageUrl != null;
    imageError = null;
    notifyListeners();
  }

  List<Category> get categories => _categories;
  String? get categoryId => _categoryId;
  String get unit => _unit;
  String get barcode => _barcode;

  List<ProductVariant> get variants =>
      List<ProductVariant>.unmodifiable(_variants);

  int get currentTabIndex => tabController.index;

  /// الأقسام لازم تتحمّل قبل ما الفورم يقدر يحفظ، ومعاها المنتج لو تعديل.
  Future<void> load() async {
    await runLoad(() async {
      final String? id = productId;

      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchCategories(),
        if (id != null) _repository.fetchForEdit(id),
      ]);

      _categories = results[0] as List<Category>;
      if (id != null) _fill(results[1] as ProductDraft);
      _categoryId ??= _categories.isEmpty ? null : _categories.first.id;
    });
  }

  void _fill(ProductDraft draft) {
    final Product p = draft.product;

    nameController.text = p.name;
    skuController.text = p.sku;
    brandController.text = p.brand;
    descriptionController.text = draft.description;
    costController.text = _number(p.cost);
    priceController.text = _number(p.price);
    cartonPriceController.text = p.cartonPrice == null ? '0' : _number(p.cartonPrice!);
    piecesPerCartonController.text = p.piecesPerCarton <= 1 ? '1' : p.piecesPerCarton.toString();
    reorderController.text = p.minStock.toString();
    _categoryId = p.category?.id;
    _barcode = p.barcode ?? '';
    _imageUrl = p.imageUrl;

    // وحدة مش في القايمة بتتضاف عشان متتغيرش لوحدها مع الحفظ.
    _unit = p.unit.isEmpty ? _unit : p.unit;

    _variants
      ..clear()
      ..addAll(
        draft.variants.map(
          (ProductVariantInput v) => ProductVariant(
            size: v.size,
            color: v.color,
            sku: v.sku,
            price: v.priceOverride == null ? '' : _number(v.priceOverride!),
          ),
        ),
      );
    if (_variants.isEmpty) _variants.add(ProductVariant());
  }

  /// 12.0 بتتكتب 12 عشان الخانة متبانش غريبة.
  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  /// الوحدات المعروضة، ومعاها وحدة المنتج لو مش من القايمة الثابتة.
  List<String> get unitOptions =>
      units.contains(_unit) ? units : <String>[...units, _unit];

  Future<void> retry() => load();

  // ── حسابات التسعير ───────────────────────────────────────────────────────
  double get cost => double.tryParse(costController.text.trim()) ?? 0;
  double get price => double.tryParse(priceController.text.trim()) ?? 0;
  double get cartonPrice => double.tryParse(cartonPriceController.text.trim()) ?? 0;
  int get piecesPerCarton =>
      int.tryParse(piecesPerCartonController.text.trim()) ?? 1;
  double get profit => price - cost;
  double get margin => price <= 0 ? 0 : (profit / price) * 100;
  bool get hasPricing => cost > 0 && price > 0;
  bool get isLoss => hasPricing && profit < 0;

  // ── حالة الحفظ ───────────────────────────────────────────────────────────
  String get productName => nameController.text.trim();
  String get sku => skuController.text.trim();

  bool get hasName => productName.isNotEmpty;
  bool get hasSku => sku.isNotEmpty;

  /// السيرفر بيرفض السعر الأقل من التكلفة، فبنمنعه من هنا.
  bool get canSave =>
      hasName && hasSku && _categoryId != null && !isLoss && !isLoading;

  /// نص التنبيه في تبويب المخزون
  String get reorderPoint => reorderController.text.trim().isEmpty
      ? '0'
      : reorderController.text.trim();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// أي تغيير في حقل نصي بيعيد بناء الأجزاء اللي بتعتمد عليه.
  void fieldChanged([String? _]) => notifyListeners();

  void setCategory(String id) {
    _categoryId = id;
    notifyListeners();
  }

  void setUnit(String unit) {
    _unit = unit;
    notifyListeners();
  }

  void addVariant() {
    _variants.add(ProductVariant());
    notifyListeners();
  }

  void removeVariantAt(int index) {
    _variants.removeAt(index);
    notifyListeners();
  }

  void generateBarcode() {
    final int suffix = DateTime.now().millisecondsSinceEpoch.remainder(
      10000000,
    );
    _barcode = '622103${suffix.toString().padLeft(7, '0')}';
    notifyListeners();
  }

  void ensureBarcode() {
    if (_barcode.trim().isEmpty) {
      generateBarcode();
    }
  }

  void goToTab(ProductFormTab tab) => tabController.animateTo(tab.index);

  /// بيحفظ المنتج على السيرفر. بيرجّع المنتج لو نجح، و`null` لو فشل.
  ///
  /// [saveError] بيحمل السبب عشان الشاشة تعرضه.
  String? saveError;

  Future<Product?> save() async {
    saveError = null;

    Product? created;

    ensureBarcode();

    // الصفوف الفاضية موجودة عشان المستخدم يكتب فيها، مش عشان تتبعت.
    final List<ProductVariantInput> variantInputs = _variants
        .where((ProductVariant v) => !v.isEmpty)
        .map((ProductVariant v) => v.toInput())
        .toList(growable: false);

    final ApiException? failure = await runAction(() async {
      final String? id = productId;

      if (id != null) {
        created = await _repository.update(
          id,
          name: productName,
          sku: sku,
          categoryId: _categoryId!,
          price: price,
          cost: cost,
          unit: _unit,
          brand: brandController.text.trim(),
          description: descriptionController.text.trim(),
          cartonPrice: cartonPrice > 0 ? cartonPrice : null,
          piecesPerCarton: piecesPerCarton > 0 ? piecesPerCarton : 1,
          barcode: _barcode.isEmpty ? null : _barcode,
          minStock: int.tryParse(reorderController.text.trim()) ?? 0,
          variants: variantInputs,
        );
        return;
      }

      created = await _repository.create(
        name: productName,
        sku: sku,
        categoryId: _categoryId!,
        price: price,
        cost: cost,
        cartonPrice: cartonPrice > 0 ? cartonPrice : null,
        piecesPerCarton: piecesPerCarton > 0 ? piecesPerCarton : 1,
        unit: _unit,
        brand: brandController.text.trim(),
        description: descriptionController.text.trim(),
        barcode: _barcode.isEmpty ? null : _barcode,
        minStock: int.tryParse(reorderController.text.trim()) ?? 0,
        openingStock: int.tryParse(openingStockController.text.trim()) ?? 0,
        branchId: branchId,
        variants: variantInputs,
      );
    });

    if (failure != null) {
      // خطأ الحقل أدق من الرسالة العامة لما السيرفر يحدّده.
      saveError =
          failure.fieldErrors['sku'] ??
          failure.fieldErrors['barcode'] ??
          failure.fieldErrors['name'] ??
          failure.message;
      notifyListeners();
      return null;
    }

    return _syncImage(created!);
  }

  /// الصورة بترتفع بعد ما المنتج يتحفظ (المنتج الجديد مالوش معرّف قبلها).
  ///
  /// فشل الصورة مبيلغيش الحفظ: المنتج اتسجل فعلًا، وإعادة الحفظ كانت
  /// هتعمل منتج مكرر. فبنرجّع المنتج ومعاه تنبيه.
  Future<Product> _syncImage(Product saved) async {
    final ({Uint8List bytes, String name})? pending = _pendingImage;

    try {
      if (pending != null) {
        final Product withImage = await _repository.uploadImage(
          saved.id,
          bytes: pending.bytes,
          filename: pending.name,
        );
        _pendingImage = null;
        _imageUrl = withImage.imageUrl;
        return withImage;
      }

      if (_removeImage && _imageUrl != null) {
        final Product cleared = await _repository.removeImage(saved.id);
        _removeImage = false;
        _imageUrl = null;
        return cleared;
      }
    } on ApiException catch (exception) {
      imageError = 'اتحفظ المنتج بس الصورة ماترفعتش: ${exception.message}';
      notifyListeners();
    }

    return saved;
  }

  @override
  void dispose() {
    tabController.dispose();
    nameController.dispose();
    skuController.dispose();
    brandController.dispose();
    descriptionController.dispose();
    costController.dispose();
    priceController.dispose();
    cartonPriceController.dispose();
    piecesPerCartonController.dispose();
    reorderController.dispose();
    openingStockController.dispose();
    super.dispose();
  }
}
