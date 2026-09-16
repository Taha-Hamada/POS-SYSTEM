import '../../../core/api/api_client.dart';
import '../../../core/models/shift.dart';

/// نتيجة قراءة الوردية الحالية — الوردية وأرقامها مع بعض.
typedef ShiftSnapshot = ({Shift shift, ShiftTotals totals});

class ShiftRepository {
  const ShiftRepository(this._api);

  final ApiClient _api;

  /// ورديتي المفتوحة دلوقتي، أو null لو مفيش.
  Future<ShiftSnapshot?> fetchCurrent() async {
    final ApiResponse response = await _api.get('/shifts/current');

    // السيرفر بيرجّع data فاضية لما الكاشير ميكونش فاتح وردية.
    // وبنتأكد من وجود الوردية جوه الرد كمان، عشان أي شكل غير متوقع
    // يبان كـ«مفيش وردية» بدل ما يكسر الشاشة.
    if (response.data == null) return null;
    if (response.object['shift'] is! Map<String, dynamic>) return null;

    return _snapshotFrom(response.object);
  }

  Future<ShiftSnapshot> open({
    required double openingBalance,
    String? branchId,
  }) async {
    final ApiResponse response = await _api.post(
      '/shifts',
      body: <String, dynamic>{
        'openingBalance': openingBalance,
        // الفرع بيتشال من الطلب لو مش محدد، والسيرفر بياخد فرع المستخدم.
        'branch': ?branchId,
      },
    );

    // رد الفتح بيرجّع الوردية لوحدها من غير أرقام، وأصفار هنا معناها
    // إن الدرج بيبان فاضي رغم إن فيه الرصيد الافتتاحي. فبنقرا الأرقام
    // من السيرفر عشان الكاشير يشوف الدرج صح من أول لحظة.
    final Shift opened = Shift.fromJson(response.object);

    return fetchById(opened.id);
  }

  Future<Shift> close(
    String id, {
    required double countedCash,
    String? note,
  }) async {
    final ApiResponse response = await _api.post(
      '/shifts/$id/close',
      body: <String, dynamic>{
        'countedCash': countedCash,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );

    return Shift.fromJson(response.object);
  }

  /// إيداع أو سحب كاش من الدرج أثناء الوردية.
  Future<void> addCashMovement(
    String id, {
    required bool isIn,
    required double amount,
    required String reason,
  }) => _api.post(
    '/shifts/$id/cash',
    body: <String, dynamic>{
      'direction': isIn ? 'in' : 'out',
      'amount': amount,
      'reason': reason,
    },
  );

  Future<ShiftSnapshot> fetchById(String id) async {
    final ApiResponse response = await _api.get('/shifts/$id');
    return _snapshotFrom(response.object);
  }

  /// سجل الورديات — السيرفر بيقصره على فرع المستخدم لو مربوط بفرع.
  Future<({List<Shift> items, int total})> fetchPage({
    DateTime? from,
    String? status,
    int page = 1,
    int limit = 100,
  }) async {
    final ApiResponse response = await _api.get(
      '/shifts',
      query: <String, dynamic>{
        'page': page,
        'limit': limit,
        'from': from?.toUtc().toIso8601String(),
        'status': status,
      },
    );

    return (
      items: response.list.map(Shift.fromJson).toList(),
      total: response.total,
    );
  }

  ShiftSnapshot _snapshotFrom(Map<String, dynamic> json) => (
    shift: Shift.fromJson(json['shift'] as Map<String, dynamic>),
    totals: ShiftTotals.fromJson(
      (json['totals'] as Map<String, dynamic>?) ?? <String, dynamic>{},
    ),
  );
}
