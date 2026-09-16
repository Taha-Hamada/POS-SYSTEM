import 'package:flutter/foundation.dart';

import '../../../core/api/load_state.dart';
import '../../../core/models/history_period.dart';
import '../../../core/models/shift.dart';
import '../data/shift_repository.dart';

/// حالة سجل الورديات: الفترة والحالة.
class ShiftsHistoryController extends ChangeNotifier with LoadState {
  ShiftsHistoryController(this._repository);

  final ShiftRepository _repository;

  HistoryPeriod _period = HistoryPeriod.week;
  String? _status;

  List<Shift> _rows = <Shift>[];
  int _total = 0;

  HistoryPeriod get period => _period;
  String? get status => _status;
  List<Shift> get rows => _rows;
  int get totalCount => _total;

  List<Shift> get _closed =>
      _rows.where((Shift s) => s.closing != null).toList(growable: false);

  int get openCount => _rows.where((Shift s) => s.isOpen).length;

  /// إجماليات الصفحة المعروضة من أرقام التقفيل المتجمّدة.
  double get closedSales => _closed.fold<double>(
    0,
    (double sum, Shift s) => sum + s.closing!.salesTotal,
  );

  double get netDifference => _closed.fold<double>(
    0,
    (double sum, Shift s) => sum + s.closing!.difference,
  );

  int get shortCount => _closed.where((Shift s) => s.closing!.isShort).length;

  Future<void> load() async {
    await runLoad(() async {
      final ({List<Shift> items, int total}) page = await _repository.fetchPage(
        from: _period.from,
        status: _status,
      );
      _rows = page.items;
      _total = page.total;
    });
  }

  Future<void> retry() => load();

  Future<void> setPeriod(HistoryPeriod period) async {
    if (_period == period) return;
    _period = period;
    notifyListeners();
    await load();
  }

  Future<void> setStatus(String? status) async {
    if (_status == status) return;
    _status = status;
    notifyListeners();
    await load();
  }

  /// الوردية بأرقامها — للمفتوحة لحظية، وللمقفولة محسوبة وقت الطلب.
  Future<ShiftSnapshot> details(Shift shift) => _repository.fetchById(shift.id);
}
