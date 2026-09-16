import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/api/api_exception.dart';
import '../../../core/data/branches_repository.dart';
import '../../../core/models/branch.dart';
import '../../../theme/app_theme.dart';

/// اختيار فرع الوردية — للحساب اللي مش مربوط بفرع زي مدير النظام.
///
/// الوردية لازم يبقى لها فرع، والفواتير اللي بتتعمل فيها بتتسجل عليه
/// وبتخصم من مخزونه. بيرجّع معرّف الفرع أو null لو اتلغى.
Future<String?> showShiftBranchPicker(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (BuildContext context) => _ShiftBranchPicker(
      repository: BranchesRepository(context.read<ApiClient>()),
    ),
  );
}

class _ShiftBranchPicker extends StatefulWidget {
  const _ShiftBranchPicker({required this.repository});

  final BranchesRepository repository;

  @override
  State<_ShiftBranchPicker> createState() => _ShiftBranchPickerState();
}

class _ShiftBranchPickerState extends State<_ShiftBranchPicker> {
  late final Future<List<Branch>> _branches = widget.repository.fetchAll();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('الوردية في أنهي فرع؟'),
      content: SizedBox(
        width: 380,
        child: FutureBuilder<List<Branch>>(
          future: _branches,
          builder: (BuildContext context, AsyncSnapshot<List<Branch>> snap) {
            if (snap.connectionState != ConnectionState.done) {
              return const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (snap.hasError) {
              final Object? error = snap.error;
              return Text(
                error is ApiException ? error.message : 'مقدرناش نجيب الفروع',
                style: const TextStyle(color: AppColors.danger),
              );
            }

            final List<Branch> branches = snap.data ?? <Branch>[];
            if (branches.isEmpty) {
              return const Text('مفيش فروع مفتوحة تقدر تفتح فيها وردية');
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  'حسابك مش مربوط بفرع، فالفواتير هتتسجل على الفرع اللي تختاره '
                  'وهتخصم من مخزونه.',
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final Branch b in branches)
                  ListTile(
                    leading: const Icon(Icons.storefront_rounded),
                    title: Text(b.name),
                    subtitle: b.address.isEmpty ? null : Text(b.address),
                    onTap: () => Navigator.of(context).pop(b.id),
                  ),
              ],
            );
          },
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
      ],
    );
  }
}
