import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/add_branch_controller.dart';

/// حقول نموذج الفرع: الاسم والكود والعنوان والتليفون والمواعيد.
class AddBranchFields extends StatelessWidget {
  const AddBranchFields({super.key});

  @override
  Widget build(BuildContext context) {
    final AddBranchController form = context.watch<AddBranchController>();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              flex: 2,
              child: AppFormField(
                label: 'اسم الفرع',
                controller: form.nameController,
                hint: 'مثال: فرع الشيخ زايد',
                required: true,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppFormField(
                label: 'كود الفرع',
                controller: form.codeController,
                hint: 'ZAYED',
                required: true,
                prefixIcon: Icons.tag_rounded,
                onChanged: form.fieldChanged,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFormField(
          label: 'العنوان',
          controller: form.addressController,
          hint: 'الشارع، الحي، المدينة',
          prefixIcon: Icons.location_on_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        AppFormField(
          label: 'التليفون',
          controller: form.phoneController,
          hint: '02xxxxxxxx',
          keyboardType: TextInputType.phone,
          prefixIcon: Icons.phone_outlined,
        ),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: AppFormField(
                label: 'يفتح الساعة',
                controller: form.openFromController,
                hint: '09:00',
                prefixIcon: Icons.schedule_rounded,
                onChanged: form.fieldChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppFormField(
                label: 'يقفل الساعة',
                controller: form.openToController,
                hint: '23:00',
                prefixIcon: Icons.schedule_rounded,
                onChanged: form.fieldChanged,
              ),
            ),
          ],
        ),
        if (!form.hoursValid) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            'المواعيد لازم تكون بصيغة 24 ساعة زي 09:00',
            style: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }
}
