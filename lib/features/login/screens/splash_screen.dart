import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

/// بتتعرض أثناء قراءة الجلسة المحفوظة عند تشغيل التطبيق.
///
/// من غيرها التطبيق كان بيعرض الشاشة الرئيسية لحظة وبعدين يقفز لشاشة الدخول،
/// والوميض ده بيبان غلط وبيخلي سلوك التطبيق غير متوقّع.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// أنيميشن دخول لمرة واحدة — مش متكرر عشان الاختبارات تقدر تستقر.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
  )..forward();

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _AppLogo(size: 132),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'نظام نقاط البيع',
                  style: AppText.pageTitle,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'إدارة المبيعات والمخزون',
                  style: AppText.caption,
                ),
                const SizedBox(height: AppSpacing.xxl),
                const SizedBox(
                  width: 26,
                  height: 26,
                  child: CircularProgressIndicator(strokeWidth: 2.6),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// أيقونة التطبيق بظل خفيف — نفس الأيقونة اللي على سطح المكتب.
class _AppLogo extends StatelessWidget {
  const _AppLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.accentDark.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        'assets/icon/app_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}
