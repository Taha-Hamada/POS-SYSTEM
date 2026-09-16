import 'package:flutter/material.dart';

/// تبويبات نموذج المنتج بالترتيب اللي بتظهر بيه.
enum ProductFormTab { basic, pricing, variants, stock, barcode }

extension ProductFormTabInfo on ProductFormTab {
  String get label => switch (this) {
    ProductFormTab.basic => 'بيانات أساسية',
    ProductFormTab.pricing => 'التسعير',
    ProductFormTab.variants => 'المتغيرات',
    ProductFormTab.stock => 'المخزون والوحدات',
    ProductFormTab.barcode => 'الباركود',
  };

  IconData get icon => switch (this) {
    ProductFormTab.basic => Icons.description_outlined,
    ProductFormTab.pricing => Icons.sell_outlined,
    ProductFormTab.variants => Icons.tune_rounded,
    ProductFormTab.stock => Icons.warehouse_outlined,
    ProductFormTab.barcode => Icons.qr_code_2_rounded,
  };
}
