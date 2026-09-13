/// خطأ جاي من الـ API أو من الشبكة نفسها.
///
/// الباك اند بيرجّع `{ success, message, error: { code, details } }`،
/// فبنحتفظ بالرسالة الجاهزة للعرض وبالكود اللي بنفرّق بيه الحالات في الكود.
class ApiException implements Exception {
  const ApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.fieldErrors = const <String, String>{},
  });

  /// الشبكة نفسها فشلت — السيرفر مقفول أو مفيش نت.
  const ApiException.network()
      : message = 'مقدرناش نوصل للسيرفر. اتأكد إنه شغال وإن الشبكة متاحة',
        statusCode = null,
        code = 'NETWORK_ERROR',
        fieldErrors = const <String, String>{};

  const ApiException.timeout()
      : message = 'السيرفر أخد وقت طويل ومردّش',
        statusCode = null,
        code = 'TIMEOUT',
        fieldErrors = const <String, String>{};

  final String message;
  final int? statusCode;
  final String? code;

  /// أخطاء التحقق مرتّبة باسم الحقل عشان الفورم يعرضها جنب كل خانة.
  final Map<String, String> fieldErrors;

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidation => code == 'VALIDATION_ERROR';

  /// الجلسة سقطت وبتحتاج دخول من جديد.
  bool get needsReauth =>
      statusCode == 401 || code == 'SESSION_REVOKED' || code == 'TOKEN_EXPIRED';

  @override
  String toString() => 'ApiException($statusCode/$code): $message';
}
