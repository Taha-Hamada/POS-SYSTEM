import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/purchase_order.dart';
import '../../../theme/app_theme.dart';
import '../controllers/receive_goods_controller.dart';
import '../data/purchases_repository.dart';
import '../widgets/receive_goods_footer.dart';
import '../widgets/receive_goods_header.dart';
import '../widgets/receive_lines_table.dart';
import '../widgets/receive_progress_bar.dart';

/// يفتح Modal استلام البضاعة ويرجّع الأمر بعد التحديث، أو `null` لو اتلغى.
///
/// [order] لازم يكون متقري كامل بسطوره — قايمة الأوامر بترجع من غيرها.
Future<PurchaseOrder?> showReceiveGoodsDialog(
  BuildContext context,
  PurchaseOrder order,
) {
  final PurchasesRepository repository =
      PurchasesRepository(context.read<ApiClient>());

  return showDialog<PurchaseOrder>(
    context: context,
    barrierColor: AppColors.primary.withValues(alpha: 0.45),
    builder: (BuildContext context) =>
        ChangeNotifierProvider<ReceiveGoodsController>(
      create: (_) => ReceiveGoodsController(repository, order: order),
      child: const ReceiveGoodsDialog(),
    ),
  );
}

/// حوار الاستلام — بيجمّع الهيدر وشريط التقدّم والجدول والفوتر بس.
class ReceiveGoodsDialog extends StatelessWidget {
  const ReceiveGoodsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return Dialog(
      insetPadding: const EdgeInsets.all(AppSpacing.xxl),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 940,
          maxHeight: screen.height - 80,
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ReceiveGoodsHeader(),
            ReceiveProgressBar(),
            Flexible(child: ReceiveLinesTable()),
            ReceiveGoodsFooter(),
          ],
        ),
      ),
    );
  }
}
