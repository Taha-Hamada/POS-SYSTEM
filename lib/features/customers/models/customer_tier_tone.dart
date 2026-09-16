import '../../../core/widgets/status_badge.dart';

/// مجموعات العملاء زي ما الباك اند بيسمّيها.
///
/// بتتخزّن كنص مش enum لأن السيرفر ممكن يضيف مجموعة جديدة من غير ما التطبيق
/// يتحدّث، والقيمة الغريبة بتتعرض زي ما هي بدل ما تكسر الشاشة.
const List<String> kCustomerTiers = <String>[
  'regular',
  'silver',
  'gold',
  'platinum',
];

extension CustomerTierTone on String {
  StatusTone get tierTone => switch (this) {
    'platinum' => StatusTone.success,
    'gold' => StatusTone.warning,
    'silver' => StatusTone.info,
    _ => StatusTone.neutral,
  };

  /// الاسم المختصر المستخدم في فلتر المجموعات.
  String get tierLabel => switch (this) {
    'platinum' => 'بلاتيني',
    'gold' => 'ذهبي',
    'silver' => 'فضي',
    'regular' => 'عادي',
    _ => this,
  };
}
