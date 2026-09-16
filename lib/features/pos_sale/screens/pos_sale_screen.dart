import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../cashier_shift/controllers/current_shift_controller.dart';
import '../controllers/cart_controller.dart';
import '../controllers/sales_session_controller.dart';
import '../data/pos_repository.dart';
import '../widgets/cart_panel.dart';
import '../widgets/products_panel.dart';

/// شاشة نقطة البيع — بتجمّع لوحة المنتجات ولوحة السلة بس.
///
/// الفواتير المفتوحة كلها في [SalesSessionController]، والشاشة بتوفّر
/// الفاتورة النشطة بس كـ[CartController] عشان باقي الويدجتس ما تحتاجش تعرف
/// إن فيه تبويبات أصلاً.
class PosSaleScreen extends StatelessWidget {
  const PosSaleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // الحساب اللي مالوش فرع بيبيع في فرع ورديته المفتوحة، فالأرصدة تبقى
    // أرصدة الفرع ده. لما الوردية تتفتح والشاشة مفتوحة، الكتالوج بيتحمّل تاني.
    final String? shiftBranchId = context.select(
      (CurrentShiftController s) => s.shift?.branchId,
    );
    final String? branchId =
        context.read<SessionController>().user?.branchId ?? shiftBranchId;

    return ChangeNotifierProvider<SalesSessionController>(
      key: ValueKey<String?>(branchId),
      create: (BuildContext context) => SalesSessionController(
        PosRepository(context.read<ApiClient>()),
        branchId: branchId,
      )..load(),
      child: const _PosSaleBody(),
    );
  }
}

class _PosSaleBody extends StatelessWidget {
  const _PosSaleBody();

  @override
  Widget build(BuildContext context) {
    final SalesSessionController session =
        context.watch<SalesSessionController>();

    if (session.isFirstLoad) {
      return const LoadingView(message: 'بنجهّز الكاشير…');
    }

    if (session.hasFailed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: ErrorView(
          message: session.errorMessage!,
          onRetry: session.retry,
        ),
      );
    }

    if (!session.hasCatalog) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: EmptyView(
          title: 'مفيش منتجات للبيع',
          description: 'ضيف منتجات من شاشة المنتجات الأول.',
          icon: Icons.inventory_2_outlined,
        ),
      );
    }

    // السيرفر بيرفض البيع من غير وردية، فبنقول للكاشير ده من الأول
    // بدل ما يملا السلة ويترفض عند الدفع.
    final CurrentShiftController shifts =
        context.watch<CurrentShiftController>();

    if (session.settings.requireOpenShift && !shifts.isOpen && !shifts.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: EmptyView(
          title: 'مفيش وردية مفتوحة',
          description:
              'افتح وردية من بطاقة الوردية تحت القائمة الجانبية عشان تبدأ البيع.',
          icon: Icons.lock_clock_rounded,
        ),
      );
    }

    return ChangeNotifierProvider<CartController>.value(
      value: session.active,
      child: const Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // المنتجات — الجزء الأكبر (يمين في RTL)
            Expanded(flex: 2, child: ProductsPanel()),
            SizedBox(width: AppSpacing.xl),
            // السلة — الجزء الأصغر (يسار في RTL)
            Expanded(child: CartPanel()),
          ],
        ),
      ),
    );
  }
}
