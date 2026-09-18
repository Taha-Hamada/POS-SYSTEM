import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../controllers/payment_controller.dart';
import '../models/payment_result.dart';
import '../widgets/payment_content.dart';
import '../widgets/payment_success_view.dart';

/// يفتح شاشة الدفع ويرجّع النتيجة (أو null لو اتلغت).
Future<PaymentResult?> showPaymentDialog({
  required BuildContext context,
  required double total,
  required double itemsCount,
  required String customerName,
}) {
  return showDialog<PaymentResult>(
    context: context,
    barrierColor: AppColors.primary.withValues(alpha: 0.45),
    builder: (BuildContext context) => PaymentDialog(
      total: total,
      itemsCount: itemsCount,
      customerName: customerName,
    ),
  );
}

/// شاشة الدفع — بتجمّع الهيدر والعمودين والفوتر، وبتدير شاشة النجاح.
class PaymentDialog extends StatefulWidget {
  const PaymentDialog({
    super.key,
    required this.total,
    required this.itemsCount,
    required this.customerName,
  });

  final double total;
  final double itemsCount;
  final String customerName;

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog>
    with SingleTickerProviderStateMixin {
  late final PaymentController _payment;

  bool _success = false;

  /// بيتعمل في initState مش lazily — عشان لو الحوار اتقفل من غير تأكيد
  /// ما يحاولش ينشئه جوه dispose (ده بيرمي استثناء).
  late final AnimationController _successController;

  @override
  void initState() {
    super.initState();
    _payment = PaymentController(total: widget.total);
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _successController.dispose();
    _payment.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final PaymentResult result = _payment.buildResult();

    setState(() => _success = true);
    await _successController.forward();
    await Future<void>.delayed(const Duration(milliseconds: 550));

    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final Size screen = MediaQuery.sizeOf(context);

    return ChangeNotifierProvider<PaymentController>.value(
      value: _payment,
      child: Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.xxl),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 960,
            maxHeight: screen.height - 80,
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: _success
                ? PaymentSuccessView(animation: _successController)
                : PaymentContent(
                    itemsCount: widget.itemsCount,
                    customerName: widget.customerName,
                    onConfirm: _confirm,
                  ),
          ),
        ),
      ),
    );
  }
}
