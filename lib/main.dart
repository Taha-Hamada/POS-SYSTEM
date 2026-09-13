import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import 'core/api/api_client.dart';
import 'core/router/app_router.dart';
import 'core/session/session_controller.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PosSystemApp());
}

class PosSystemApp extends StatefulWidget {
  const PosSystemApp({super.key});

  @override
  State<PosSystemApp> createState() => _PosSystemAppState();
}

class _PosSystemAppState extends State<PosSystemApp> {
  late final ApiClient _api;
  late final SessionController _session;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();

    _api = ApiClient();
    _session = SessionController(_api);
    _router = createRouter(_session);

    // بنحاول نرجّع الجلسة المحفوظة قبل ما نعرض أي شاشة.
    _session.restore();
  }

  @override
  void dispose() {
    _session.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: <SingleChildWidget>[
        Provider<ApiClient>.value(value: _api),
        ChangeNotifierProvider<SessionController>.value(value: _session),
      ],
      child: MaterialApp.router(
        title: 'POS System — نظام إدارة المبيعات',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: _router,
        locale: const Locale('ar'),
        supportedLocales: const <Locale>[Locale('ar'), Locale('en')],
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        // اتجاه RTL على مستوى التطبيق كله
        builder: (BuildContext context, Widget? child) => Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
