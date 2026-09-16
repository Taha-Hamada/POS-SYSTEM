import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/employee.dart';
import '../../../core/models/store_settings.dart';
import '../../employees_permissions/data/employees_repository.dart';
import '../data/settings_repository.dart';
import '../models/settings_section.dart';

/// حالة شاشة الإعدادات: القسم المختار وقيم الإعدادات قبل وبعد التعديل.
class SettingsController extends ChangeNotifier with LoadState {
  SettingsController(
    this._repository, {
    required TickerProvider vsync,
    this.canEdit = false,
    this.employees,
  }) {
    fadeController = AnimationController(
      vsync: vsync,
      duration: const Duration(milliseconds: 300),
      value: 1,
    );
  }

  final SettingsRepository _repository;

  /// null لو المستخدم مايقدرش يشوف الموظفين، فقسم المستخدمين بيقول كده.
  final EmployeesRepository? employees;

  /// من غير صلاحية الإعدادات الشاشة بتبقى للعرض بس.
  final bool canEdit;

  /// أنيميشن الـFade عند تبديل القسم
  late final AnimationController fadeController;

  /// العملات اللي الشاشة بتعرضها بأسمائها — الكود هو اللي بيتخزن.
  static const Map<String, String> currencies = <String, String>{
    'EGP': 'الجنيه المصري (ج.م)',
    'SAR': 'الريال السعودي (ر.س)',
    'AED': 'الدرهم الإماراتي (د.إ)',
  };

  static const List<int> receiptWidths = <int>[58, 80];

  SettingsSection _section = SettingsSection.general;
  SettingsSection get section => _section;

  StoreSettings _saved = const StoreSettings();
  StoreSettings get saved => _saved;

  // ── إعدادات عامة ─────────────────────────────────────────────────────────
  final TextEditingController storeNameController = TextEditingController();
  final TextEditingController storeAddressController = TextEditingController();
  final TextEditingController storePhoneController = TextEditingController();
  String _currency = 'EGP';
  String get currency => _currency;

  bool _requireOpenShift = true;
  bool _requireCustomerForCredit = true;
  bool _allowNegativeStock = false;
  bool get requireOpenShift => _requireOpenShift;
  bool get requireCustomerForCredit => _requireCustomerForCredit;
  bool get allowNegativeStock => _allowNegativeStock;

  // ── الضرائب ──────────────────────────────────────────────────────────────
  final TextEditingController taxRateController = TextEditingController();
  final TextEditingController taxNumberController = TextEditingController();
  bool _taxIncluded = false;
  bool get taxIncluded => _taxIncluded;

  /// النسبة كعدد زي ما المستخدم كاتبها: 14 مش 0.14.
  double get taxRate => double.tryParse(taxRateController.text.trim()) ?? 0;

  // ── الطباعة ──────────────────────────────────────────────────────────────
  final TextEditingController footerNoteController = TextEditingController();
  int _receiptWidth = 80;
  int get receiptWidth => _receiptWidth;

  // ── التنبيهات — بتتحفظ على السيرفر وبتتحكم في جرس الشريط العلوي ─────────
  bool _notifyLowStock = true;
  bool _notifyExpiry = true;
  bool get notifyLowStock => _notifyLowStock;
  bool get notifyExpiry => _notifyExpiry;

  // ── المستخدمون ───────────────────────────────────────────────────────────
  List<Employee> _users = <Employee>[];
  List<Employee> get users => _users;
  bool get canViewUsers => employees != null;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      _fill(await _repository.fetch());

      final EmployeesRepository? repository = employees;
      if (repository != null) {
        try {
          _users = await repository.fetchAll();
        } on ApiException {
          _users = <Employee>[];
        }
      }
    });
  }

  Future<void> retry() => load();

  void _fill(StoreSettings s) {
    _saved = s;
    storeNameController.text = s.storeName;
    storeAddressController.text = s.storeAddress;
    storePhoneController.text = s.storePhone;
    _currency = s.currency;
    _requireOpenShift = s.requireOpenShift;
    _requireCustomerForCredit = s.requireCustomerForCredit;
    _allowNegativeStock = s.allowNegativeStock;
    taxRateController.text = _formatPercent(s.taxPercent);
    taxNumberController.text = s.taxNumber;
    _taxIncluded = s.pricesIncludeTax;
    footerNoteController.text = s.receiptFooter;
    _receiptWidth = s.receiptWidthMm;
    _notifyLowStock = s.notifyLowStock;
    _notifyExpiry = s.notifyExpiry;
  }

  /// 14.0 بتتعرض 14، و 12.5 بتفضل زي ما هي.
  static String _formatPercent(double value) {
    final double rounded = double.parse(value.toStringAsFixed(2));
    return rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toString();
  }

  /// الحقول اللي اختلفت عن المحفوظ على السيرفر.
  Map<String, dynamic> get _changes {
    final Map<String, dynamic> changes = <String, dynamic>{};

    void compare(String key, Object current, Object saved) {
      if (current != saved) changes[key] = current;
    }

    compare('storeName', storeNameController.text.trim(), _saved.storeName);
    compare(
      'storeAddress',
      storeAddressController.text.trim(),
      _saved.storeAddress,
    );
    compare('storePhone', storePhoneController.text.trim(), _saved.storePhone);
    compare('currency', _currency, _saved.currency);
    compare('requireOpenShift', _requireOpenShift, _saved.requireOpenShift);
    compare(
      'requireCustomerForCredit',
      _requireCustomerForCredit,
      _saved.requireCustomerForCredit,
    );
    compare(
      'allowNegativeStock',
      _allowNegativeStock,
      _saved.allowNegativeStock,
    );
    compare('taxNumber', taxNumberController.text.trim(), _saved.taxNumber);
    compare('pricesIncludeTax', _taxIncluded, _saved.pricesIncludeTax);
    compare(
      'receiptFooter',
      footerNoteController.text.trim(),
      _saved.receiptFooter,
    );
    compare('receiptWidthMm', _receiptWidth, _saved.receiptWidthMm);

    // التنبيهات بتتبعت ككائن واحد زي ما السيرفر مستنيها.
    if (_notifyLowStock != _saved.notifyLowStock ||
        _notifyExpiry != _saved.notifyExpiry) {
      changes['notifications'] = <String, bool>{
        'lowStock': _notifyLowStock,
        'expiry': _notifyExpiry,
      };
    }

    // السيرفر بيخزّن النسبة من 0 لـ 1، والمقارنة بتقريب عشان كسور الـdouble.
    final double rate = double.parse((taxRate / 100).toStringAsFixed(4));
    if ((rate - _saved.taxRate).abs() > 0.00001) changes['taxRate'] = rate;

    return changes;
  }

  bool get dirty => canEdit && _changes.isNotEmpty;

  /// أخطاء بنمسكها قبل ما نبعت، بنفس حدود السيرفر.
  String? get validationError {
    if (storeNameController.text.trim().isEmpty) return 'اسم المتجر مطلوب';
    final double? rate = double.tryParse(taxRateController.text.trim());
    if (rate == null || rate < 0 || rate > 100) {
      return 'نسبة الضريبة لازم تكون بين 0 و 100';
    }
    return null;
  }

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void selectSection(SettingsSection section) {
    if (section == _section) return;

    _section = section;
    fadeController
      ..reset()
      ..forward();
    notifyListeners();
  }

  void setCurrency(String currency) {
    _currency = currency;
    notifyListeners();
  }

  void setRequireOpenShift(bool value) {
    _requireOpenShift = value;
    notifyListeners();
  }

  void setRequireCustomerForCredit(bool value) {
    _requireCustomerForCredit = value;
    notifyListeners();
  }

  void setAllowNegativeStock(bool value) {
    _allowNegativeStock = value;
    notifyListeners();
  }

  void setTaxIncluded(bool value) {
    _taxIncluded = value;
    notifyListeners();
  }

  void setReceiptWidth(int value) {
    _receiptWidth = value;
    notifyListeners();
  }

  void setNotifyLowStock(bool value) {
    _notifyLowStock = value;
    notifyListeners();
  }

  void setNotifyExpiry(bool value) {
    _notifyExpiry = value;
    notifyListeners();
  }

  /// أي تعديل في حقول النص — بيحدّث المعاينة وحالة زر الحفظ.
  void fieldChanged([String? _]) => notifyListeners();

  /// بيحفظ اللي اتغير. بيرجّع رسالة الخطأ لو فشل.
  Future<String?> save() async {
    final String? invalid = validationError;
    if (invalid != null) return invalid;

    final Map<String, dynamic> changes = _changes;
    if (changes.isEmpty) return null;

    final ApiException? failure = await runAction(() async {
      _fill(await _repository.update(changes));
    });

    return failure?.message;
  }

  Future<String?> resetPassword(Employee employee, String password) async {
    final EmployeesRepository? repository = employees;
    if (repository == null) return 'مالكش صلاحية على المستخدمين';

    final ApiException? failure = await runAction(() async {
      await repository.resetPassword(employee.id, password);
    });

    return failure?.message;
  }

  @override
  void dispose() {
    fadeController.dispose();
    storeNameController.dispose();
    storeAddressController.dispose();
    storePhoneController.dispose();
    taxRateController.dispose();
    taxNumberController.dispose();
    footerNoteController.dispose();
    super.dispose();
  }
}
