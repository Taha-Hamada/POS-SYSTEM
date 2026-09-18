import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/expense.dart';
import '../data/expenses_repository.dart';

/// حالة نموذج إضافة مصروف.
class AddExpenseController extends ChangeNotifier with LoadState {
  AddExpenseController(
    this._repository, {
    required List<Branch> branches,
    required this.knownCategories,
    String? branchId,
  })  : _branches = branches,
        _branchId = branchId ?? (branches.isEmpty ? null : branches.first.id);

  final ExpensesRepository _repository;
  final List<Branch> _branches;

  /// البنود اللي اتسجّلت قبل كده — بتظهر كاقتراحات، والمستخدم حر يكتب جديد.
  final List<String> knownCategories;

  final TextEditingController categoryController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController noteController = TextEditingController();

  String? _branchId;

  List<Branch> get branches => _branches;

  String? get branchId => _branchId;
  String get category => categoryController.text.trim();

  double get amount => double.tryParse(amountController.text.trim()) ?? 0;

  bool get canSwitchBranch => _branches.length > 1;

  /// السيرفر بيطلب بند من حرفين على الأقل ومبلغ أكبر من صفر.
  bool get isValid =>
      amount > 0 && category.length >= 2 && _branchId != null && !isLoading;

  String? saveError;

  // ── إجراءات ──────────────────────────────────────────────────────────────
  void setCategory(String value) {
    categoryController.text = value;
    notifyListeners();
  }

  void setBranch(String? id) {
    if (id == null) return;
    _branchId = id;
    notifyListeners();
  }

  void fieldChanged([String? _]) => notifyListeners();

  /// بيسجّل المصروف على السيرفر. بيرجّعه لو نجح، و`null` لو فشل.
  Future<Expense?> submit() async {
    saveError = null;

    Expense? created;

    final ApiException? failure = await runAction(() async {
      created = await _repository.create(
        category: category,
        amount: amount,
        branchId: _branchId,
        note: noteController.text.trim(),
      );
    });

    if (failure != null) {
      saveError = failure.fieldErrors['amount'] ??
          failure.fieldErrors['category'] ??
          failure.message;
      notifyListeners();
      return null;
    }

    return created;
  }

  @override
  void dispose() {
    categoryController.dispose();
    amountController.dispose();
    noteController.dispose();
    super.dispose();
  }
}
