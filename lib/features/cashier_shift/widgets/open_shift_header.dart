import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

import '../../../core/session/auth_user.dart';
import '../../../core/session/session_controller.dart';
import '../../../theme/app_theme.dart';

/// هيدر حوار بدء الوردية: أيقونة كبيرة + اسم الكاشير والفرع.
class OpenShiftHeader extends StatelessWidget {
  const OpenShiftHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthUser? user = context.read<SessionController>().user;

    return Column(
      children: <Widget>[
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: <Color>[AppColors.accent, Color(0xFF8B5CF6)],
            ),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.34),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.point_of_sale_rounded,
            size: 34,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'بدء وردية جديدة',
          textAlign: TextAlign.center,
          style: AppText.pageTitle.copyWith(fontSize: 23),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          '${user?.name ?? ''} • ${user?.branchName ?? ''}',
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
      ],
    );
  }
}
