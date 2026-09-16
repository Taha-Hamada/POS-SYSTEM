import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

/// رد ناجح من الـ API بعد ما اتفك.
class ApiResponse {
  const ApiResponse({required this.data, this.message, this.meta});

  final dynamic data;
  final String? message;
  final Map<String, dynamic>? meta;

  /// بيانات الترقيم لما الرد يكون صفحة من قايمة.
  int get total => (meta?['pagination']?['total'] as int?) ?? 0;
  int get pages => (meta?['pagination']?['pages'] as int?) ?? 1;
  bool get hasNext => (meta?['pagination']?['hasNext'] as bool?) ?? false;

  /// الشكل الغلط بيرجّع فاضي بدل ما يرمي خطأ نوع خام،
  /// عشان الشاشة تعرض رسالة مفهومة مش انهيار.
  List<Map<String, dynamic>> get list => data is List<dynamic>
      ? (data as List<dynamic>).whereType<Map<String, dynamic>>().toList()
      : <Map<String, dynamic>>[];

  Map<String, dynamic> get object =>
      data is Map<String, dynamic> ? data as Map<String, dynamic> : <String, dynamic>{};
}

/// بيتنادى لما السيرفر يقول إن الجلسة انتهت، عشان التطبيق يوديه لشاشة الدخول.
typedef UnauthorizedHandler = Future<void> Function();

/// العميل اللي بيكلّم الباك اند.
///
/// كل الطلبات بتعدي من هنا عشان يكون فيه مكان واحد بيحط التوكن،
/// بيفك شكل الرد الموحّد، وبيحوّل الأخطاء لـ [ApiException] مفهومة.
class ApiClient {
  ApiClient({http.Client? httpClient})
      : _http = httpClient ?? http.Client();

  final http.Client _http;

  String? _accessToken;
  String? _refreshToken;
  UnauthorizedHandler? onUnauthorized;

  /// بيمنع أكتر من طلب فاشل إنهم يعملوا تجديد للتوكن في نفس اللحظة.
  Future<bool>? _refreshInFlight;

  bool get hasSession => _accessToken != null;

  void setTokens({String? accessToken, String? refreshToken}) {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  void clearTokens() {
    _accessToken = null;
    _refreshToken = null;
  }

  Future<ApiResponse> get(String path, {Map<String, dynamic>? query}) =>
      _send('GET', path, query: query);

  Future<ApiResponse> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<ApiResponse> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<ApiResponse> delete(String path) => _send('DELETE', path);

  /// رفع ملف واحد multipart — صور المنتجات.
  Future<ApiResponse> upload(
    String path, {
    required String field,
    required List<int> bytes,
    required String filename,
    bool allowRetry = true,
  }) async {
    final Uri uri = _buildUri(path, null);

    http.Response response;
    try {
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..files.add(
          http.MultipartFile.fromBytes(field, bytes, filename: filename),
        );
      if (_accessToken != null) {
        request.headers['Authorization'] = 'Bearer $_accessToken';
      }

      final http.StreamedResponse streamed = await _http
          .send(request)
          .timeout(ApiConfig.timeout);
      response = await http.Response.fromStream(streamed);
    } on TimeoutException {
      throw const ApiException.timeout();
    } catch (_) {
      throw const ApiException.network();
    }

    if (response.statusCode == 401 && allowRetry && _refreshToken != null) {
      if (await _refreshSession()) {
        return upload(
          path,
          field: field,
          bytes: bytes,
          filename: filename,
          allowRetry: false,
        );
      }
    }

    return _parse(response);
  }

  // ── التنفيذ ────────────────────────────────────────────────────────────────

  Future<ApiResponse> _send(
    String method,
    String path, {
    Map<String, dynamic>? query,
    Object? body,
    bool allowRetry = true,
  }) async {
    final Uri uri = _buildUri(path, query);

    http.Response response;
    try {
      response = await _dispatch(method, uri, body).timeout(ApiConfig.timeout);
    } on TimeoutException {
      throw const ApiException.timeout();
    } catch (_) {
      throw const ApiException.network();
    }

    // التوكن خلص: نجدّده مرة واحدة ونعيد نفس الطلب.
    if (response.statusCode == 401 && allowRetry && _refreshToken != null) {
      if (await _refreshSession()) {
        return _send(method, path, query: query, body: body, allowRetry: false);
      }
    }

    return _parse(response);
  }

  Future<http.Response> _dispatch(String method, Uri uri, Object? body) {
    final Map<String, String> headers = <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
    };

    final String? encoded = body == null ? null : jsonEncode(body);

    return switch (method) {
      'GET' => _http.get(uri, headers: headers),
      'POST' => _http.post(uri, headers: headers, body: encoded),
      'PATCH' => _http.patch(uri, headers: headers, body: encoded),
      'DELETE' => _http.delete(uri, headers: headers),
      _ => throw ArgumentError('طريقة غير مدعومة: $method'),
    };
  }

  Uri _buildUri(String path, Map<String, dynamic>? query) {
    // القيم الفاضية بتتشال عشان مبنبعتش فلاتر مالهاش لازمة.
    final Map<String, String> params = <String, String>{};

    query?.forEach((String key, dynamic value) {
      if (value == null) return;
      if (value is String && value.isEmpty) return;
      params[key] = value.toString();
    });

    return Uri.parse('${ApiConfig.baseUrl}$path')
        .replace(queryParameters: params.isEmpty ? null : params);
  }

  ApiResponse _parse(http.Response response) {
    Map<String, dynamic> payload;

    try {
      payload = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException(
        message: 'رد غير مفهوم من السيرفر',
        statusCode: response.statusCode,
        code: 'BAD_RESPONSE',
      );
    }

    if (payload['success'] == true) {
      return ApiResponse(
        data: payload['data'],
        message: payload['message'] as String?,
        meta: payload['meta'] as Map<String, dynamic>?,
      );
    }

    throw _toException(payload, response.statusCode);
  }

  ApiException _toException(Map<String, dynamic> payload, int statusCode) {
    final Map<String, dynamic> error =
        (payload['error'] as Map<String, dynamic>?) ?? <String, dynamic>{};

    final Map<String, String> fields = <String, String>{};

    for (final dynamic item in (error['details'] as List<dynamic>? ?? <dynamic>[])) {
      if (item is! Map<String, dynamic>) continue;
      final String? field = item['field'] as String?;
      final String? message = item['message'] as String?;
      if (field != null && message != null) fields[field] = message;
    }

    return ApiException(
      message: (payload['message'] as String?) ?? 'حصل خطأ غير متوقع',
      statusCode: statusCode,
      code: error['code'] as String?,
      fieldErrors: fields,
    );
  }

  /// بيجدّد التوكن. لو فشل، معناها إن الجلسة راحت خلاص.
  Future<bool> _refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  Future<bool> _doRefresh() async {
    try {
      final http.Response response = await _http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/auth/refresh'),
            headers: <String, String>{'Content-Type': 'application/json'},
            body: jsonEncode(<String, String>{'refreshToken': _refreshToken!}),
          )
          .timeout(ApiConfig.timeout);

      if (response.statusCode != 200) {
        await _handleSessionLost();
        return false;
      }

      final Map<String, dynamic> payload =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final Map<String, dynamic> tokens =
          payload['data']['tokens'] as Map<String, dynamic>;

      setTokens(
        accessToken: tokens['accessToken'] as String?,
        refreshToken: tokens['refreshToken'] as String?,
      );

      return true;
    } catch (_) {
      await _handleSessionLost();
      return false;
    }
  }

  Future<void> _handleSessionLost() async {
    clearTokens();
    await onUnauthorized?.call();
  }

  void dispose() => _http.close();
}
