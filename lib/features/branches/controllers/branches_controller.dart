import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../data/branch_management_repository.dart';
import '../models/branch_stats.dart';

/// حالة شاشة الفروع: الفروع بأرقامها والإجماليات.
class BranchesController extends ChangeNotifier with LoadState {
  BranchesController(this._repository);

  final BranchManagementRepository _repository;

  List<BranchStats> _rows = <BranchStats>[];
  BranchesTotals _totals = const BranchesTotals();

  List<BranchStats> get rows => _rows;
  BranchesTotals get totals => _totals;

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  Future<void> load() async {
    await runLoad(() async {
      final BranchesOverview overview = await _repository.fetchOverview();
      _rows = overview.branches;
      _totals = overview.totals;
    });
  }

  Future<void> retry() => load();

  /// إضافة فرع جديد أو تعديل فرع موجود. بترجّع رسالة الخطأ لو فشلت.
  Future<String?> save(BranchInput input, {Branch? existing}) async {
    final ApiException? failure = await runAction(() async {
      if (existing == null) {
        await _repository.create(input);
      } else {
        await _repository.update(existing.id, input);
      }
    });

    if (failure == null) await load();

    return failure?.message;
  }

  Future<String?> setOpen(Branch branch, {required bool isOpen}) async {
    final ApiException? failure = await runAction(() async {
      await _repository.setOpen(branch.id, isOpen: isOpen);
    });

    if (failure == null) await load();

    return failure?.message;
  }

  /// الفرع المعطّل بيختفي من الشاشة ومن كل الفلاتر.
  Future<String?> deactivate(Branch branch) async {
    final ApiException? failure = await runAction(() async {
      await _repository.deactivate(branch.id);
    });

    if (failure == null) await load();

    return failure?.message;
  }
}
