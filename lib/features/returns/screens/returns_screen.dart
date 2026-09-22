import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../data/returns_repository.dart';
import '../models/return_line.dart';

import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/returns_controller.dart';
import '../widgets/returns_empty_state.dart';
import '../widgets/returns_error_banner.dart';
import '../widgets/returns_invoice_view.dart';
import '../widgets/returns_search_bar.dart';

/// شاشة المرتجعات — بتجمّع البحث وعرض الفاتورة بس.
class ReturnsScreen extends StatefulWidget {
  const ReturnsScreen({super.key});

  @override
  State<ReturnsScreen> createState() => _ReturnsScreenState();
}

class _ReturnsScreenState extends State<ReturnsScreen> {
  bool _autoSelectedFull = false;

  @override
  Widget build(BuildContext context) {
    final String? invoiceNumber = GoRouterState.of(context).uri.queryParameters['invoice'];
    final String? mode = GoRouterState.of(context).uri.queryParameters['mode'];

    return ChangeNotifierProvider<ReturnsController>(
      create: (_) => ReturnsController(
        ReturnsRepository(context.read<ApiClient>()),
      ),
      child: Consumer<ReturnsController>(
        builder: (
          BuildContext context,
          ReturnsController returns,
          Widget? child,
        ) {
          if (invoiceNumber != null &&
              invoiceNumber.isNotEmpty &&
              returns.searchController.text.isEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted || returns.searchController.text.isNotEmpty) return;
              returns.search(invoiceNumber);
            });
          }

          if (mode == 'full' && returns.hasInvoice && !_autoSelectedFull) {
            _autoSelectedFull = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              for (final ReturnLine line in returns.lines) {
                returns.setLineSelected(line, true);
                returns.setReturnQuantity(line, line.maxQuantity);
              }
              if (returns.reason == null) {
                returns.setReason(kReturnReasons.first);
              }
            });
          }

          if (mode != 'full') {
            _autoSelectedFull = false;
          }

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'المرتجعات',
                  subtitle: 'استرجاع أصناف من فاتورة مبيعات سابقة',
                  actions: <Widget>[
                    SecondaryButton(
                      label: 'سجل المرتجعات',
                      icon: Icons.history_rounded,
                      onPressed: () => context.go('/returns/history'),
                    ),
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
