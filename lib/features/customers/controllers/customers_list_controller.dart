import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/customer.dart';
import '../data/customers_repository.dart';
import '../models/customers_sort_column.dart';

/// حالة شاشة العملاء: البحث، المجموعة، فلتر المدينين، والفرز.
///
/// العملاء بيتجابوا مرة واحدة، والفلترة والفرز محليًا عشان البطاقات
/// تعرض إجماليات على الكل مش على الصفحة المعروضة.
class CustomersListController extends ChangeNotifier with LoadState {
  CustomersListController(this._repository);

  final CustomersRepository _repository;

  final TextEditingController searchController = TextEditingController();

  List<Customer> _all = <Customer>[];
  String _query = '';
  bool _onlyDebtors = false;
  int _sortIndex = 0;
  bool _sortAscending = true;

  Timer? _searchDebounce;
  List<Customer>? _cachedRows;

  bool get onlyDebtors => _onlyDebtors;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<Customer> get allCustomers => _all;
  List<Customer> get rows => _cachedRows ??= _computeRows();

  int get visibleCount => rows.length;
  bool get isEmpty => !isLoading && !hasFailed && _all.isEmpty;

  double get visibleBalance =>
      rows.fold<double>(0, (double s, Customer c) => s + c.balance);

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      _all = await _repository.fetchAll();
      _cachedRows = null;
    });
  }

  Future<void> retry() => load();

  // ── إحصائيات ─────────────────────────────────────────────────────────────
  double get totalDebt => _all
      .where((Customer c) => c.balance < 0)
      .fold<double>(0, (double s, Customer c) => s + c.balance.abs());

  double get totalPurchases =>
      _all.fold<double>(0, (double s, Customer c) => s + c.totalPurchases);

  // ── الفلترة والفرز ───────────────────────────────────────────────────────
  List<Customer> _computeRows() {
    final String q = _query.trim().toLowerCase();

    final List<Customer> list = _all.where((Customer c) {
      if (_onlyDebtors && c.balance >= 0) return false;
      if (q.isEmpty) return true;

      return c.name.toLowerCase().contains(q) ||
          c.phone.contains(q) ||
          (c.email?.toLowerCase().contains(q) ?? false);
    }).toList();

    final CustomersSortColumn column = CustomersSortColumn.values[_sortIndex];
    list.sort((Customer a, Customer b) {
      final int result = switch (column) {
        CustomersSortColumn.name => a.name.compareTo(b.name),
        CustomersSortColumn.phone => a.phone.compareTo(b.phone),
        CustomersSortColumn.balance => a.balance.compareTo(b.balance),
        // العميل اللي عمره ما جه بيتحط في الآخر بدل ما يتصدّر.
        CustomersSortColumn.lastVisit => (a.lastVisitAt ?? DateTime(1970))
            .compareTo(b.lastVisitAt ?? DateTime(1970)),
      };
      return _sortAscending ? result : -result;
    });

    return list;
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 200), _refresh);
  }

  void toggleOnlyDebtors() {
    _onlyDebtors = !_onlyDebtors;
    _refresh();
  }

  void sortBy(int columnIndex, bool ascending) {
    _sortIndex = columnIndex;
    _sortAscending = ascending;
    _refresh();
  }

  /// إضافة عميل جديد. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> addCustomer({
    required String name,
    required String phone,
    String? email,
    double? creditLimit,
  }) async {
    final ApiException? failure = await runAction(() async {
      final Customer created = await _repository.create(
        name: name,
        phone: phone,
        email: email,
        creditLimit: creditLimit,
      );

      _all = <Customer>[created, ..._all];
      _cachedRows = null;
    });

    // خطأ الحقل أدق من الرسالة العامة لما السيرفر يحدّده.
    return failure == null
        ? null
        : failure.fieldErrors['phone'] ?? failure.message;
  }

  /// بتتنادى بعد أي تعديل على عميل من شاشة الملف.
  void replace(Customer customer) {
    final int index = _all.indexWhere((Customer c) => c.id == customer.id);
    if (index < 0) return;

    _all[index] = customer;
    _refresh();
  }

  void _refresh() {
    _cachedRows = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
