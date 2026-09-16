import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';
import 'promotion_date_field.dart';

/// حقلا البداية والنهاية + مدة العرض.
class PromotionDateRangeFields extends StatelessWidget {
  const PromotionDateRangeFields({super.key});

  /// نفس ثيم منتقي التاريخ المستخدم في باقي النظام.
  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final PromotionFormController form = context
        .read<PromotionFormController>();
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStart ? form.start : form.end,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
      locale: const Locale('ar'),
      builder: (BuildContext context, Widget? child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            headerBackgroundColor: AppColors.primary,
            headerForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            todayBorder: const BorderSide(color: AppColors.accent),
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    if (isStart) {
      form.setStart(picked);
    } else {
      form.setEnd(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .watch<PromotionFormController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: PromotionDateField(
                label: 'تاريخ البداية',
                date: form.start,
                onTap: () => _pickDate(context, isStart: true),
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: PromotionDateField(
                label: 'تاريخ النهاية',
                date: form.end,
                onTap: () => _pickDate(context, isStart: false),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: <Widget>[
            const Icon(
              Icons.schedule_rounded,
              size: 14,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'مدة العرض: ${form.durationDays} يوم — بيخلص آخر اليوم الأخير',
              style: AppText.caption.copyWith(fontSize: 11.5),
            ),
          ],
        ),
      ],
    );
  }
}
