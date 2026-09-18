import 'package:flutter/material.dart';

import '../../../core/models/branch.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../models/branch_stats.dart';
import 'branch_card_header.dart';
import 'branch_info_row.dart';
import 'branch_today_sales.dart';

/// بطاقة فرع واحد في الشبكة.
class BranchCard extends StatefulWidget {
  const BranchCard({
    super.key,
    required this.stats,
    this.onEdit,
    this.onToggleOpen,
    this.onDeactivate,
  });

  final BranchStats stats;

  /// null لو المستخدم مالوش صلاحية على الإجراء، فبيستخبى.
  final VoidCallback? onEdit;
  final VoidCallback? onToggleOpen;
  final VoidCallback? onDeactivate;

  @override
  State<BranchCard> createState() => _BranchCardState();
}

class _BranchCardState extends State<BranchCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final BranchStats s = widget.stats;
    final Branch b = s.branch;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.lgAll,
          border: Border.all(
            color: _hovered
                ? AppColors.accent.withValues(alpha: 0.45)
                : AppColors.border,
          ),
          boxShadow: _hovered ? AppShadows.lifted : AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            BranchCardHeader(
              branch: b,
              onToggleOpen: widget.onToggleOpen,
              onDeactivate: widget.onDeactivate,
            ),
            const SizedBox(height: AppSpacing.lg),
            BranchInfoRow(
              icon: Icons.location_on_outlined,
              text: b.address.isEmpty ? 'لا يوجد عنوان مسجّل' : b.address,
            ),
            const SizedBox(height: AppSpacing.sm),
            BranchInfoRow(icon: Icons.schedule_rounded, text: b.openingHours),
            const Spacer(),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                BranchTodaySales(sales: s.todaySales),
                const Spacer(),
                if (widget.onEdit != null)
                  AnimatedOpacity(
                    opacity: _hovered ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: SecondaryButton(
                      label: 'تعديل',
                      size: AppButtonSize.small,
                      tone: SecondaryButtonTone.accent,
                      onPressed: widget.onEdit,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
