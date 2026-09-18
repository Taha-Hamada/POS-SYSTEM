import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/stock_record.dart';
import '../models/stocktake_line.dart';

/// نتيجة اعتماد الجرد.
typedef StocktakeResult = ({int applied, int failed});

/// حالة شاشة الجرد: الفرع، البحث، والكميات الفعلية المُدخلة.
///
/// الأرصدة بتتجاب من السيرفر، والاعتماد بيبعت الفروق بس — الصف اللي معدود
/// ومطابق مبيتبعتش، عشان سجل الحركات مايتلوّثش بحركات بصفر.
class StocktakeController extends ChangeNotifier with LoadState {
  /// [branchId] بيبقى null للحساب اللي مش مربوط بفرع (زي مدير النظام)،
  /// وساعتها الكنترولر بيجيب الفروع ويختار واحد بنفسه.
  StocktakeController(this._repository, {String? branchId})
      : _branchId = branchId; // ignore: prefer_initializing_formals

  final InventoryRepository _repository;

  final TextEditingController searchController = TextEditingController();

  String? _branchId;
  String _query = '';
  List<StocktakeLine> _lines = <StocktakeLine>[];
  List<Branch> _branches = <Branch>[];

  String? get branchId => _branchId;
  String get query => _query;
  List<StocktakeLine> get lines => _lines;
  List<Branch> get branches => _branches;

  String get branchName => _branches
      .where((Branch b) => b.id == _branchId)
      .map((Branch b) => b.name)
      .firstOrNull ??
      '';

  bool get canSwitchBranch => _branches.length > 1;

  /// فيه فرع بنجرد عليه؟ من غيره السيرفر بيرفض أي ترحيل.
  bool get hasBranch => _branchId != null;

  /// السيرفر مرجّعش ولا فرع — مفيش حاجة نجردها.
  bool get hasNoBranches => !isLoading && !hasFailed && _branches.isEmpty;

  bool get isEmpty => !isLoading && !hasFailed && _lines.isEmpty;

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      // الحساب المش مربوط بفرع محتاج الفروع الأول عشان يختار منها،
      // فبنجيبها لوحدها قبل أي طلب رصيد بدل ما نبعت طلب ناقص الفرع.
      if (_branchId == null && _branches.isEmpty) {
        _branches = await _repository.fetchBranches();
        _branchId = _defaultBranchId;
      }

      final String? branch = _branchId;

      if (branch == null) {
        _lines = <StocktakeLine>[];
        return;
      }

      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchStock(branchId: branch, limit: 100),
        if (_branches.isEmpty)
          _repository.fetchBranches()
        else
          Future<List<Branch>>.value(_branches),
      ]);

      final StockPage page = results[0] as StockPage;
      _lines = page.items
          .map((StockRecord r) => StocktakeLine(record: r))
          .toList();
      _branches = results[1] as List<Branch>;
    });
  }

  /// الفرع الافتراضي للحساب المش مربوط بفرع: الرئيسي لو موجود، وإلا أول واحد.
  String? get _defaultBranchId {
    if (_branches.isEmpty) return null;

    return _branches
            .where((Branch b) => b.isMain)
            .map((Branch b) => b.id)
            .firstOrNull ??
        _branches.first.id;
  }

  Future<void> retry() => load();

  List<StocktakeLine> get visibleLines {
    final String q = _query.trim().toLowerCase();
    if (q.isEmpty) return _lines;

    return _lines
        .where((StocktakeLine l) =>
            l.name.toLowerCase().contains(q) ||
            l.sku.toLowerCase().contains(q))
        .toList(growable: false);
  }

  int get countedCount => _lines.where((StocktakeLine l) => l.isCounted).length;

  int get shortageCount =>
      _lines.where((StocktakeLine l) => l.isCounted && l.difference < 0).length;

  int get surplusCount =>
      _lines.where((StocktakeLine l) => l.isCounted && l.difference > 0).length;

  double get netValue => _lines
      .where((StocktakeLine l) => l.isCounted)
      .fold<double>(0, (double s, StocktakeLine l) => s + l.valueDifference);

  bool get hasCounted => countedCount > 0;

  /// الصفوف اللي هتتبعت فعلًا — اللي فيها فرق بس.
  List<StocktakeLine> get pendingLines =>
      _lines.where((StocktakeLine l) => l.needsSubmit).toList();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  Future<void> changeBranch(String? id) async {
    if (id == null || id == _branchId) return;
    _branchId = id;
    _lines = <StocktakeLine>[];
    notifyListeners();
    await load();
  }

  void setQuery(String value) {
    _query = value;
    notifyListeners();
  }

  void setActualQuantity(StocktakeLine line, double? quantity) {
    line.actualQuantity = quantity;
    notifyListeners();
  }

  void fillAllFromSystem() {
    for (final StocktakeLine l in _lines) {
      l.actualQuantity = l.systemQuantity;
    }
    notifyListeners();
  }

  void resetAll() {
    for (final StocktakeLine l in _lines) {
      l.actualQuantity = null;
    }
    notifyListeners();
  }

  /// بيعتمد الجرد: بيبعت كل صف فيه فرق لوحده.
  ///
  /// الصف اللي يفشل مبيوقفش الباقي، عشان جرد 50 صنف ما يضيعش بسبب صنف واحد.
  Future<StocktakeResult> submit({String? note}) async {
    final String? branch = _branchId;
    if (branch == null) return (applied: 0, failed: 0);

    final List<StocktakeLine> pending = pendingLines;
    int applied = 0;
    int failed = 0;

    await runAction(() async {
      for (final StocktakeLine line in pending) {
        try {
          await _repository.stocktake(
            productId: line.productId,
            branchId: branch,
            countedQuantity: line.actualQuantity!,
            note: note,
          );
          applied += 1;
        } on ApiException {
          failed += 1;
        }
      }
    });

    await load();

    return (applied: applied, failed: failed);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}
