import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import '../api/api_exception.dart';
import 'auth_user.dart';
import 'session_storage.dart';

enum SessionStatus {
  /// لسه بنقرأ التوكن المحفوظ ونتأكد إنه لسه صالح.
  checking,
  authenticated,
  unauthenticated,
}

/// حالة الدخول في التطبيق كله.
///
/// هي المالك الوحيد للتوكن: بتحطّه في [ApiClient] وبتحفظه على الجهاز،
/// فمفيش شاشة تانية محتاجة تعرف حاجة عن التوكنات.
class SessionController extends ChangeNotifier {
  SessionController(this._api, {SessionStorage? storage})
      : _storage = storage ?? SessionStorage() {
    // لما السيرفر يرفض التوكن ومحاولة التجديد تفشل، بنرجّع المستخدم لشاشة الدخول.
    _api.onUnauthorized = _onSessionLost;
  }

  final ApiClient _api;
  final SessionStorage _storage;

  SessionStatus _status = SessionStatus.checking;
  AuthUser? _user;
  String? _error;
  bool _busy = false;

  SessionStatus get status => _status;
  AuthUser? get user => _user;
  String? get error => _error;
  bool get busy => _busy;
  bool get isAuthenticated => _status == SessionStatus.authenticated;

  bool can(String permission) => _user?.can(permission) ?? false;

  /// بتتنادى مرة واحدة عند تشغيل التطبيق.
  Future<void> restore() async {
    final ({String? access, String? refresh}) saved = await _storage.read();

    if (saved.access == null || saved.refresh == null) {
      _set(SessionStatus.unauthenticated);
      return;
    }

    _api.setTokens(accessToken: saved.access, refreshToken: saved.refresh);

    // بنسأل السيرفر عن الحساب: ده بيتأكد إن التوكن لسه صالح
    // وبيجيب الصلاحيات الحالية في نفس الوقت.
    try {
      final ApiResponse response = await _api.get('/auth/me');
      _user = AuthUser.fromJson(response.object);
      _set(SessionStatus.authenticated);
    } on ApiException {
      await _clear();
    }
  }

  Future<bool> login({required String username, required String password}) async {
    _busy = true;
    _error = null;
    notifyListeners();

    try {
      final ApiResponse response = await _api.post(
        '/auth/login',
        body: <String, String>{'username': username, 'password': password},
      );

      await _adopt(response.object);
      return true;
    } on ApiException catch (exception) {
      _error = exception.message;
      _set(SessionStatus.unauthenticated);
      return false;
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _clear();
  }

  /// بياخد رد الدخول (مستخدم + توكنات) ويثبّته في كل مكان.
  Future<void> _adopt(Map<String, dynamic> payload) async {
    final Map<String, dynamic> tokens = payload['tokens'] as Map<String, dynamic>;
    final String access = tokens['accessToken'] as String;
    final String refresh = tokens['refreshToken'] as String;

    _api.setTokens(accessToken: access, refreshToken: refresh);
    await _storage.save(access: access, refresh: refresh);

    _user = AuthUser.fromJson(payload['user'] as Map<String, dynamic>);
    _set(SessionStatus.authenticated);
  }

  Future<void> _onSessionLost() async {
    _error = 'انتهت الجلسة، سجّل دخول تاني';
    await _clear();
  }

  Future<void> _clear() async {
    _api.clearTokens();
    await _storage.clear();
    _user = null;
    _set(SessionStatus.unauthenticated);
  }

  void _set(SessionStatus next) {
    _status = next;
    notifyListeners();
  }
}
