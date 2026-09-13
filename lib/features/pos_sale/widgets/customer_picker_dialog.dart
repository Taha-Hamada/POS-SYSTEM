import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/api/api_exception.dart';
import '../../../core/models/customer.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import '../controllers/sales_session_controller.dart';
import 'customer_picker_tile.dart';

/// يفتح حوار اختيار العميل ويرجّع العميل المختار (أو null).
Future<Customer?> showCustomerPicker(
  BuildContext context, {
  required SalesSessionController session,
}) {
  return showDialog<Customer>(
    context: context,
    builder: (BuildContext context) => CustomerPickerDialog(session: session),
  );
}

class CustomerPickerDialog extends StatefulWidget {
  const CustomerPickerDialog({super.key, required this.session});

  final SalesSessionController session;

  @override
  State<CustomerPickerDialog> createState() => _CustomerPickerDialogState();
}

class _CustomerPickerDialogState extends State<CustomerPickerDialog> {
  final TextEditingController _search = TextEditingController();

  List<Customer> _results = <Customer>[];
  bool _loading = true;
  String? _error;

  /// البحث بيروح للسيرفر، فبنستنى شوية بعد آخر حرف بدل طلب لكل ضغطة.
  Timer? _debounce;

  /// بنتجاهل رد أي بحث قديم لو المستخدم كتب حاجة جديدة بعده.
  int _requestId = 0;

  @override
  void initState() {
    super.initState();
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _runSearch(value),
    );
  }

  Future<void> _runSearch(String query) async {
    final int id = ++_requestId;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final List<Customer> found = await widget.session.searchCustomers(query);
      if (!mounted || id != _requestId) return;

      setState(() {
        _results = found;
        _loading = false;
      });
    } on ApiException catch (exception) {
      if (!mounted || id != _requestId) return;

      setState(() {
        _error = exception.message;
        _loading = false;
      });
    }
  }

  Future<void> _createCustomer() async {
    final Customer? created = await showDialog<Customer>(
      context: context,
      builder: (_) => _NewCustomerDialog(session: widget.session),
    );

    if (created != null && mounted) Navigator.of(context).pop(created);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 520,
        height: 560,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.xxl,
                AppSpacing.xxl,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              child: Row(
                children: <Widget>[
                  Text('اختيار العميل', style: AppText.sectionTitle),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: TextField(
                controller: _search,
                autofocus: true,
                onChanged: _onChanged,
                decoration: const InputDecoration(
                  hintText: 'ابحث بالاسم أو رقم الهاتف…',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(child: _body()),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: <Widget>[
                  SecondaryButton(
                    label: 'عميل جديد',
                    icon: Icons.person_add_alt_1_rounded,
                    tone: SecondaryButtonTone.accent,
                    onPressed: _createCustomer,
                  ),
                  const Spacer(),
                  // البيع النقدي مبيحتاجش حساب عميل أصلًا.
                  SecondaryButton(
                    label: 'عميل عابر',
                    onPressed: () =>
                        Navigator.of(context).pop(const Customer.walkIn()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) return const LoadingView();

    if (_error != null) {
      return ErrorView(message: _error!, onRetry: () => _runSearch(_search.text));
    }

    if (_results.isEmpty) {
      return EmptyView(
        title: _search.text.trim().isEmpty
            ? 'مفيش عملاء مسجّلين'
            : 'مفيش عميل بالاسم أو الرقم ده',
        description: 'تقدر تضيف عميل جديد من الزرار تحت.',
        icon: Icons.person_search_outlined,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _results.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (BuildContext context, int i) => CustomerPickerTile(
        customer: _results[i],
        onTap: () => Navigator.of(context).pop(_results[i]),
      ),
    );
  }
}

/// إضافة عميل سريع من شاشة الكاشير — الاسم والموبايل بس.
class _NewCustomerDialog extends StatefulWidget {
  const _NewCustomerDialog({required this.session});

  final SalesSessionController session;

  @override
  State<_NewCustomerDialog> createState() => _NewCustomerDialogState();
}

class _NewCustomerDialogState extends State<_NewCustomerDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();

  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final Customer created = await widget.session.createCustomer(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
      );

      if (mounted) Navigator.of(context).pop(created);
    } on ApiException catch (exception) {
      if (!mounted) return;

      setState(() {
        // خطأ الحقل أدق من الرسالة العامة لما السيرفر يحدّده.
        _error = exception.fieldErrors['phone'] ?? exception.message;
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('عميل جديد'),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (_error != null) ...<Widget>[
                Text(
                  _error!,
                  style: const TextStyle(color: AppColors.danger, height: 1.4),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              TextFormField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الاسم'),
                validator: (String? v) =>
                    (v == null || v.trim().length < 2) ? 'اكتب اسم العميل' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'رقم الموبايل'),
                validator: (String? v) =>
                    (v == null || v.trim().length < 7) ? 'رقم غير صالح' : null,
              ),
            ],
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}
