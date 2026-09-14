import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/expense.dart';
import '../data/expenses_repository.dart';
import '../models/expenses_sort_column.dart';

/// حالة شاشة المصروفات: القائمة والفلاتر والفرز والإجماليات.
///
/// الفلترة والفرز بيتعملوا على السيرفر، والإجماليات جاية من مسار الملخّص،
/// عشان الأرقام فوق الجدول تبقى عن كل المصروفات المطابقة مش عن الصفحة.
class ExpensesController extends ChangeNotifier with LoadState {
  ExpensesController(this._repository, this._branches);

  final ExpensesRepository _repository;
  final BranchesRepository _branches;

  final TextEditingController searchController = TextEditingController();

  List<Expense> _rows = <Expense>[];
  List<Branch> _branchList = <Branch>[];
  int _total = 0;

  ExpensesSummary _summary =
      (total: 0, categories: <ExpenseCategoryTotal>[]);
  ExpensesSummary _pending =
      (total: 0, categories: <ExpenseCategoryTotal>[]);
  double _monthTotal = 0;

  String _query = '';
  String? _category;
  String? _branchId;
  ExpenseStatus? _status;
  int _sortIndex = ExpensesSortColumn.date.index;
  bool _sortAscending = false;

  Timer? _searchDebounce;

  String? get category => _category;
  String? get branchId => _branchId;
  ExpenseStatus? get status => _status;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<Expense> get rows => _rows;
  List<Branch> get branches => _branchList;

  /// بنود المصروفات اللي اتسجّلت فعلًا — مصدر قائمة الفلتر والاقتراحات.
  List<String> get categoryNames => _summary.categories
      .map((ExpenseCategoryTotal c) => c.category)
      .toList(growable: false);

  /// العدد الكلي المطابق للفلتر، مش عدد الصفوف المعروضة.
  int get visibleCount => _total;

  /// إجمالي المصروفات المطابقة للفلتر — محسوب على السيرفر.
  double get visibleTotal => _summary.total;

  double get pendingTotal => _pending.total;
  double get monthTotal => _monthTotal;

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final DateTime now = DateTime.now();
      final DateTime monthStart = DateTime(now.year, now.month);

      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchPage(
          search: _query.trim().isEmpty ? null : _query.trim(),
          category: _category,
          branchId: _branchId,
          status: _status,
          sort: _sortKey,
          limit: 100,
        ),
        // الملخّص بنفس الفلتر عشان الإجمالي تحت الجدول يطابق اللي فوقه.
        _repository.fetchSummary(branchId: _branchId, status: _status),
        _repository.fetchSummary(
          branchId: _branchId,
          status: ExpenseStatus.pending,
        ),
        _repository.fetchSummary(branchId: _branchId, from: monthStart),
        if (_branchList.isEmpty)
          _branches.fetchAll()
        else
          Future<List<Branch>>.value(_branchList),
      ]);

      final ExpensesPage page = results[0] as ExpensesPage;
      _rows = page.items;
      _total = page.total;
      _summary = results[1] as ExpensesSummary;
      _pending = results[2] as ExpensesSummary;
      _monthTotal = (results[3] as ExpensesSummary).total;
      _branchList = results[4] as List<Branch>;
    });
  }

  Future<void> retry() => load();

  /// مفتاح الفرز اللي السيرفر بيفهمه.
  ///
  /// عمود الفرع مش هنا: السيرفر بيفرز بمعرّف الفرع مش باسمه، فبيتفرز محليًا.
  String get _sortKey {
    final String prefix = _sortAscending ? '' : '-';

    return switch (ExpensesSortColumn.values[_sortIndex]) {
      ExpensesSortColumn.category => '${prefix}category',
      ExpensesSortColumn.amount => '${prefix}amount',
      ExpensesSortColumn.status => '${prefix}status',
      _ => '${prefix}date',
    };
  }

  // ── إجراءات الفلترة ──────────────────────────────────────────────────────
  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> setCategory(String? category) async {
    if (_category == category) return;
    _category = category;
    notifyListeners();
    await load();
  }

  Future<void> setBranch(String? id) async {
    if (_branchId == id) return;
    _branchId = id;
    notifyListeners();
    await load();
  }

  Future<void> setStatus(ExpenseStatus? status) async {
    if (_status == status) return;
    _status = status;
    notifyListeners();
    await load();
  }

  Future<void> sortBy(int columnIndex, bool ascending) async {
    _sortIndex = columnIndex;
    _sortAscending = ascending;

    if (ExpensesSortColumn.values[_sortIndex] == ExpensesSortColumn.branch) {
      _rows = List<Expense>.from(_rows)
        ..sort((Expense a, Expense b) {
          final int result = a.branchName.compareTo(b.branchName);
          return _sortAscending ? result : -result;
        });

      notifyListeners();
      return;
    }

    notifyListeners();
    await load();
  }

  // ── الكتابة ──────────────────────────────────────────────────────────────
  /// بيضيف المصروف للقايمة بعد ما السيرفر يقبله.
  Future<void> addCreated(Expense expense) async {
    _rows = <Expense>[expense, ..._rows];
    notifyListeners();
    // الإجماليات محسوبة على السيرفر، فبنعيد القراءة بدل ما نجمعها محليًا.
    await load();
  }

  /// اعتماد أو رفض مصروف. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> review(
    Expense expense, {
    required bool approve,
    String? reason,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.review(expense.id, approve: approve, reason: reason);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  /// مسح مصروف. السيرفر بيرفض مسح المعتمد.
  Future<String?> delete(Expense expense) async {
    final ApiException? failure = await runAction(() async {
      await _repository.delete(expense.id);
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
