import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../../inventory/data/inventory_repository.dart';
import '../../inventory/models/stock_record.dart';
import '../models/transfer_line.dart';

/// نتيجة تنفيذ التحويل.
typedef TransferResult = ({int moved, int failed, String? error});

/// حالة أمر تحويل المخزون: الفرعين والأصناف.
///
/// التحويل بيتنفذ فورًا على السيرفر: خصم من المصدر وإضافة للوجهة في عملية
/// واحدة. مفيش مرحلة «في الطريق» لأن السيرفر مبيمسكش شحنات، فبنعرض الحقيقة
/// بدل مراحل مالهاش وجود.
class StockTransferController extends ChangeNotifier with LoadState {
  StockTransferController(this._repository, {required String fromBranchId})
      : _fromBranchId = fromBranchId; // ignore: prefer_initializing_formals

  final InventoryRepository _repository;

  String _fromBranchId;
  String? _toBranchId;

  final List<TransferLine> _lines = <TransferLine>[];
  List<StockRecord> _sourceStock = <StockRecord>[];
  List<Branch> _branches = <Branch>[];

  String get fromBranchId => _fromBranchId;
  String? get toBranchId => _toBranchId;

  UnmodifiableListView<TransferLine> get lines =>
      UnmodifiableListView<TransferLine>(_lines);

  List<Branch> get branches => _branches;

  /// الأصناف اللي في الفرع المُرسِل وليها رصيد متاح.
  List<StockRecord> get availableStock =>
      _sourceStock.where((StockRecord r) => r.available > 0).toList();

  String _branchName(String? id) => _branches
          .where((Branch b) => b.id == id)
          .map((Branch b) => b.name)
          .firstOrNull ??
      '';

  String get fromName => _branchName(_fromBranchId);
  String get toName => _branchName(_toBranchId);

  bool get sameBranch => _fromBranchId == _toBranchId;

  bool get canSubmit =>
      _lines.isNotEmpty &&
      _toBranchId != null &&
      !sameBranch &&
      !isLoading &&
      _lines.every((TransferLine l) => l.quantity > 0 && !l.exceedsAvailable);

  int get totalQuantity =>
      _lines.fold<int>(0, (int s, TransferLine l) => s + l.quantity);

  double get totalValue =>
      _lines.fold<double>(0, (double s, TransferLine l) => s + l.value);

  /// المنتجات المضافة بالفعل — عشان ما تتكررش في نافذة الاختيار.
  Set<String> get pickedProductIds =>
      _lines.map((TransferLine l) => l.productId).toSet();

  // ── التحميل ──────────────────────────────────────────────────────────────
  Future<void> load() async {
    await runLoad(() async {
      final List<Object> results = await Future.wait(<Future<Object>>[
        _repository.fetchStock(branchId: _fromBranchId, limit: 100),
        if (_branches.isEmpty)
          _repository.fetchBranches()
        else
          Future<List<Branch>>.value(_branches),
      ]);

      _sourceStock = (results[0] as StockPage).items;
      _branches = results[1] as List<Branch>;

      // أول فرع تاني بيبقى الوجهة الافتراضية.
      _toBranchId ??= _branches
          .where((Branch b) => b.id != _fromBranchId)
          .map((Branch b) => b.id)
          .firstOrNull;
    });
  }

  Future<void> retry() => load();

  // ── إجراءات ──────────────────────────────────────────────────────────────
  Future<void> setFromBranch(String id) async {
    if (id == _fromBranchId) return;

    _fromBranchId = id;
    // الأصناف كانت من الفرع القديم، فمبقاش ليها معنى.
    _lines.clear();
    notifyListeners();
    await load();
  }

  void setToBranch(String id) {
    _toBranchId = id;
    notifyListeners();
  }

  Future<void> swapBranches() async {
    final String? destination = _toBranchId;
    if (destination == null) return;

    _toBranchId = _fromBranchId;
    await setFromBranch(destination);
  }

  void addProduct(StockRecord record) {
    if (pickedProductIds.contains(record.productId)) return;

    _lines.add(TransferLine(record: record));
    notifyListeners();
  }

  void removeLine(TransferLine line) {
    _lines.remove(line);
    notifyListeners();
  }

  void setQuantity(TransferLine line, int quantity) {
    line.quantity = quantity.clamp(0, line.available);
    notifyListeners();
  }

  /// بينفّذ التحويل صنف صنف — السيرفر بيحوّل منتج واحد في الطلب.
  Future<TransferResult> submit({String? note}) async {
    if (!canSubmit) return (moved: 0, failed: 0, error: 'مفيش حاجة للتحويل');

    int moved = 0;
    int failed = 0;
    String? firstError;

    await runAction(() async {
      for (final TransferLine line in _lines.toList()) {
        try {
          await _repository.transfer(
            productId: line.productId,
            fromBranchId: _fromBranchId,
            toBranchId: _toBranchId!,
            quantity: line.quantity,
            note: note,
          );

          _lines.remove(line);
          moved += 1;
        } on ApiException catch (exception) {
          failed += 1;
          firstError ??= exception.message;
        }
      }
    });

    await load();

    return (moved: moved, failed: failed, error: firstError);
  }
}
