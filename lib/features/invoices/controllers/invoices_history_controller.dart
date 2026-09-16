import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/history_period.dart';
import '../data/invoices_repository.dart';
import '../models/invoice_record.dart';

/// حالة سجل الفواتير: الفترة والحالة والبحث برقم الفاتورة.
class InvoicesHistoryController extends ChangeNotifier with LoadState {
  InvoicesHistoryController(this._repository);

  final InvoicesRepository _repository;

  final TextEditingController searchController = TextEditingController();

  static const List<String> statuses = <String>[
    'completed',
    'partially_returned',
    'returned',
    'voided',
  ];

  HistoryPeriod _period = HistoryPeriod.today;
  String? _status;
  String _query = '';
  Timer? _debounce;

  List<InvoiceRecord> _rows = <InvoiceRecord>[];
  int _total = 0;
  InvoicesSummary _summary = (count: 0, total: 0, returned: 0, profit: 0);

  HistoryPeriod get period => _period;
  String? get status => _status;
  List<InvoiceRecord> get rows => _rows;
  int get totalCount => _total;
  InvoicesSummary get summary => _summary;

  double get average =>
      _summary.count == 0 ? 0 : _summary.total / _summary.count;

  Future<void> load() async {
    await runLoad(() async {
      final DateTime? from = _period.from;
      final String search = _query.trim();

      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchPage(
          from: from,
          status: _status,
          search: search.isEmpty ? null : search,
        ),
        _repository.fetchSummary(from: from),
      ]);

      final InvoicesPage page = results[0] as InvoicesPage;
      _rows = page.items;
      _total = page.total;
      _summary = results[1] as InvoicesSummary;
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

  void setQuery(String value) {
    _query = value;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), load);
  }

  Future<InvoiceRecord> details(InvoiceRecord record) =>
      _repository.fetchOne(record.id);

  /// بيلغي الفاتورة ويعيد تحميل السجل. بيرجّع الخطأ لو السيرفر رفض.
  Future<ApiException?> voidInvoice(InvoiceRecord record, String reason) async {
    final ApiException? error = await runAction(
      () => _repository.voidInvoice(record.id, reason: reason),
    );
    if (error == null) await load();
    return error;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    searchController.dispose();
    super.dispose();
  }
}
