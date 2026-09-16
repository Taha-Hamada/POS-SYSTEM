import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/session/settings_controller.dart' as store;
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../theme/app_theme.dart';
import '../controllers/loyalty_controller.dart';
import '../data/loyalty_repository.dart';
import '../widgets/loyalty_earning_section.dart';
import '../widgets/loyalty_leaderboard.dart';
import '../widgets/loyalty_tiers_section.dart';

/// شاشة برنامج الولاء — بتجمّع إعداد الكسب والمستويات وجدول الترتيب بس.
class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  Future<void> _save(BuildContext context) async {
    final LoyaltyController loyalty = context.read<LoyaltyController>();

    final String? error = await loyalty.save();
    if (!context.mounted) return;

    if (error == null) {
      // الكاشير بياخد المستويات الجديدة من غير ما يعيد تحميل الإعدادات.
      await context.read<store.SettingsController>().load();
      if (!context.mounted) return;
    }

    showAppSnackBar(
      context,
      error ?? 'اتحفظت إعدادات الولاء واتحدّث مستوى العملاء',
      isError: error != null,
      width: 460,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ApiClient api = context.read<ApiClient>();
    final bool canEdit = context.read<SessionController>().can(
      'settings:manage',
    );

    return ChangeNotifierProvider<LoyaltyController>(
      create: (_) =>
          LoyaltyController(LoyaltyRepository(api), canEdit: canEdit)..load(),
      child: Builder(
        builder: (BuildContext context) {
          final LoyaltyController loyalty = context.watch<LoyaltyController>();

          if (loyalty.isFirstLoad) {
            return const LoadingView(message: 'بنحمّل برنامج الولاء…');
          }

          if (loyalty.hasFailed && loyalty.tiers.isEmpty) {
            return ErrorView(
              message: loyalty.errorMessage!,
              onRetry: loyalty.retry,
            );
          }

          return Padding(
            padding: AppSpacing.page,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  ScreenHeader(
                    title: 'برنامج الولاء',
                    subtitle: canEdit
                        ? 'إعدادات كسب النقاط ومستويات العضوية وأعلى العملاء'
                        : 'عرض فقط — تعديل البرنامج محتاج صلاحية الإعدادات',
                    actions: <Widget>[
                      if (canEdit)
                        PrimaryButton(
                          label: 'حفظ الإعدادات',
                          icon: Icons.save_outlined,
                          onPressed: loyalty.dirty && !loyalty.isLoading
                              ? () => _save(context)
                              : null,
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const LoyaltyEarningSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  const LoyaltyTiersSection(),
                  const SizedBox(height: AppSpacing.xxl),
                  const LoyaltyLeaderboard(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
