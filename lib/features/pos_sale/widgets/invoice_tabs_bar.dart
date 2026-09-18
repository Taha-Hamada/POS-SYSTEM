import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_session_controller.dart';
import 'invoice_tab.dart';

/// شريط الفواتير المفتوحة أعلى السلة + زرار فاتورة جديدة والمعلّقة.
class InvoiceTabsBar extends StatelessWidget {
  const InvoiceTabsBar({super.key});

  @override
  Widget build(BuildContext context) {
    final SalesSessionController session =
        context.watch<SalesSessionController>();
    final List<CartController> carts = session.carts;

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: const BoxDecoration(
        color: AppColors.surfaceAlt,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: carts.length + 1,
              separatorBuilder: (_, _) => const SizedBox(width: 5),
              itemBuilder: (BuildContext context, int i) {
                // آخر عنصر = زرار «فاتورة جديدة»
                if (i == carts.length) {
                  return Center(
                    child: IconButton(
                      tooltip: 'فاتورة جديدة',
                      onPressed: session.openNew,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.add_rounded, size: 20),
                      color: AppColors.accent,
                    ),
                  );
                }

                return Center(
                  child: ListenableBuilder(
                    listenable: carts[i],
                    builder: (BuildContext context, Widget? child) => InvoiceTab(
                      number: carts[i].number,
                      itemsCount: carts[i].itemsCount,
                      selected: i == session.activeIndex,
                      onTap: () => session.switchTo(i),
                      onClose: session.canCloseTabs
                          ? () => session.closeAt(i)
                          : null,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
