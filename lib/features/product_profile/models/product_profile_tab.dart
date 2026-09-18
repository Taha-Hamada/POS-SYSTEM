import 'package:flutter/material.dart';

/// تبويبات شاشة تفاصيل المنتج.
enum ProductProfileTab { details, branches, movements }

extension ProductProfileTabInfo on ProductProfileTab {
  String get label => switch (this) {
        ProductProfileTab.details => 'البيانات',
        ProductProfileTab.branches => 'الأرصدة',
        ProductProfileTab.movements => 'الحركات',
      };

  IconData get icon => switch (this) {
        ProductProfileTab.details => Icons.description_outlined,
        ProductProfileTab.branches => Icons.store_mall_directory_outlined,
        ProductProfileTab.movements => Icons.swap_vert_rounded,
      };
}
