import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// بتتعرض أثناء قراءة الجلسة المحفوظة عند تشغيل التطبيق.
///
/// من غيرها التطبيق كان بيعرض الشاشة الرئيسية لحظة وبعدين يقفز لشاشة الدخول،
/// والوميض ده بيبان غلط وبيخلي سلوك التطبيق غير متوقّع.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              Icons.point_of_sale_rounded,
              size: 48,
              color: AppColors.primary,
            ),
            SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}
