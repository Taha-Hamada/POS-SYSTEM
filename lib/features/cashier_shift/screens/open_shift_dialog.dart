import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/numpad.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/shift_controller.dart';
import '../widgets/open_shift_amount_display.dart';
import '../widgets/open_shift_header.dart';
import '../widgets/open_shift_presets.dart';

/// يفتح حوار بدء الوردية ويرجّع الرصيد الافتتاحي (أو null لو اتلغى).
Future<double?> showOpenShiftDialog(BuildContext context) {
  return showDialog<double>(
    context: context,
    barrierDismissible: false,
    barrierColor: AppColors.primary.withValues(alpha: 0.55),
    builder: (_) => const OpenShiftDialog(),
  );
}

/// حوار بدء الوردية — بيجمّع الهيدر وخانة المبلغ والـNumpad بس.
class OpenShiftDialog extends StatelessWidget {
  const OpenShiftDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return ChangeNotifierProvider<ShiftController>(
      create: (_) => ShiftController(),
      // الحوار بيرجّع المبلغ بس؛ اللي فتحه هو اللي بيبعته للسيرفر،
      // عشان الحوار يفضل بسيط ومالوش دعوة بالشبكة.
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 520,
            maxHeight: screen.height - 80,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xxl,
              vertical: AppSpacing.xxl,
            ),
            child: Consumer<ShiftController>(
              builder: (
                BuildContext context,
                ShiftController shift,
                Widget? child,
              ) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const OpenShiftHeader(),
                    const SizedBox(height: AppSpacing.xxl),
                    const OpenShiftAmountDisplay(),
                    const SizedBox(height: AppSpacing.lg),
                    const OpenShiftPresets(),
                    const SizedBox(height: AppSpacing.xl),
                    Center(
                      child: Numpad(
                        keySize: 66,
                        spacing: 12,
                        onKey: shift.tapKey,
                        onBackspace: shift.backspace,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                    PrimaryButton(
                      label: 'بدء الوردية',
                      icon: Icons.play_circle_outline_rounded,
                      size: AppButtonSize.hero,
                      expanded: true,
                      onPressed: shift.isOpeningValid
                          ? () =>
                              Navigator.of(context).pop(shift.openingValue)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Center(
                      child: SecondaryButton(
                        label: 'إلغاء',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
