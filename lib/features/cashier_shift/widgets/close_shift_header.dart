import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/shift.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/shift_controller.dart';

/// هيدر حوار إغلاق الوردية: رقم الوردية والكاشير ووقت البدء.
class CloseShiftHeader extends StatelessWidget {
  const CloseShiftHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final Shift? shift = context.read<ShiftController>().shift;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.xxl,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(AppRadius.xl),
          topLeft: Radius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.lock_clock_rounded,
              size: 21,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text('إغلاق الوردية', style: AppText.sectionTitle),
                const SizedBox(height: 2),
                Text(
                  'وردية ${shift?.number ?? '—'} • '
                  '${shift?.cashierName ?? '—'} • '
                  'بدأت ${shift == null ? '—' : Fmt.time(shift.openedAt)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'إغلاق',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}
