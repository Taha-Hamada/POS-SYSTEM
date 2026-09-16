import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/loyalty_tier.dart';
import '../../../core/models/store_settings.dart';
import '../data/loyalty_repository.dart';

/// حالة شاشة برنامج الولاء: آلية الكسب والمستويات وأعلى العملاء.
class LoyaltyController extends ChangeNotifier with LoadState {
  LoyaltyController(this._repository, {this.canEdit = false});

  final LoyaltyRepository _repository;

  /// من غير صلاحية الإعدادات الشاشة بتبقى للعرض بس.
  final bool canEdit;

  /// عدد النقاط لكل جنيه
  final TextEditingController rateController = TextEditingController();

  /// قيمة النقطة بالجنيه عند الاستبدال
  final TextEditingController pointValueController = TextEditingController();

  /// المبلغ المستخدم في المثال الحي تحت الحقل
  static const double exampleInvoice = 500;

  StoreSettings _saved = const StoreSettings();
  List<LoyaltyTier> _tiers = <LoyaltyTier>[];
  List<Customer> _top = <Customer>[];
  Map<String, int> _counts = <String, int>{};

  double get rate => double.tryParse(rateController.text.trim()) ?? 0;
  double get pointValue =>
      double.tryParse(pointValueController.text.trim()) ?? 0;

  /// السيرفر بيقرّب النقاط للأقل، فالمثال بيعمل نفس الحاجة.
  int get examplePoints => (exampleInvoice * rate).floor();

  double get exampleDiscount => examplePoints * pointValue;

  List<LoyaltyTier> get tiers => _tiers;
  List<Customer> get topCustomers => _top;

  int get totalGrantedPoints =>
      _top.fold<int>(0, (int s, Customer c) => s + c.points);

  int membersCountFor(LoyaltyTier tier) => _counts[tier.key] ?? 0;

  /// قيمة نقاط العميل بالجنيه بقيمة النقطة المحفوظة.
  double pointsValue(Customer c) => c.points * _saved.currencyPerPoint;

  String tierNameOf(Customer c) => tierNameFor(c.tier, _tiers);

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchSettings(),
        _repository.fetchTopCustomers(),
      ]);

      _fill(results[0] as StoreSettings);
      _top = results[1] as List<Customer>;
      await _loadCounts();
    });
  }

  Future<void> retry() => load();

  Future<void> _loadCounts() async {
    try {
      _counts = await _repository.fetchTierCounts(
        _tiers.map((LoyaltyTier t) => t.key).toList(growable: false),
      );
    } on ApiException {
      _counts = <String, int>{};
    }
  }

  void _fill(StoreSettings s) {
    _saved = s;
    rateController.text = _number(s.pointsPerCurrency);
    pointValueController.text = _number(s.currencyPerPoint);
    _tiers = List<LoyaltyTier>.of(s.loyaltyTiers);
  }

  static String _number(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toString();

  // ── التعديل ──────────────────────────────────────────────────────────────
  void rateChanged([String? _]) => notifyListeners();

  void updateTier(LoyaltyTier tier) {
    _tiers = <LoyaltyTier>[
      for (final LoyaltyTier t in _tiers) t.key == tier.key ? tier : t,
    ];
    notifyListeners();
  }

  /// نفس شروط السيرفر، عشان الحفظ مايترفضش بعد ما يتبعت.
  String? get validationError {
    if (rate < 0) return 'عدد النقاط مينفعش يكون سالب';
    if (pointValue < 0) return 'قيمة النقطة مينفعش تكون سالبة';

    for (int i = 1; i < _tiers.length; i++) {
      if (_tiers[i].minPurchases <= _tiers[i - 1].minPurchases) {
        return 'حد «${_tiers[i].name}» لازم يكون أكبر من «${_tiers[i - 1].name}»';
      }
    }

    return null;
  }

  Map<String, dynamic> get _changes {
    final Map<String, dynamic> changes = <String, dynamic>{};

    if ((rate - _saved.pointsPerCurrency).abs() > 0.00001) {
      changes['pointsPerCurrency'] = rate;
    }
    if ((pointValue - _saved.currencyPerPoint).abs() > 0.00001) {
      changes['currencyPerPoint'] = pointValue;
    }

    // المقارنة بالشكل اللي بيتبعت، عشان أي فرق في أي حقل يتلقط.
    String encode(List<LoyaltyTier> tiers) =>
        jsonEncode(tiers.map((LoyaltyTier t) => t.toJson()).toList());

    if (encode(_tiers) != encode(_saved.loyaltyTiers)) {
      changes['loyaltyTiers'] = _tiers
          .map((LoyaltyTier t) => t.toJson())
          .toList(growable: false);
    }

    return changes;
  }

  bool get dirty => canEdit && _changes.isNotEmpty;

  /// بيحفظ اللي اتغير. بيرجّع رسالة الخطأ لو فشل.
  Future<String?> save() async {
    final String? invalid = validationError;
    if (invalid != null) return invalid;

    final Map<String, dynamic> changes = _changes;
    if (changes.isEmpty) return null;

    final ApiException? failure = await runAction(() async {
      _fill(await _repository.saveSettings(changes));

      // تغيير الحدود بينقل عملاء بين المستويات على السيرفر.
      if (changes.containsKey('loyaltyTiers')) await _loadCounts();
    });

    return failure?.message;
  }

  @override
  void dispose() {
    rateController.dispose();
    pointValueController.dispose();
    super.dispose();
  }
}
