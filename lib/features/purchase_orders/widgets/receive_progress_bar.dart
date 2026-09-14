import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/receive_goods_controller.dart';

/// شريط نسبة الاستلام فوق جدول الأصناف.
class ReceiveProgressBar extends StatelessWidget {
  const ReceiveProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final ReceiveGoodsController receive =
        context.watch<ReceiveGoodsController>();
    final bool isComplete = receive.isComplete;
    final double progress = receive.progress;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        0,
        AppSpacing.xxl,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'نسبة الاستلام',
                style: AppText.label.copyWith(fontSize: 12.5),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '${Fmt.count(receive.receivedTotal.round())} من '
                '${Fmt.count(receive.orderedTotal.round())} وحدة',
                style: AppText.caption.copyWith(fontSize: 12),
              ),
              const Spacer(),
              Text(
                '${(progress * 100).round()}%',
                style: AppText.amountMd.copyWith(
                  fontSize: 17,
                  color: isComplete ? AppColors.success : AppColors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Stack(
              children: <Widget>[
                Container(height: 10, color: AppColors.surfaceAlt),
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints c) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 260),
                      curve: Curves.easeOut,
                      height: 10,
                      width: c.maxWidth * progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isComplete
                              ? <Color>[
                                  AppColors.success,
                                  const Color(0xFF34D399),
                                ]
                              : <Color>[
                                  AppColors.accent,
                                  const Color(0xFF8B5CF6),
                                ],
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
