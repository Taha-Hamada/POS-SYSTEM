/// فترة شاشات السجلات: المرتجعات والفواتير والورديات.
enum HistoryPeriod {
  today('النهاردة'),
  week('آخر 7 أيام'),
  month('آخر 30 يوم'),
  all('الكل');

  const HistoryPeriod(this.label);

  final String label;

  /// بداية الفترة من أول اليوم، أو null للكل.
  DateTime? get from {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);

    return switch (this) {
      HistoryPeriod.today => today,
      HistoryPeriod.week => today.subtract(const Duration(days: 6)),
      HistoryPeriod.month => today.subtract(const Duration(days: 29)),
      HistoryPeriod.all => null,
    };
  }
}
