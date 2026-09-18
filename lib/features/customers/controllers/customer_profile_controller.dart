import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/customer.dart';
import '../data/customers_repository.dart';
import '../models/customer_entries.dart';
import '../models/customer_profile_tab.dart';

/// حالة ملف العميل: التبويب المفتوح، وبياناته الجاية من السيرفر.
class CustomerProfileController extends ChangeNotifier with LoadState {
  CustomerProfileController(
    this._repository, {
    required this.customerId,
    required TickerProvider vsync,
  }) {
    tabController = TabController(
      length: CustomerProfileTab.values.length,
      vsync: vsync,
    )..addListener(() {
        if (tabController.indexIsChanging) notifyListeners();
      });
  }

  final CustomersRepository _repository;
  final String customerId;

  late final TabController tabController;

  Customer? _customer;
  List<CustomerInvoice> _invoices = <CustomerInvoice>[];
  List<LedgerEntry> _ledger = <LedgerEntry>[];

  int get currentTabIndex => tabController.index;

  Customer? get customer => _customer;
  List<CustomerInvoice> get invoices => _invoices;
  List<LedgerEntry> get ledger => _ledger;

  /// التبويبين بيتحمّلوا مع بعض عشان التنقل بينهم يبقى فوري.
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchById(customerId),
        _repository.fetchInvoices(customerId),
        _repository.fetchLedger(customerId),
      ]);

      _customer = results[0] as Customer;
      _invoices = results[1] as List<CustomerInvoice>;
      _ledger = results[2] as List<LedgerEntry>;
    });
  }

  Future<void> retry() => load();

  /// تسجيل سداد. بترجّع رسالة الخطأ لو فشل، و`null` لو نجح.
  Future<String?> recordPayment({required double amount, String? note}) async {
    final ApiException? failure = await runAction(() async {
      _customer = await _repository.recordPayment(
        customerId,
        amount: amount,
        note: note,
      );

      // الرصيد اتغيّر، فكشف الحساب لازم يتقرا من جديد.
      _ledger = await _repository.fetchLedger(customerId);
    });

    return failure?.message;
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }
}
