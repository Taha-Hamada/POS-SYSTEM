import 'package:flutter/foundation.dart';

import 'api_exception.dart';

/// حالة أي شاشة بتقرأ من الـ API: بتحمّل، فشلت، أو جاهزة.
///
/// الشاشات كانت بتقرأ البيانات فورًا من الذاكرة، فمكانش فيه انتظار ولا فشل.
/// دلوقتي كل شاشة محتاجة تعرض التلات حالات، فالمنطق ده متجمّع هنا
/// بدل ما كل كنترولر يكرّره.
mixin LoadState on ChangeNotifier {
  bool _loading = false;
  bool _loadedOnce = false;
  ApiException? _failure;

  bool get isLoading => _loading;
  bool get hasFailed => _failure != null;
  ApiException? get failure => _failure;
  String? get errorMessage => _failure?.message;

  /// أول تحميل لسه مخلصش — الشاشة بتعرض هيكل تحميل بدل محتوى فاضي.
  bool get isFirstLoad => _loading && !_loadedOnce;

  /// بينفّذ عملية قراءة ويمسك حالتها.
  ///
  /// بيرجّع `true` لو نجحت، عشان اللي بينادي يقدر يكمّل بعدها.
  @protected
  Future<bool> runLoad(Future<void> Function() work) async {
    _loading = true;
    _failure = null;
    notifyListeners();

    try {
      await work();
      _loadedOnce = true;
      return true;
    } on ApiException catch (exception) {
      _failure = exception;
      return false;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// بينفّذ عملية كتابة ويرجّع الخطأ بدل ما يخزّنه، عشان الشاشة تعرضه كرسالة
  /// مؤقتة من غير ما تستبدل المحتوى المعروض بشاشة خطأ.
  @protected
  Future<ApiException?> runAction(Future<void> Function() work) async {
    _loading = true;
    notifyListeners();

    try {
      await work();
      return null;
    } on ApiException catch (exception) {
      return exception;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  @protected
  void clearFailure() {
    _failure = null;
    notifyListeners();
  }
}
