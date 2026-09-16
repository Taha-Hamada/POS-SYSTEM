import 'package:flutter/foundation.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/api/load_state.dart';
import '../../../core/models/branch.dart';
import '../../../core/models/employee.dart';
import '../../../core/models/user_role.dart';
import '../../employees_permissions/data/employees_repository.dart';
import '../data/branch_management_repository.dart';
import '../models/branch_stats.dart';

/// حالة شاشة الفروع: الفروع بأرقامها والإجماليات والمرشّحين لإدارتها.
class BranchesController extends ChangeNotifier with LoadState {
  BranchesController(this._repository, [this._employees]);

  final BranchManagementRepository _repository;

  /// null لو المستخدم مايقدرش يشوف الموظفين — ساعتها مفيش اختيار مسؤول.
  final EmployeesRepository? _employees;

  List<BranchStats> _rows = <BranchStats>[];
  BranchesTotals _totals = const BranchesTotals();
  List<Employee> _managers = <Employee>[];

  List<BranchStats> get rows => _rows;
  BranchesTotals get totals => _totals;

  /// الحسابات اللي ينفع تبقى مسؤولة عن فرع.
  List<Employee> get managers => _managers;

  bool get isEmpty => !isLoading && !hasFailed && _rows.isEmpty;

  Future<void> load() async {
    await runLoad(() async {
      final BranchesOverview overview = await _repository.fetchOverview();
      _rows = overview.branches;
      _totals = overview.totals;

      if (_employees != null && _managers.isEmpty) {
        _managers = await _loadManagers(_employees);
      }
    });
  }

  Future<void> retry() => load();

  /// قايمة المسؤولين ثانوية: لو فشلت الشاشة تكمل من غيرها.
  Future<List<Employee>> _loadManagers(EmployeesRepository employees) async {
    try {
      final List<Employee> active = await employees.fetchAll(isActive: true);

      return active
          .where(
            (Employee e) =>
                e.role == UserRole.manager.apiValue ||
                e.role == UserRole.admin.apiValue,
          )
          .toList(growable: false);
    } on ApiException {
      return <Employee>[];
    }
  }

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
