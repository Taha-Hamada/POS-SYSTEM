import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';

/// معاينة الباركود الحقيقي — نفس اللي بيتطبع على الملصق.
class BarcodePreview extends StatelessWidget {
  const BarcodePreview({super.key});

  /// EAN-13 لو الرقم صالح، وإلا Code128 اللي بيقبل أي كود.
  static Barcode symbologyFor(String data) {
    final Barcode ean = Barcode.ean13();
    return data.length == 13 && ean.isValid(data) ? ean : Barcode.code128();
  }

  @override
  Widget build(BuildContext context) {
    final String barcode = context.select(
      (ProductFormController f) => f.barcode,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 300,
            height: 96,
            child: barcode.isEmpty
                ? Center(
                    child: Text(
                      'مفيش باركود لسه',
                      style: AppText.caption.copyWith(fontSize: 13),
                    ),
                  )
                : SvgPicture.string(
                    symbologyFor(
                      barcode,
                    ).toSvg(barcode, width: 300, height: 96, drawText: false),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            barcode.isEmpty ? '—' : barcode,
            style: AppText.amountMd.copyWith(fontSize: 17, letterSpacing: 4),
          ),
        ],
      ),
    );
  }
}
