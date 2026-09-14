import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/supplier.dart';
import '../data/suppliers_repository.dart';
import '../models/supplier_filter.dart';
import '../models/suppliers_sort_column.dart';

/// حالة شاشة الموردين: البحث، الفلتر، والفرز.
///
/// البحث والفلترة والفرز على السيرفر، وإجمالي المستحقات جاي من مسار
/// `payables` عشان يبقى على كل الموردين مش على الصفحة المعروضة.
class SuppliersListController extends ChangeNotifier with LoadState {
  SuppliersListController(this._repository);

  final SuppliersRepository _repository;

  final TextEditingController searchController = TextEditingController();

  List<Supplier> _rows = <Supplier>[];
  int _total = 0;
  PayablesSummary _payables = (total: 0, count: 0);
  int _activeCount = 0;

  String _query = '';
  SupplierFilter _filter = SupplierFilter.all;
  int _sortIndex = SuppliersSortColumn.name.index;
  bool _sortAscending = true;

  Timer? _searchDebounce;

  SupplierFilter get filter => _filter;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<Supplier> get rows => _rows;

  /// العدد الكلي المطابق للفلتر، مش عدد الصفوف المعروضة.
  int get visibleCount => _total;

  double get visibleDue =>
      _rows.fold<double>(0, (double s, Supplier x) => s + x.balanceDue);

  /// إجمالي المستحق على كل الموردين — محسوب على السيرفر.
  double get totalDue => _payables.total;
  int get dueSuppliersCount => _payables.count;
  int get activeCount => _activeCount;

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchPage(
          search: _query.trim().isEmpty ? null : _query.trim(),
          isActive: _activeFilter,
          hasDue: _filter == SupplierFilter.due,
          sort: _sortKey,
        ),
        _repository.fetchPayables(),
        // عدّاد النشطين على كل الموردين مش على الفلتر الحالي.
        _repository.fetchPage(isActive: true, limit: 1),
      ]);

      final SuppliersPage page = results[0] as SuppliersPage;
      _rows = page.items;
      _total = page.total;
      _payables = results[1] as PayablesSummary;
      _activeCount = (results[2] as SuppliersPage).total;
    });
  }

  Future<void> retry() => load();

  bool? get _activeFilter => switch (_filter) {
        SupplierFilter.active => true,
        SupplierFilter.inactive => false,
        _ => null,
      };

  /// مفتاح الفرز اللي السيرفر بيفهمه.
  String get _sortKey {
    final String prefix = _sortAscending ? '' : '-';

    return switch (SuppliersSortColumn.values[_sortIndex]) {
      SuppliersSortColumn.contact => '${prefix}contactPerson',
      SuppliersSortColumn.phone => '${prefix}phone',
      SuppliersSortColumn.balance => '${prefix}balanceDue',
      SuppliersSortColumn.orders => '${prefix}ordersCount',
      _ => '${prefix}name',
    };
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setFilter(SupplierFilter filter) async {
    if (_filter == filter) return;
    _filter = filter;
    notifyListeners();
    await load();
  }

  Future<void> sortBy(int columnIndex, bool ascending) async {
    _sortIndex = columnIndex;
    _sortAscending = ascending;
    notifyListeners();
    await load();
  }

  /// بيضيف المورد للقايمة بعد ما السيرفر يقبله.
  Future<void> addCreated(Supplier supplier) async {
    _rows = <Supplier>[supplier, ..._rows];
    notifyListeners();
    await load();
  }

  /// تفعيل أو تعطيل مورد. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> setActiveState(
    Supplier supplier, {
    required bool isActive,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.setActiveState(supplier.id, isActive: isActive);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
