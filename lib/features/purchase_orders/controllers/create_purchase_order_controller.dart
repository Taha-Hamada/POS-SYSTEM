import 'dart:collection';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/product.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../products_list/data/products_repository.dart';
import '../../suppliers/data/suppliers_repository.dart';
import '../../suppliers/models/supplied_product.dart';
import '../data/purchases_repository.dart';
import '../models/draft_order_line.dart';

/// حالة أمر الشراء الجديد: المورد، فرع الاستلام، والأصناف المطلوبة.
///
/// أمر الشراء مالوش ضريبة على السيرفر — إجماليه = قيمة الأصناف + الشحن،
/// والشحن بيتوزّع على التكلفة وقت الاستلام.
class CreatePurchaseOrderController extends ChangeNotifier with LoadState {
  CreatePurchaseOrderController(
    this._repository,
    this._suppliers,
    this._products,
    this._branches, {
    String? branchId,
  }) : _branchId = branchId; // ignore: prefer_initializing_formals

  final PurchasesRepository _repository;
  final SuppliersRepository _suppliers;
  final ProductsRepository _products;
  final BranchesRepository _branches;

  /// الكمية المبدئية لأي صنف بيتضاف.
  static const int _defaultQuantity = 10;

  final TextEditingController shippingController =
      TextEditingController(text: '0');
  final TextEditingController noteController = TextEditingController();

  String? _supplierId;
  String? _branchId;
  DateTime? _expectedDate;

  final List<DraftOrderLine> _lines = <DraftOrderLine>[];

  List<Supplier> _supplierList = <Supplier>[];
  List<Branch> _branchList = <Branch>[];
  List<Product> _catalog = <Product>[];

  String? saveError;

  String? get supplierId => _supplierId;
  String? get branchId => _branchId;
  DateTime? get expectedDate => _expectedDate;

  List<Supplier> get suppliers => _supplierList;
  List<Branch> get branches => _branchList;

  /// كل المنتجات — نافذة اختيار الأصناف بتقرا منها.
  List<Product> get catalog => _catalog;

  UnmodifiableListView<DraftOrderLine> get lines =>
      UnmodifiableListView<DraftOrderLine>(_lines);

  Supplier? get supplier => _supplierList
      .where((Supplier s) => s.id == _supplierId)
      .firstOrNull;

  bool get hasLines => _lines.isNotEmpty;
  bool get canSwitchBranch => _branchList.length > 1;

  // ── الإجماليات ───────────────────────────────────────────────────────────
  double get subtotal =>
      _lines.fold<double>(0, (double s, DraftOrderLine l) => s + l.total);

  double get shippingCost =>
      double.tryParse(shippingController.text.trim()) ?? 0;

  double get total => subtotal + shippingCost;

  int get totalUnits =>
      _lines.fold<int>(0, (int s, DraftOrderLine l) => s + l.quantity);

  /// المنتجات المضافة بالفعل — عشان ما تتكررش في نافذة الاختيار.
  Set<String> get pickedProductIds =>
      _lines.map((DraftOrderLine l) => l.productId).toSet();

  /// السيرفر بيرفض الأمر من غير مورد أو من غير أصناف أو بكمية صفر.
  bool get canSubmit =>
      hasLines &&
      _supplierId != null &&
      _branchId != null &&
      !isLoading &&
      _lines.every((DraftOrderLine l) => l.quantity > 0);

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        // الموردين المعطلين مبينفعش يتعمل لهم أمر، فمش بيظهروا.
        _suppliers.fetchPage(isActive: true, limit: 100),
        _branches.fetchAll(),
        _products.fetchAll(),
      ]);

      _supplierList = (results[0] as SuppliersPage).items;
      _branchList = results[1] as List<Branch>;
      _catalog = results[2] as List<Product>;

      _supplierId ??= _supplierList.isEmpty ? null : _supplierList.first.id;
      _branchId ??= _branchList.isEmpty ? null : _branchList.first.id;
    });
  }

  Future<void> retry() => load();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setSupplier(String? id) {
    if (id == null) return;
    _supplierId = id;
    notifyListeners();
  }

  void setBranch(String? id) {
    if (id == null) return;
    _branchId = id;
    notifyListeners();
  }

  void setExpectedDate(DateTime? date) {
    _expectedDate = date;
    notifyListeners();
  }

  void fieldChanged([String? _]) => notifyListeners();

  void addProduct(Product product) {
    if (pickedProductIds.contains(product.id)) return;

    _lines.add(
      DraftOrderLine(
        productId: product.id,
        name: product.name,
        sku: product.sku,
        unit: product.unit,
        stock: product.stock,
        quantity: _defaultQuantity,
        unitCost: product.cost,
      ),
    );

    notifyListeners();
  }

  /// بيضيف الأصناف اللي المورد ده وردها قبل كده بآخر سعر اتدفع فيه.
  ///
  /// بترجّع عدد الأصناف اللي اتضافت، أو رسالة الخطأ.
  Future<({int added, String? error})> addSupplierCatalog() async {
    final String? id = _supplierId;
    if (id == null) return (added: 0, error: 'اختر المورد الأول');

    List<SuppliedProduct> supplied = <SuppliedProduct>[];

    final ApiException? failure = await runAction(() async {
      supplied = await _suppliers.fetchSuppliedProducts(id);
    });

    if (failure != null) return (added: 0, error: failure.message);

    final Set<String> existing = pickedProductIds;
    int added = 0;

    for (final SuppliedProduct p in supplied) {
      if (existing.contains(p.id)) continue;

      _lines.add(
        DraftOrderLine(
          productId: p.id,
          name: p.name,
          sku: p.sku,
          unit: p.unit,
          stock: p.stock,
          quantity: _defaultQuantity,
          // آخر سعر اتدفع للمورد ده أقرب لسعر النهارده من متوسط التكلفة.
          unitCost: p.lastUnitCost > 0 ? p.lastUnitCost : p.cost,
        ),
      );

      added += 1;
    }

    notifyListeners();
    return (added: added, error: null);
  }

  void removeLineAt(int index) {
    _lines.removeAt(index);
    notifyListeners();
  }

  void setQuantity(DraftOrderLine line, int quantity) {
    line.quantity = quantity < 0 ? 0 : quantity;
    notifyListeners();
  }

  void setUnitCost(DraftOrderLine line, double cost) {
    line.unitCost = cost < 0 ? 0 : cost;
    notifyListeners();
  }

  /// بينشئ الأمر على السيرفر، وبيأكده كمان لو [confirm] اتبعت.
  ///
  /// بيرجّع الأمر لو نجح، و`null` لو فشل و[saveError] بيحمل السبب.
  Future<PurchaseOrder?> submit({bool confirm = false}) async {
    saveError = null;

    PurchaseOrder? created;

    final ApiException? failure = await runAction(() async {
      created = await _repository.create(
        supplierId: _supplierId!,
        branchId: _branchId,
        expectedDate: _expectedDate,
        shippingCost: shippingCost,
        note: noteController.text.trim(),
        lines: <PurchaseLineInput>[
          for (final DraftOrderLine l in _lines)
            (
              productId: l.productId,
              quantity: l.quantity.toDouble(),
              unitCost: l.unitCost,
            ),
        ],
      );

      // التأكيد بيقفل باب التعديل، فبيتعمل بعد ما الأمر يتخزّن بنجاح.
      if (confirm) created = await _repository.confirm(created!.id);
    });

    if (failure != null) {
      saveError = failure.message;
      notifyListeners();
      return null;
    }

    return created;
  }

  @override
  void dispose() {
    shippingController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
