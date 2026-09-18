import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_tab_bar.dart';
import '../../../core/widgets/icon_tab_label.dart';
import '../controllers/product_profile_controller.dart';
import '../models/product_profile_tab.dart';

/// شريط تبويبات تفاصيل المنتج.
class ProductProfileTabBar extends StatelessWidget {
  const ProductProfileTabBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppTabBar(
      controller: context.read<ProductProfileController>().tabController,
      tabs: <Widget>[
        for (final ProductProfileTab tab in ProductProfileTab.values)
          IconTabLabel(icon: tab.icon, label: tab.label),
      ],
    );
  }
}
