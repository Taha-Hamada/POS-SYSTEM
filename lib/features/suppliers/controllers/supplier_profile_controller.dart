import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../purchase_orders/data/purchases_repository.dart';
import '../data/suppliers_repository.dart';
import '../models/supplied_product.dart';
import '../models/supplier_profile_tab.dart';

/// حالة ملف المورد: بياناته وأصنافه وأوامره والتبويب المفتوح.
class SupplierProfileController extends ChangeNotifier with LoadState {
  SupplierProfileController(
    this._repository,
    this._purchases, {
    required this.supplierId,
    required TickerProvider vsync,
  }) {
    tabController = TabController(
      length: SupplierProfileTab.values.length,
      vsync: vsync,
    )..addListener(() {
        if (tabController.indexIsChanging) notifyListeners();
      });
  }

  final SuppliersRepository _repository;
  final PurchasesRepository _purchases;
  final String supplierId;

  late final TabController tabController;

  Supplier? _supplier;
  List<SuppliedProduct> _products = <SuppliedProduct>[];
  List<PurchaseOrder> _orders = <PurchaseOrder>[];

  Supplier? get supplier => _supplier;
  List<SuppliedProduct> get products => _products;
  List<PurchaseOrder> get orders => _orders;

  int get currentTabIndex => tabController.index;

  /// المورد اتمسح أو المعرّف غلط.
  bool get notFound => !isLoading && _supplier == null && failure?.isNotFound == true;

  double get ordersTotal =>
      _orders.fold<double>(0, (double s, PurchaseOrder o) => s + o.total);

  /// متوسط الهامش على أصناف المورد، محسوب بآخر سعر شراء منه.
  double get averageMargin {
    if (_products.isEmpty) return 0;

    final double sum = _products.fold<double>(
      0,
      (double s, SuppliedProduct p) => s + p.profitMargin,
    );

    return sum / _products.length;
  }

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchOne(supplierId),
        _repository.fetchSuppliedProducts(supplierId),
        _purchases.fetchPage(supplierId: supplierId, limit: 100),
      ]);

      _supplier = results[0] as Supplier;
      _products = results[1] as List<SuppliedProduct>;
      _orders = (results[2] as PurchaseOrdersPage).items;
    });
  }

  Future<void> retry() => load();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  /// سداد دفعة من المستحق. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> pay({required double amount, String? note}) async {
    final ApiException? failure = await runAction(() async {
      _supplier = await _repository.pay(supplierId, amount: amount, note: note);
    });

    if (failure == null) {
      notifyListeners();
      return null;
    }

    return failure.message;
  }

  /// تفعيل أو تعطيل المورد. السيرفر بيرفض تعطيل مورد عليه مستحقات.
  Future<String?> setActiveState({required bool isActive}) async {
    final ApiException? failure = await runAction(() async {
      _supplier =
          await _repository.setActiveState(supplierId, isActive: isActive);
    });

    if (failure == null) {
      notifyListeners();
      return null;
    }

    return failure.message;
  }

  void goToTab(SupplierProfileTab tab) => tabController.animateTo(tab.index);

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
