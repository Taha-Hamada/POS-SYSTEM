import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/load_state.dart';
import '../../../core/models/history_period.dart';
import '../data/returns_history_repository.dart';
import '../models/return_record.dart';

typedef ReturnsPeriod = HistoryPeriod;

/// حالة سجل المرتجعات: الفترة والبحث برقم المرتجع.
class ReturnsHistoryController extends ChangeNotifier with LoadState {
  ReturnsHistoryController(this._repository);

  final ReturnsHistoryRepository _repository;

  final TextEditingController searchController = TextEditingController();

  ReturnsPeriod _period = ReturnsPeriod.month;
  String _query = '';
  Timer? _debounce;

  List<ReturnRecord> _rows = <ReturnRecord>[];
  int _total = 0;
  ReturnsSummary _summary = (count: 0, total: 0);

  ReturnsPeriod get period => _period;
  List<ReturnRecord> get rows => _rows;
  int get totalCount => _total;
  ReturnsSummary get summary => _summary;

  double get average =>
      _summary.count == 0 ? 0 : _summary.total / _summary.count;

  Future<void> load() async {
    await runLoad(() async {
      final DateTime? from = _period.from;
      final String search = _query.trim();

      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchPage(
          from: from,
          search: search.isEmpty ? null : search,
        ),
        _repository.fetchSummary(from: from),
      ]);

      final ReturnsPage page = results[0] as ReturnsPage;
      _rows = page.items;
      _total = page.total;
      _summary = results[1] as ReturnsSummary;
    });
  }

  Future<void> retry() => load();

  Future<void> setPeriod(ReturnsPeriod period) async {
    if (_period == period) return;
    _period = period;
    notifyListeners();
    await load();
  }

  void setQuery(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<ReturnRecord> details(ReturnRecord record) =>
      _repository.fetchOne(record.id);

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
