import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/purchase_order.dart';
import '../../../core/models/supplier.dart';
import '../../suppliers/data/suppliers_repository.dart';
import '../data/purchases_repository.dart';
import '../models/purchase_orders_sort_column.dart';

/// حالة شاشة أوامر الشراء: البحث، المورد، الحالة، والفرز.
///
/// الفلترة والفرز على السيرفر، والعدادات فوق الجدول جاية من مسار الملخّص
/// عشان تبقى على كل الأوامر مش على الصفحة المعروضة.
class PurchaseOrdersController extends ChangeNotifier with LoadState {
  PurchaseOrdersController(this._repository, this._suppliers);

  final PurchasesRepository _repository;
  final SuppliersRepository _suppliers;

  final TextEditingController searchController = TextEditingController();

  List<PurchaseOrder> _rows = <PurchaseOrder>[];
  List<Supplier> _supplierList = <Supplier>[];
  int _total = 0;

  PurchaseOrdersSummary _summary = (
    byStatus: <PurchaseOrderStatus, StatusTotals>{},
    awaiting: (count: 0, total: 0),
    count: 0,
    total: 0,
  );

  String _query = '';
  String? _supplierId;
  PurchaseOrderStatus? _status;
  int _sortIndex = PurchaseOrdersSortColumn.date.index;
  bool _sortAscending = false;

  Timer? _searchDebounce;

  String? get supplierId => _supplierId;
  PurchaseOrderStatus? get status => _status;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<PurchaseOrder> get rows => _rows;
  List<Supplier> get suppliers => _supplierList;

  /// العدد الكلي المطابق للفلتر، مش عدد الصفوف المعروضة.
  int get visibleCount => _total;

  double get visibleValue =>
      _rows.fold<double>(0, (double s, PurchaseOrder o) => s + o.total);

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  // ── إحصائيات أعلى الشاشة ─────────────────────────────────────────────────
  int countByStatus(PurchaseOrderStatus status) =>
      _summary.byStatus[status]?.count ?? 0;

  double valueByStatus(PurchaseOrderStatus status) =>
      _summary.byStatus[status]?.total ?? 0;

  /// المؤكد والمستلم جزئيًا — اللي لسه مستنيين بضاعة.
  int get awaitingCount => _summary.awaiting.count;
  double get awaitingValue => _summary.awaiting.total;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchPage(
          search: _query.trim().isEmpty ? null : _query.trim(),
          supplierId: _supplierId,
          status: _status,
          sort: _sortKey,
        ),
        _repository.fetchSummary(supplierId: _supplierId),
        if (_supplierList.isEmpty)
          _suppliers.fetchPage(limit: 100)
        else
          Future<SuppliersPage>.value(
            (items: _supplierList, total: _supplierList.length),
          ),
      ]);

      final PurchaseOrdersPage page = results[0] as PurchaseOrdersPage;
      _rows = page.items;
      _total = page.total;
      _summary = results[1] as PurchaseOrdersSummary;
      _supplierList = (results[2] as SuppliersPage).items;
    });
  }

  Future<void> retry() => load();

  /// مفتاح الفرز اللي السيرفر بيفهمه.
  ///
  /// عمود المورد مش هنا: السيرفر بيفرز بمعرّف المورد مش باسمه، فبيتفرز محليًا.
  String get _sortKey {
    final String prefix = _sortAscending ? '' : '-';

    return switch (PurchaseOrdersSortColumn.values[_sortIndex]) {
      PurchaseOrdersSortColumn.id => '${prefix}number',
      PurchaseOrdersSortColumn.status => '${prefix}status',
      PurchaseOrdersSortColumn.total => '${prefix}total',
      _ => '${prefix}orderDate',
    };
  }

  // ── الفلترة والفرز ───────────────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setSupplier(String? id) async {
    if (_supplierId == id) return;
    _supplierId = id;
    notifyListeners();
    await load();
  }

  Future<void> setStatus(PurchaseOrderStatus? status) async {
    if (_status == status) return;
    _status = status;
    notifyListeners();
    await load();
  }

  Future<void> sortBy(int columnIndex, bool ascending) async {
    _sortIndex = columnIndex;
    _sortAscending = ascending;

    if (PurchaseOrdersSortColumn.values[_sortIndex] ==
        PurchaseOrdersSortColumn.supplier) {
      _rows = List<PurchaseOrder>.from(_rows)
        ..sort((PurchaseOrder a, PurchaseOrder b) {
          final int result = a.supplierName.compareTo(b.supplierName);
          return _sortAscending ? result : -result;
        });

      notifyListeners();
      return;
    }

    notifyListeners();
    await load();
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────
  /// بيجيب الأمر كامل بسطوره — القايمة بترجع من غيرها.
  Future<PurchaseOrder?> fetchFullOrder(String id) async {
    PurchaseOrder? order;

    final ApiException? failure = await runAction(() async {
      order = await _repository.fetchOne(id);
    });

    return failure == null ? order : null;
  }

  /// تأكيد الأمر بيقفل باب التعديل ويخليه جاهز للاستلام.
  Future<String?> confirm(PurchaseOrder order) async {
    final ApiException? failure = await runAction(() async {
      await _repository.confirm(order.id);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  /// الإلغاء بيترفض لو دخل من الأمر بضاعة.
  Future<String?> cancel(PurchaseOrder order, {required String reason}) async {
    final ApiException? failure = await runAction(() async {
      await _repository.cancel(order.id, reason: reason);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<void> refreshAfterReceipt() => load();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
