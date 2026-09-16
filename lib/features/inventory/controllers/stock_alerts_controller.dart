import 'package:flutter/foundation.dart';

import '../../../core/api/load_state.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../data/stock_alerts_repository.dart';

/// حالة شاشة تنبيهات المخزون.
class StockAlertsController extends ChangeNotifier with LoadState {
  StockAlertsController(this._repository, this._branches, {String? branchId})
    // ignore: prefer_initializing_formals
    : _branchId = branchId;

  final StockAlertsRepository _repository;
  final BranchesRepository _branches;

  /// الفترات المتاحة لقرب انتهاء الصلاحية.
  static const List<int> dayOptions = <int>[7, 30, 60, 90];

  List<LowStockAlert> _lowStock = <LowStockAlert>[];
  List<ExpiringProduct> _expiring = <ExpiringProduct>[];
  List<Branch> _branchList = <Branch>[];

  /// null = كل الفروع.
  String? _branchId;
  int _days = 30;

  List<LowStockAlert> get lowStock => _lowStock;
  List<ExpiringProduct> get expiring => _expiring;
  List<Branch> get branches => _branchList;
  String? get branchId => _branchId;
  int get days => _days;

  int get outOfStockCount =>
      _lowStock.where((LowStockAlert a) => a.isOut).length;
  int get belowMinCount => _lowStock.length - outOfStockCount;
  int get expiredCount =>
      _expiring.where((ExpiringProduct p) => p.isExpired).length;
  int get expiringSoonCount => _expiring.length - expiredCount;

  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchLowStock(branchId: _branchId),
        _repository.fetchExpiring(days: _days),
        if (_branchList.isEmpty)
          _branches.fetchAll()
        else
          Future<List<Branch>>.value(_branchList),
      ]);

      _lowStock = results[0] as List<LowStockAlert>;
      _expiring = results[1] as List<ExpiringProduct>;
      _branchList = results[2] as List<Branch>;
    });
  }

  Future<void> retry() => load();

  Future<void> setBranch(String? id) async {
    if (_branchId == id) return;
    _branchId = id;
    notifyListeners();
    await load();
  }

  Future<void> setDays(int days) async {
    if (_days == days) return;
    _days = days;
    notifyListeners();
    await load();
  }
}
