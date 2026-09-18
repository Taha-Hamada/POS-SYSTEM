import 'package:flutter/material.dart';

import '../../../core/models/branch.dart';
import '../models/branch_stats.dart';

/// بيبعت بيانات الفرع للسيرفر ويرجّع رسالة الخطأ لو فشل.
typedef BranchSubmit = Future<String?> Function(BranchInput input);

/// حالة نموذج الفرع — إضافة فرع جديد أو تعديل فرع موجود.
class AddBranchController extends ChangeNotifier {
  AddBranchController({Branch? initial}) : isEditing = initial != null {
    if (initial == null) return;

    nameController.text = initial.name;
    codeController.text = initial.code;
    addressController.text = initial.address;
    phoneController.text = initial.phone;
    openFromController.text = initial.openFrom;
    openToController.text = initial.openTo;
  }

  final bool isEditing;

  final TextEditingController nameController = TextEditingController();
  final TextEditingController codeController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController openFromController = TextEditingController(
    text: '09:00',
  );
  final TextEditingController openToController = TextEditingController(
    text: '23:00',
  );

  static final RegExp _time = RegExp(r'^([01]\d|2[0-3]):[0-5]\d$');

  bool _saving = false;
  String? _error;

  bool get saving => _saving;
  String? get error => _error;

  bool get hoursValid =>
      _time.hasMatch(openFromController.text.trim()) &&
      _time.hasMatch(openToController.text.trim());

  /// نفس حدود السيرفر: الاسم والكود حرفين على الأقل، والمواعيد HH:MM.
  bool get isValid =>
      nameController.text.trim().length >= 2 &&
      codeController.text.trim().length >= 2 &&
      hoursValid;

  void fieldChanged([String? _]) => notifyListeners();

  BranchInput build() => BranchInput(
    name: nameController.text.trim(),
    code: codeController.text.trim().toUpperCase(),
    address: addressController.text.trim(),
    phone: phoneController.text.trim(),
    openFrom: openFromController.text.trim(),
    openTo: openToController.text.trim(),
  );

  /// بترجّع true لو السيرفر قبل البيانات.
  Future<bool> submit(BranchSubmit onSubmit) async {
    _saving = true;
    _error = null;
    notifyListeners();

    final String? failure = await onSubmit(build());

    _saving = false;
    _error = failure;
    notifyListeners();

    return failure == null;
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    addressController.dispose();
    phoneController.dispose();
    openFromController.dispose();
    openToController.dispose();
    super.dispose();
  }
}
