import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../data/inventory_repository.dart';
import '../models/stock_record.dart';

/// بيعرض حركات صنف واحد في الفرع.
Future<void> showStockMovementsDialog(
  BuildContext context, {
  required InventoryRepository repository,
  required StockRecord record,
}) {
  return showDialog<void>(
    context: context,
    builder: (_) => _StockMovementsDialog(
      repository: repository,
      record: record,
    ),
  );
}

class _StockMovementsDialog extends StatefulWidget {
  const _StockMovementsDialog({
    required this.repository,
    required this.record,
  });

  final InventoryRepository repository;
  final StockRecord record;

  @override
  State<_StockMovementsDialog> createState() => _StockMovementsDialogState();
}

class _StockMovementsDialogState extends State<_StockMovementsDialog> {
  List<StockMovement> _movements = <StockMovement>[];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<StockMovement> found = await widget.repository.fetchMovements(
        branchId: widget.record.branchId,
        productId: widget.record.productId,
      );

      if (!mounted) return;
      setState(() {
        _movements = found;
        _loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.message;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 640,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          widget.record.productName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppText.sectionTitle,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'الرصيد الحالي ${Fmt.count(widget.record.onHand)} '
                          '${widget.record.unit}',
                          style: AppText.caption,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _body()),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _load);
    }

    if (_movements.isEmpty) {
      return const EmptyView(
        title: 'مفيش حركات على الصنف ده',
        icon: Icons.swap_vert_rounded,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: _movements.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (BuildContext context, int i) => _MovementTile(
        movement: _movements[i],
      ),
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.movement});

  final StockMovement movement;

  @override
  Widget build(BuildContext context) {
    final Color color =
        movement.isIncoming ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              movement.isIncoming
                  ? Icons.arrow_downward_rounded
                  : Icons.arrow_upward_rounded,
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  movement.reasonLabel,
                  style: AppText.bodyMedium.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  <String>[
                    Fmt.date(movement.createdAt),
                    if (movement.performedBy != null) movement.performedBy!,
                    if (movement.note.isNotEmpty) movement.note,
                  ].join(' • '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.caption.copyWith(fontSize: 11.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${movement.isIncoming ? '+' : '−'} '
                '${Fmt.count(movement.quantity.abs())}',
                style: AppText.amountSm.copyWith(color: color, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                'الرصيد ${Fmt.count(movement.balanceAfter)}',
                style: AppText.caption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
