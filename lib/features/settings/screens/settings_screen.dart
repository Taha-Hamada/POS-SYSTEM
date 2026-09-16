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
import '../../employees_permissions/data/employees_repository.dart';
import '../controllers/settings_controller.dart';
import '../data/settings_repository.dart';
import '../widgets/settings_content.dart';
import '../widgets/settings_sections_list.dart';

/// شاشة الإعدادات — بتجمّع القائمة الفرعية ومحتوى القسم المختار بس.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  /// الكنترولر محتاج vsync عشان أنيميشن الـFade عند تبديل القسم.
  late final SettingsController _settings = _create();

  SettingsController _create() {
    final ApiClient api = context.read<ApiClient>();
    final SessionController session = context.read<SessionController>();

    return SettingsController(
      SettingsRepository(api),
      vsync: this,
      canEdit: session.can('settings:manage'),
      employees: session.can('user:view') ? EmployeesRepository(api) : null,
    )..load();
  }

  @override
  void dispose() {
    _settings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String? error = await _settings.save();
    if (!mounted) return;

    if (error == null) {
      // الكاشير والشاشات التانية بتقرا الإعدادات من هنا، فبتاخد الجديد فورًا.
      context.read<store.SettingsController>().apply(_settings.saved);
    }

    showAppSnackBar(
      context,
      error ?? 'اتحفظت الإعدادات',
      isError: error != null,
      width: 460,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<SettingsController>.value(
      value: _settings,
      child: Padding(
        padding: AppSpacing.page,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ListenableBuilder(
              listenable: _settings,
              builder: (BuildContext context, _) => ScreenHeader(
                title: 'الإعدادات',
                subtitle: _settings.canEdit
                    ? 'ضبط النظام حسب طبيعة نشاطك'
                    : 'عرض فقط — تعديل الإعدادات محتاج صلاحية',
                actions: <Widget>[
                  if (_settings.canEdit)
                    PrimaryButton(
                      label: _settings.isLoading && !_settings.isFirstLoad
                          ? 'جاري الحفظ…'
                          : 'حفظ التغييرات',
                      icon: Icons.save_outlined,
                      onPressed: _settings.dirty && !_settings.isLoading
                          ? _save
                          : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const Expanded(child: _SettingsBody()),
          ],
        ),
      ),
    );
  }
}

class _SettingsBody extends StatelessWidget {
  const _SettingsBody();

  @override
  Widget build(BuildContext context) {
    final SettingsController settings = context.watch<SettingsController>();

    if (settings.isFirstLoad) {
      return const LoadingView(message: 'بنحمّل الإعدادات…');
    }

    if (settings.hasFailed &&
        !settings.dirty &&
        settings.saved.storeName.isEmpty) {
      return ErrorView(
        message: settings.errorMessage!,
        onRetry: settings.retry,
      );
    }

    return const Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        // القائمة الفرعية (يمين في RTL)
        SizedBox(width: 272, child: SettingsSectionsList()),
        SizedBox(width: AppSpacing.xl),
        Expanded(child: SettingsContent()),
      ],
    );
  }
}
