import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/add_edit_product/screens/add_product_screen.dart';
import '../../features/branches/screens/branches_screen.dart';
import '../../features/cashier_shift/screens/shifts_history_screen.dart';
import '../../features/invoices/screens/invoices_history_screen.dart';
import '../../features/categories/screens/categories_screen.dart';
import '../../features/inventory/screens/stock_alerts_screen.dart';
import '../../features/returns/screens/returns_history_screen.dart';
import '../../features/customers/screens/customer_profile_screen.dart';
import '../../features/customers/screens/customers_list_screen.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/expenses/screens/expenses_screen.dart';
import '../../features/inventory/screens/inventory_screen.dart';
import '../../features/login/screens/login_screen.dart';
import '../../features/login/screens/splash_screen.dart';
import '../../features/pos_sale/screens/pos_sale_screen.dart';
import '../../features/products_list/screens/products_list_screen.dart';
import '../../features/promotions/screens/promotions_screen.dart';
import '../../features/purchase_orders/screens/create_purchase_order_screen.dart';
import '../../features/purchase_orders/screens/purchase_orders_screen.dart';
import '../../features/reports/screens/reports_screen.dart';
import '../../features/returns/screens/returns_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/stock_transfer_stocktake/screens/stocktake_screen.dart';
import '../../features/suppliers/screens/supplier_profile_screen.dart';
import '../../features/suppliers/screens/suppliers_list_screen.dart';
import '../../features/welcome/screens/welcome_screen.dart';
import '../../widgets/app_shell.dart';
import '../session/session_controller.dart';
import '../widgets/placeholder_screen.dart';

/// كل الشاشات جوه [AppShell] من غير أنيميشن انتقال.
Page<void> _page(Widget child) => NoTransitionPage<void>(child: child);

const String loginPath = '/login';
const String splashPath = '/splash';

/// راوتر التطبيق — كل عناصر القائمة الجانبية ليها شاشة حقيقية،
/// والـPlaceholder اتساب كـfallback للمسارات غير المعروفة بس.
///
/// الراوتر بياخد [SessionController] عشان يحرس المسارات: من غير جلسة
/// كل حاجة بتوديك لشاشة الدخول، ومع جلسة شاشة الدخول بتوديك للرئيسية.
GoRouter createRouter(SessionController session) => GoRouter(
  initialLocation: '/',
  refreshListenable: session,
  redirect: (BuildContext context, GoRouterState state) {
    final String location = state.matchedLocation;

    // لسه بنقرأ التوكن المحفوظ. بنستنى على شاشة انتظار بدل ما نعرض
    // الشاشة المحمية لحظة وبعدين نقفز لشاشة الدخول.
    if (session.status == SessionStatus.checking) {
      return location == splashPath ? null : splashPath;
    }

    if (!session.isAuthenticated) {
      return location == loginPath ? null : loginPath;
    }

    // الجلسة جاهزة: شاشتَي الدخول والانتظار مالهمش لازمة.
    return location == loginPath || location == splashPath ? '/' : null;
  },
  errorBuilder: (BuildContext context, GoRouterState state) => AppShell(
    child: PlaceholderScreen(
      title: 'الصفحة غير موجودة',
      icon: Icons.explore_off_outlined,
      description:
          'المسار «${state.uri.path}» مش موجود — '
          'اختر شاشة من القائمة الجانبية.',
    ),
  ),
  routes: <RouteBase>[
    // شاشة الدخول بره الـShell عشان متظهرش القائمة الجانبية قبل الدخول.
    GoRoute(
      path: splashPath,
      pageBuilder: (_, _) => _page(const SplashScreen()),
    ),
    GoRoute(path: loginPath, pageBuilder: (_, _) => _page(const LoginScreen())),
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) =>
          AppShell(child: child),
      routes: <RouteBase>[
        GoRoute(path: '/', pageBuilder: (_, _) => _page(const WelcomeScreen())),
        GoRoute(
          path: '/pos',
          pageBuilder: (_, _) => _page(const PosSaleScreen()),
        ),
        GoRoute(
          path: '/dashboard',
          pageBuilder: (_, _) => _page(const DashboardScreen()),
        ),
        GoRoute(
          path: '/expenses',
          pageBuilder: (_, _) => _page(const ExpensesScreen()),
        ),
        GoRoute(
          path: '/branches',
          pageBuilder: (_, _) => _page(const BranchesScreen()),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (_, _) => _page(const SettingsScreen()),
        ),
        GoRoute(
          path: '/invoices',
          pageBuilder: (_, _) => _page(const InvoicesHistoryScreen()),
        ),
        GoRoute(
          path: '/shifts',
          pageBuilder: (_, _) => _page(const ShiftsHistoryScreen()),
        ),
        GoRoute(
          path: '/returns',
          pageBuilder: (_, _) => _page(const ReturnsScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: 'history',
              pageBuilder: (_, _) => _page(const ReturnsHistoryScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/promotions',
          pageBuilder: (_, _) => _page(const PromotionsScreen()),
        ),
        GoRoute(
          path: '/reports',
          pageBuilder: (_, _) => _page(const ReportsScreen()),
        ),
        GoRoute(
          path: '/products',
          pageBuilder: (_, _) => _page(const ProductsListScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              pageBuilder: (_, _) => _page(const AddProductScreen()),
            ),
            GoRoute(
              path: 'categories',
              pageBuilder: (_, _) => _page(const CategoriesScreen()),
            ),
            GoRoute(
              path: ':id/edit',
              pageBuilder: (_, GoRouterState state) => _page(
                AddProductScreen(
                  key: ValueKey<String>(state.pathParameters['id']!),
                  productId: state.pathParameters['id'],
                ),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/inventory',
          pageBuilder: (_, _) => _page(const InventoryScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: 'stocktake',
              pageBuilder: (_, _) => _page(const StocktakeScreen()),
            ),
            GoRoute(
              path: 'alerts',
              pageBuilder: (_, _) => _page(const StockAlertsScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/purchases',
          pageBuilder: (_, _) => _page(const PurchaseOrdersScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: 'new',
              pageBuilder: (_, _) => _page(const CreatePurchaseOrderScreen()),
            ),
          ],
        ),
        GoRoute(
          path: '/customers',
          pageBuilder: (_, _) => _page(const CustomersListScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              pageBuilder: (_, GoRouterState state) => _page(
                CustomerProfileScreen(customerId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
        GoRoute(
          path: '/suppliers',
          pageBuilder: (_, _) => _page(const SuppliersListScreen()),
          routes: <RouteBase>[
            GoRoute(
              path: ':id',
              pageBuilder: (_, GoRouterState state) => _page(
                SupplierProfileScreen(supplierId: state.pathParameters['id']!),
              ),
            ),
          ],
        ),
      ],
    ),
  ],
);
