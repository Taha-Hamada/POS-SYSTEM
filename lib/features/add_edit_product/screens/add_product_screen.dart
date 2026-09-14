import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../products_list/data/products_repository.dart';
import '../controllers/product_form_controller.dart';
import '../widgets/add_product_footer.dart';
import '../widgets/add_product_header.dart';
import '../widgets/product_form_tab_bar.dart';
import '../widgets/product_form_tab_views.dart';

/// شاشة إضافة/تعديل منتج — بتجمّع الهيدر والتبويبات والشريط السفلي بس.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen>
    with SingleTickerProviderStateMixin {
  late final ProductFormController _form;

  @override
  void initState() {
    super.initState();

    // الكنترولر محتاج vsync عشان الـTabController اللي جواه.
    _form = ProductFormController(
      ProductsRepository(context.read<ApiClient>()),
      vsync: this,
      // الرصيد الافتتاحي بيتسجل في فرع المستخدم اللي بيضيف المنتج.
      branchId: context.read<SessionController>().user?.branchId,
    )..load();
  }

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProductFormController>.value(
      value: _form,
      child: const _AddProductBody(),
    );
  }
}

class _AddProductBody extends StatelessWidget {
  const _AddProductBody();

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();

    // الأقسام جاية من السيرفر، والفورم مينفعش يتملى من غيرها.
    if (form.isFirstLoad) {
      return const LoadingView(message: 'بنجهّز النموذج…');
    }

    if (form.hasFailed) {
      return ErrorView(message: form.errorMessage!, onRetry: form.retry);
    }

    return const Column(
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xxl,
              AppSpacing.xxl,
              AppSpacing.xxl,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                AddProductHeader(),
                SizedBox(height: AppSpacing.xl),
                ProductFormTabBar(),
                SizedBox(height: AppSpacing.lg),
                Expanded(child: ProductFormTabViews()),
              ],
            ),
          ),
        ),
        AddProductFooter(),
      ],
    );
  }
}
