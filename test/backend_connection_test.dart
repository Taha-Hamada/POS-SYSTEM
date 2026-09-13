import 'package:flutter_test/flutter_test.dart';
import 'package:pos_system/core/api/api_client.dart';
import 'package:pos_system/core/api/api_config.dart';
import 'package:pos_system/core/api/api_exception.dart';
import 'package:pos_system/core/session/auth_user.dart';
import 'package:pos_system/core/session/session_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// اختبار وصل بين الفرونت والباك اند.
///
/// بيشتغل على الباك اند الحقيقي، فلازم يكون شغال ومتعمله seed:
///   cd ../pos_system_backend && npm run seed && npm run dev
///
/// لو السيرفر مش شغال، الاختبارات بتتخطّى بدل ما تفشل، عشان `flutter test`
/// العادي ميبقاش مربوط بحاجة برّه المشروع.
void main() {
  late ApiClient api;
  bool backendUp = false;

  setUpAll(() async {
    api = ApiClient();
    try {
      await api.get('/health');
      backendUp = true;
    } on ApiException {
      backendUp = false;
    }
  });

  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    api.clearTokens();
  });

  tearDownAll(() => api.dispose());

  void skipIfDown() {
    if (!backendUp) {
      markTestSkipped('الباك اند مش شغال على ${ApiConfig.baseUrl}');
    }
  }

  group('الاتصال بالباك اند', () {
    test('فحص الحياة بيرد', () async {
      skipIfDown();
      if (!backendUp) return;

      final ApiResponse response = await api.get('/health');
      expect(response.object['status'], 'ok');
    });

    test('المسار المحمي بيرفض من غير توكن', () async {
      skipIfDown();
      if (!backendUp) return;

      expect(
        () => api.get('/products'),
        throwsA(
          isA<ApiException>().having((ApiException e) => e.isUnauthorized,
              'unauthorized', isTrue),
        ),
      );
    });

    test('بيانات دخول غلط بترجع رسالة مفهومة', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController session = SessionController(api);
      final bool ok = await session.login(
        username: 'cashier',
        password: 'definitely-wrong',
      );

      expect(ok, isFalse);
      expect(session.isAuthenticated, isFalse);
      expect(session.error, isNotNull);
      expect(session.error, contains('اسم المستخدم'));
    });
  });

  group('دورة الجلسة', () {
    test('الدخول بيجيب المستخدم والصلاحيات', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController session = SessionController(api);
      final bool ok = await session.login(
        username: 'cashier',
        password: 'Cashier@123',
      );

      expect(ok, isTrue, reason: 'محتاج تعمل npm run seed للباك اند');
      expect(session.status, SessionStatus.authenticated);

      final AuthUser user = session.user!;
      expect(user.id, isNotEmpty);
      expect(user.role, 'cashier');
      expect(user.branchId, isNotNull, reason: 'الكاشير لازم يكون مربوط بفرع');
      expect(user.can('invoice:create'), isTrue);
      expect(user.can('user:manage'), isFalse);
    });

    test('الجلسة بترجع بعد إعادة تشغيل التطبيق', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController first = SessionController(api);
      await first.login(username: 'cashier', password: 'Cashier@123');

      // جلسة جديدة على نفس التخزين — زي ما التطبيق يتقفل ويتفتح تاني.
      final ApiClient freshApi = ApiClient();
      final SessionController second = SessionController(freshApi);
      await second.restore();

      expect(second.status, SessionStatus.authenticated);
      expect(second.user!.username, 'cashier');

      freshApi.dispose();
    });

    test('الخروج بيمسح الجلسة المحفوظة', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController session = SessionController(api);
      await session.login(username: 'cashier', password: 'Cashier@123');
      await session.logout();

      expect(session.status, SessionStatus.unauthenticated);
      expect(session.user, isNull);

      final SessionController after = SessionController(ApiClient());
      await after.restore();
      expect(after.status, SessionStatus.unauthenticated);
    });
  });

  group('قراءة بيانات حقيقية', () {
    test('المنتجات بترجع مع أرصدتها', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController session = SessionController(api);
      await session.login(username: 'cashier', password: 'Cashier@123');

      final ApiResponse response =
          await api.get('/products', query: <String, dynamic>{'limit': 5});

      expect(response.list, isNotEmpty,
          reason: 'محتاج تعمل npm run seed للباك اند');
      expect(response.total, greaterThan(0));

      final Map<String, dynamic> product = response.list.first;
      expect(product['id'], isNotNull, reason: 'كل عنصر لازم يكون فيه id');
      expect(product['name'], isNotNull);
      expect(product['price'], isA<num>());
    });

    test('الأخطاء بترجع أسماء الحقول الغلط', () async {
      skipIfDown();
      if (!backendUp) return;

      final SessionController session = SessionController(api);
      await session.login(username: 'admin', password: 'Admin@12345');

      try {
        await api.post('/categories', body: <String, String>{'name': 'x'});
        fail('المفروض يرفض الاسم القصير');
      } on ApiException catch (exception) {
        expect(exception.isValidation, isTrue);
        expect(exception.fieldErrors, contains('name'));
      }
    });
  });
}
