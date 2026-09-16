import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/promotion.dart';
import '../../../core/widgets/app_form_field.dart';
import '../../../theme/app_theme.dart';
import '../controllers/promotion_form_controller.dart';
import '../controllers/promotions_controller.dart';
import '../widgets/create_promotion_actions.dart';
import '../widgets/create_promotion_header.dart';
import '../widgets/promotion_date_range_fields.dart';
import '../widgets/promotion_scope_fields.dart';
import '../widgets/promotion_type_field.dart';
import '../widgets/promotion_value_field.dart';

/// يفتح حوار العرض ويرجّع true لو اتحفظ.
///
/// بياخد [PromotionsController] بتاع الشاشة عشان الأقسام والمنتجات
/// تتحمّل مرة واحدة، والنموذج نفسه ليه كنترولر جديد مع كل فتح.
Future<bool?> showCreatePromotionDialog(
  BuildContext context, {
  required PromotionsController promotions,
  Promotion? initial,
}) {
  promotions.ensureLookups();

  return showDialog<bool>(
    context: context,
    builder: (BuildContext context) => MultiProvider(
      providers: <ChangeNotifierProvider<ChangeNotifier>>[
        ChangeNotifierProvider<PromotionsController>.value(value: promotions),
        ChangeNotifierProvider<PromotionFormController>(
          create: (_) => PromotionFormController(initial: initial),
        ),
      ],
      child: CreatePromotionDialog(
        onSubmit: (input) => promotions.save(input, existing: initial),
      ),
    ),
  );
}

/// حوار إنشاء أو تعديل عرض — بيجمّع حقول النموذج بس.
class CreatePromotionDialog extends StatelessWidget {
  const CreatePromotionDialog({super.key, required this.onSubmit});

  final PromotionSubmit onSubmit;

  @override
  Widget build(BuildContext context) {
    final PromotionFormController form = context
        .read<PromotionFormController>();

    return Dialog(
      child: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const CreatePromotionHeader(),
              const SizedBox(height: AppSpacing.xl),
              AppFormField(
                label: 'اسم العرض',
                controller: form.nameController,
                hint: 'مثال: خصم الصيف على المشروبات',
                required: true,
                onChanged: form.fieldChanged,
              ),
              const SizedBox(height: AppSpacing.lg),
              const PromotionTypeField(),
              const SizedBox(height: AppSpacing.lg),
              const PromotionValueField(),
              const SizedBox(height: AppSpacing.lg),
              const PromotionScopeFields(),
              const SizedBox(height: AppSpacing.lg),
              const PromotionDateRangeFields(),
              const SizedBox(height: AppSpacing.xxl),
              CreatePromotionActions(onSubmit: onSubmit),
            ],
          ),
        ),
      ),
    );
  }
}
