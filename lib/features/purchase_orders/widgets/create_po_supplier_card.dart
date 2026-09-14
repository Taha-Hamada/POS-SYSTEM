import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/models/branch.dart';
import '../../../core/models/supplier.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/labeled_field.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/create_purchase_order_controller.dart';
import 'create_po_supplier_contact.dart';

/// بطاقة اختيار المورد وفرع الاستلام وموعد التسليم المتوقع.
class CreatePoSupplierCard extends StatelessWidget {
  const CreatePoSupplierCard({super.key});

  Future<void> _pickDate(
    BuildContext context,
    CreatePurchaseOrderController draft,
  ) async {
    final DateTime now = DateTime.now();

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: draft.expectedDate ?? now.add(const Duration(days: 7)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) draft.setExpectedDate(picked);
  }

  @override
  Widget build(BuildContext context) {
    final CreatePurchaseOrderController draft =
        context.watch<CreatePurchaseOrderController>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: AppDecorations.card(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Expanded(
            flex: 2,
            child: LabeledField(
              label: 'المورد',
              child: AppDropdown<String?>(
                value: draft.supplierId,
                width: double.infinity,
                height: 48,
                icon: Icons.local_shipping_outlined,
                onChanged: draft.setSupplier,
                items: <AppDropdownItem<String?>>[
                  // الموقوفين مش هنا: السيرفر بيرفض أمر شراء لمورد معطّل.
                  for (final Supplier s in draft.suppliers)
                    AppDropdownItem<String?>(
                      value: s.id,
                      label: s.name,
                      icon: Icons.storefront_outlined,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: LabeledField(
              label: 'فرع الاستلام',
              child: AppDropdown<String?>(
                value: draft.branchId,
                width: double.infinity,
                height: 48,
                icon: Icons.store_outlined,
                onChanged: draft.setBranch,
                items: <AppDropdownItem<String?>>[
                  for (final Branch b in draft.branches)
                    AppDropdownItem<String?>(value: b.id, label: b.name),
                ],
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: LabeledField(
              label: 'التسليم المتوقع',
              child: SizedBox(
                height: 48,
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(context, draft),
                  icon: const Icon(Icons.event_outlined, size: 17),
                  label: Text(
                    draft.expectedDate == null
                        ? 'اختياري'
                        : Fmt.date(draft.expectedDate!),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xl),
          const Expanded(flex: 2, child: CreatePoSupplierContact()),
        ],
      ),
    );
  }
}
