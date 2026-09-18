import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../theme/app_theme.dart';
import '../controllers/add_branch_controller.dart';
import '../widgets/add_branch_actions.dart';
import '../widgets/add_branch_fields.dart';
import '../widgets/add_branch_header.dart';

/// يفتح حوار الفرع ويرجّع true لو اتحفظ.
///
/// الحفظ بيحصل جوه الحوار عشان أخطاء السيرفر (زي كود مكرر) تظهر جنب الحقول
/// والمستخدم يصلّحها من غير ما يكتب كل حاجة من الأول.
Future<bool?> showAddBranchDialog(
  BuildContext context, {
  required BranchSubmit onSubmit,
  Branch? initial,
}) {
  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) =>
        AddBranchDialog(onSubmit: onSubmit, initial: initial),
  );
}

/// حوار إضافة أو تعديل فرع — بيجمّع الهيدر والحقول والأزرار بس.
class AddBranchDialog extends StatelessWidget {
  const AddBranchDialog({super.key, required this.onSubmit, this.initial});

  final BranchSubmit onSubmit;
  final Branch? initial;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AddBranchController>(
      create: (_) => AddBranchController(initial: initial),
      child: Dialog(
        child: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const AddBranchHeader(),
                const SizedBox(height: AppSpacing.xl),
                const AddBranchFields(),
                const SizedBox(height: AppSpacing.xxl),
                AddBranchActions(onSubmit: onSubmit),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
