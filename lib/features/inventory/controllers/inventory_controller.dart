import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../data/inventory_repository.dart';
import '../models/stock_record.dart';
import '../models/stock_sort_column.dart';

/// حالة شاشة المخزون: الفرع والفلتر والفرز.
///
/// الفلترة والترقيم بيتعملوا على السيرفر، مش على صفحة محمّلة، عشان عدّاد
/// «الأصناف الناقصة» يبقى العدد الحقيقي مش اللي ظهر في الصفحة الأولى.
class InventoryController extends ChangeNotifier with LoadState {
  InventoryController(this._repository, {required String branchId})
      : _branchId = branchId; // ignore: prefer_initializing_formals

  final InventoryRepository _repository;

  /// المخزون دايمًا لفرع واحد — السيرفر مبيدعمش «كل الفروع».
  String _branchId;

  String get branchId => _branchId;

  List<StockRecord> _rows = <StockRecord>[];
  List<Branch> _branches = <Branch>[];
  InventorySummary _summary = (
    items: 0,
    units: 0,
    value: 0,
    retailValue: 0,
    outOfStock: 0,
    lowStock: 0,
    nearExpiry: 0,
  );
  int _total = 0;

  String? _status;
  String _query = '';
  int _sortIndex = StockSortColumn.onHand.index;
  bool _sortAscending = true;

  Timer? _searchDebounce;

  String? get status => _status;
  String get query => _query;
  int get sortIndex => _sortIndex;
  bool get sortAscending => _sortAscending;

  List<StockRecord> get rows => _rows;
  List<Branch> get branches => _branches;
  InventorySummary get summary => _summary;

  bool get canSwitchBranch => _branches.length > 1;

  /// العدد الكلي المطابق للفلتر، مش عدد الصف المعروض.
  int get visibleCount => _total;

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  double get visibleValue =>
      _rows.fold<double>(0, (double s, StockRecord r) => s + r.value);

  /// الأعداد دي على كل أصناف الفرع مش على الصفحة المعروضة.
  int get lowCount => _summary.lowStock;
  int get outCount => _summary.outOfStock;
  int get nearExpiryCount => _summary.nearExpiry;
  double get totalValue => _summary.value;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      // الفروع بتتقرا مرة واحدة، والباقي مع كل تغيير فلتر.
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchStock(
          branchId: _branchId,
          status: _status,
          search: _query.trim().isEmpty ? null : _query.trim(),
          sort: _sortKey,
          limit: 100,
        ),
        _repository.fetchSummary(_branchId),
        if (_branches.isEmpty)
          _repository.fetchBranches()
        else
          Future<List<Branch>>.value(_branches),
      ]);

      final StockPage page = results[0] as StockPage;
      _rows = page.items;
      _total = page.total;
      _summary = results[1] as InventorySummary;
      _branches = results[2] as List<Branch>;
    });
  }

  Future<void> setBranch(String? id) async {
    if (id == null || id == _branchId) return;
    _branchId = id;
    notifyListeners();
    await load();
  }

  Future<void> retry() => load();

  /// الفرز المسموح بيه على السيرفر — باقي الأعمدة بتتفرز محليًا.
  String? get _sortKey {
    final String prefix = _sortAscending ? '' : '-';

    return switch (StockSortColumn.values[_sortIndex]) {
      StockSortColumn.product => '${prefix}name',
      StockSortColumn.onHand => '${prefix}quantity',
      StockSortColumn.available => '${prefix}available',
      _ => null,
    };
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  Future<void> setStatus(String? status) async {
    if (_status == status) return;
    _status = status;
    notifyListeners();
    await load();
  }

  void setQuery(String value) {
    _query = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<void> sortBy(int columnIndex, bool ascending) async {
    _sortIndex = columnIndex;
    _sortAscending = ascending;

    // الأعمدة اللي السيرفر بيفرزها بتتطلب من جديد، والباقي بيتفرز محليًا.
    if (_sortKey != null) {
      notifyListeners();
      await load();
      return;
    }

    _rows = List<StockRecord>.from(_rows)
      ..sort((StockRecord a, StockRecord b) {
        final int result = switch (StockSortColumn.values[_sortIndex]) {
          StockSortColumn.branch => a.branchName.compareTo(b.branchName),
          StockSortColumn.reserved => a.reserved.compareTo(b.reserved),
          StockSortColumn.lastMovement =>
            a.lastMovement.compareTo(b.lastMovement),
          _ => 0,
        };
        return _sortAscending ? result : -result;
      });

    notifyListeners();
  }

  // ── تعديل الرصيد ─────────────────────────────────────────────────────────
  /// تسوية يدوية. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> adjust({
    required String productId,
    required int delta,
    String? note,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.adjust(
        productId: productId,
        branchId: _branchId,
        delta: delta,
        note: note,
      );
    });

    if (failure == null) await load();

    return failure?.message;
  }

  /// جرد. بترجّع الفرق لو نجح، و`null` لو فشل.
  Future<int?> stocktake({
    required String productId,
    required int countedQuantity,
    String? note,
  }) async {
    int? delta;

    final ApiException? failure = await runAction(() async {
      delta = await _repository.stocktake(
        productId: productId,
        branchId: _branchId,
        countedQuantity: countedQuantity,
        note: note,
      );
    });

    if (failure != null) return null;

    await load();
    return delta;
  }

  Future<String?> transfer({
    required String productId,
    required String toBranchId,
    required int quantity,
    String? note,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.transfer(
        productId: productId,
        fromBranchId: _branchId,
        toBranchId: toBranchId,
        quantity: quantity,
        note: note,
      );
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<String?> setMinStock({
    required String productId,
    required int minStock,
  }) async {
    final ApiException? failure = await runAction(() async {
      await _repository.setMinStock(
        productId: productId,
        branchId: _branchId,
        minStock: minStock,
      );
    });

    if (failure == null) await load();

    return failure?.message;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
