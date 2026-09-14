import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/settings_controller.dart';
import '../data/returns_repository.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/returns_controller.dart';
import '../widgets/returns_empty_state.dart';
import '../widgets/returns_error_banner.dart';
import '../widgets/returns_invoice_view.dart';
import '../widgets/returns_search_bar.dart';

/// شاشة المرتجعات — بتجمّع البحث وعرض الفاتورة بس.
class ReturnsScreen extends StatelessWidget {
  const ReturnsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ReturnsController>(
      create: (_) => ReturnsController(
        ReturnsRepository(context.read<ApiClient>()),
        taxRate: context.read<SettingsController>().taxRate,
      ),
      child: Consumer<ReturnsController>(
        builder: (
          BuildContext context,
          ReturnsController returns,
          Widget? child,
        ) {
          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'المرتجعات',
                  subtitle: 'استرجاع أصناف من فاتورة مبيعات سابقة',
                  actions: <Widget>[
                    if (returns.hasInvoice)
                      SecondaryButton(
                        label: 'فاتورة جديدة',
                        icon: Icons.refresh_rounded,
                        onPressed: returns.clear,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const ReturnsSearchBar(),
                if (returns.error != null) ...<Widget>[
                  const SizedBox(height: AppSpacing.md),
                  ReturnsErrorBanner(message: returns.error!),
                ],
                const SizedBox(height: AppSpacing.xl),
                Expanded(
                  child: returns.hasInvoice
                      ? const ReturnsInvoiceView()
                      : const ReturnsEmptyState(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
