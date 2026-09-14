import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

import '../core/api/api_client.dart';
import '../core/models/shift.dart';
import '../core/session/session_controller.dart';
import '../core/session/settings_controller.dart';
import '../features/cashier_shift/controllers/current_shift_controller.dart';
import '../features/cashier_shift/data/shift_repository.dart';
import '../features/cashier_shift/screens/close_shift_dialog.dart';
import '../features/cashier_shift/screens/open_shift_dialog.dart';
import '../mock_data/mock_data.dart';
import '../theme/app_theme.dart';
import '../utils/formatters.dart';

/// عنصر تنقل في القائمة الجانبية.
class NavItem {
  const NavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}

class NavSection {
  const NavSection({required this.title, required this.items});

  final String title;
  final List<NavItem> items;
}

/// خريطة التنقل الكاملة للنظام.
const List<NavSection> kNavSections = <NavSection>[
  NavSection(
    title: 'الرئيسية',
    items: <NavItem>[
      NavItem(
        label: 'لوحة التحكم',
        icon: Icons.dashboard_rounded,
        route: '/dashboard',
      ),
    ],
  ),
  NavSection(
    title: 'المبيعات',
    items: <NavItem>[
      NavItem(
        label: 'نقطة البيع',
        icon: Icons.point_of_sale_rounded,
        route: '/pos',
      ),
      NavItem(
        label: 'المرتجعات',
        icon: Icons.assignment_return_outlined,
        route: '/returns',
      ),
      NavItem(
        label: 'العروض والخصومات',
        icon: Icons.local_offer_outlined,
        route: '/promotions',
      ),
    ],
  ),
  NavSection(
    title: 'الكتالوج والمخزون',
    items: <NavItem>[
      NavItem(
        label: 'المنتجات',
        icon: Icons.inventory_2_outlined,
        route: '/products',
      ),
      NavItem(
        label: 'المخزون',
        icon: Icons.warehouse_outlined,
        route: '/inventory',
      ),
      NavItem(
        label: 'المشتريات',
        icon: Icons.shopping_cart_outlined,
        route: '/purchases',
      ),
    ],
  ),
  NavSection(
    title: 'العملاء والفريق',
    items: <NavItem>[
      NavItem(
        label: 'العملاء',
        icon: Icons.people_alt_outlined,
        route: '/customers',
      ),
      NavItem(
        label: 'الموردين',
        icon: Icons.local_shipping_outlined,
        route: '/suppliers',
      ),
      NavItem(
        label: 'الموظفين',
        icon: Icons.badge_outlined,
        route: '/employees',
      ),
      NavItem(
        label: 'برنامج الولاء',
        icon: Icons.stars_outlined,
        route: '/loyalty',
      ),
    ],
  ),
  NavSection(
    title: 'المالية والتقارير',
    items: <NavItem>[
      NavItem(
        label: 'التقارير',
        icon: Icons.bar_chart_rounded,
        route: '/reports',
      ),
      NavItem(
        label: 'المصروفات',
        icon: Icons.receipt_long_outlined,
        route: '/expenses',
      ),
    ],
  ),
  NavSection(
    title: 'الإدارة',
    items: <NavItem>[
      NavItem(
        label: 'الفروع',
        icon: Icons.store_outlined,
        route: '/branches',
      ),
      NavItem(
        label: 'الإعدادات',
        icon: Icons.settings_outlined,
        route: '/settings',
      ),
    ],
  ),
];

List<NavItem> get kNavItems =>
    kNavSections.expand((NavSection s) => s.items).toList(growable: false);

/// الهيكل العام للتطبيق: Sidebar على اليمين + Top Bar فوق + محتوى الشاشة.
/// الشل بيوفّر الوردية الحالية لكل الشاشات اللي جواه،
/// لأن شاشة البيع والشريط الجانبي محتاجينها مع بعض.
class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final String? branchId = context.read<SessionController>().user?.branchId;

    return MultiProvider(
      providers: <SingleChildWidget>[
        ChangeNotifierProvider<CurrentShiftController>(
          create: (BuildContext context) => CurrentShiftController(
            ShiftRepository(context.read<ApiClient>()),
            branchId: branchId,
          )..load(),
        ),
        ChangeNotifierProvider<SettingsController>(
          create: (BuildContext context) =>
              SettingsController(context.read<ApiClient>())..load(),
        ),
      ],
      child: _AppShellBody(child: child),
    );
  }
}

class _AppShellBody extends StatefulWidget {
  const _AppShellBody({required this.child});

  final Widget child;

  @override
  State<_AppShellBody> createState() => _AppShellState();
}

class _AppShellState extends State<_AppShellBody> {
  static const double _expandedWidth = 268;
  static const double _collapsedWidth = 84;

  bool _collapsed = false;
  Branch _branch = MockData.currentBranch;

  Future<void> _openShift() async {
    final CurrentShiftController shifts = context.read<CurrentShiftController>();

    final double? balance = await showOpenShiftDialog(context);
    if (balance == null || !mounted) return;

    final String? error = await shifts.open(balance);
    if (!mounted) return;

    _toast(
      error ?? 'تم بدء الوردية برصيد افتتاحي ${Fmt.money(balance)}',
    );
  }

  Future<void> _closeShift() async {
    final CurrentShiftController shifts = context.read<CurrentShiftController>();

    // الأرقام بتتقرا من السيرفر قبل ما نعرضها، عشان الكاشير يعدّ الدرج
    // على رقم محدّث مش رقم قديم من أول الوردية.
    await shifts.refreshTotals();
    if (!mounted) return;

    final Shift? open = shifts.shift;
    if (open == null) {
      _toast('مفيش وردية مفتوحة');
      return;
    }

    final double? counted = await showCloseShiftDialog(
      context,
      shift: open,
      totals: shifts.totals,
    );
    if (counted == null || !mounted) return;

    final String? error = await shifts.close(countedCash: counted);
    if (!mounted) return;

    if (error != null) {
      _toast(error);
      return;
    }

    final ShiftClosing? closing = shifts.lastClosed?.closing;
    _toast(
      closing == null || closing.isBalanced
          ? 'اتقفلت الوردية والدرج مظبوط'
          : closing.isShort
              ? 'اتقفلت الوردية — عجز ${Fmt.money(closing.difference.abs())}'
              : 'اتقفلت الوردية — زيادة ${Fmt.money(closing.difference)}',
    );
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message), width: 460));
  }

  String get _location => GoRouterState.of(context).uri.path;

  String get _pageTitle {
    for (final NavItem item in kNavItems) {
      if (_location.startsWith(item.route)) return item.label;
    }
    return 'الرئيسية';
  }

  @override
  Widget build(BuildContext context) {
    final CurrentShiftController shifts =
        context.watch<CurrentShiftController>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: <Widget>[
          _Sidebar(
            collapsed: _collapsed,
            width: _collapsed ? _collapsedWidth : _expandedWidth,
            currentLocation: _location,
            shiftOpen: shifts.isOpen,
            shiftSales: shifts.totals.salesTotal,
            busy: shifts.isLoading,
            onToggle: () => setState(() => _collapsed = !_collapsed),
            onNavigate: (String route) => context.go(route),
            onShiftTap: shifts.isOpen ? _closeShift : _openShift,
          ),
          Expanded(
            child: Column(
              children: <Widget>[
                _TopBar(
                  title: _pageTitle,
                  branch: _branch,
                  onBranchChanged: (Branch b) => setState(() => _branch = b),
                ),
                Expanded(
                  child: ClipRect(child: widget.child),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Sidebar
// ═══════════════════════════════════════════════════════════════════════════

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.collapsed,
    required this.width,
    required this.currentLocation,
    required this.shiftOpen,
    required this.shiftSales,
    required this.busy,
    required this.onToggle,
    required this.onNavigate,
    required this.onShiftTap,
  });

  final bool collapsed;
  final double width;
  final String currentLocation;
  final bool shiftOpen;

  /// مبيعات الوردية المفتوحة، محسوبة على السيرفر.
  final double shiftSales;

  /// بنقفل زرار الوردية أثناء الفتح أو الإغلاق عشان مايتضغطش مرتين.
  final bool busy;

  final VoidCallback onToggle;
  final ValueChanged<String> onNavigate;
  final VoidCallback onShiftTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        border: BorderDirectional(
          end: BorderSide(color: Color(0xFF1E293B)),
        ),
      ),
      child: Column(
        children: <Widget>[
          _buildBrand(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  for (final NavSection section in kNavSections) ...<Widget>[
                    if (!collapsed)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.sm,
                        ),
                        child: Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.4,
                          ),
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.md,
                        ),
                        child: Divider(color: Color(0xFF1E293B), height: 1),
                      ),
                    for (final NavItem item in section.items)
                      _NavTile(
                        item: item,
                        collapsed: collapsed,
                        selected: currentLocation.startsWith(item.route),
                        onTap: () => onNavigate(item.route),
                      ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
          _buildShiftCard(),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    return Container(
      height: 84,
      padding: EdgeInsets.symmetric(
        horizontal: collapsed ? AppSpacing.lg : AppSpacing.xl,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
                colors: <Color>[AppColors.accent, Color(0xFF8B5CF6)],
              ),
              borderRadius: BorderRadius.circular(AppRadius.md),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: const Icon(
              Icons.storefront_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          if (!collapsed) ...<Widget>[
            const SizedBox(width: AppSpacing.md),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'POS System',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'نظام إدارة المبيعات',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF94A3B8),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
          _SidebarIconButton(
            icon: collapsed
                ? Icons.keyboard_double_arrow_left_rounded
                : Icons.keyboard_double_arrow_right_rounded,
            tooltip: collapsed ? 'توسيع القائمة' : 'طيّ القائمة',
            onTap: onToggle,
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard() {
    if (collapsed) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: _SidebarIconButton(
          icon: shiftOpen
              ? Icons.lock_clock_rounded
              : Icons.play_circle_outline_rounded,
          tooltip: shiftOpen ? 'إغلاق الوردية' : 'بدء وردية جديدة',
          onTap: busy ? null : onShiftTap,
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md + 2),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color:
                      shiftOpen ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  shiftOpen ? 'الوردية مفتوحة' : 'الوردية مغلقة',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            shiftOpen
                ? 'مبيعات الوردية: ${Fmt.moneyRounded(shiftSales)}'
                : 'ابدأ وردية جديدة عشان تقدر تبيع',
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF94A3B8),
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ShiftButton(
            label: shiftOpen ? 'إغلاق الوردية' : 'بدء وردية',
            icon: shiftOpen
                ? Icons.lock_outline_rounded
                : Icons.play_arrow_rounded,
            highlighted: !shiftOpen,
            onTap: busy ? null : onShiftTap,
          ),
        ],
      ),
    );
  }
}

/// زر الوردية أسفل الـSidebar
class _ShiftButton extends StatefulWidget {
  const _ShiftButton({
    required this.label,
    required this.icon,
    required this.highlighted,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool highlighted;

  /// null معناها الزرار متعطّل — بيحصل أثناء فتح أو إغلاق الوردية.
  final VoidCallback? onTap;

  @override
  State<_ShiftButton> createState() => _ShiftButtonState();
}

class _ShiftButtonState extends State<_ShiftButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final Color background = widget.highlighted
        ? (_hovered ? AppColors.accentDark : AppColors.accent)
        : (_hovered
            ? Colors.white.withValues(alpha: 0.14)
            : Colors.white.withValues(alpha: 0.07));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 36,
          width: double.infinity,
          decoration: BoxDecoration(
            color: background,
            borderRadius: AppRadius.smAll,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(widget.icon, size: 15, color: Colors.white),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavTile extends StatefulWidget {
  const _NavTile({
    required this.item,
    required this.selected,
    required this.collapsed,
    required this.onTap,
  });

  final NavItem item;
  final bool selected;
  final bool collapsed;
  final VoidCallback onTap;

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bool selected = widget.selected;
    final Color fg = selected
        ? Colors.white
        : _hovered
            ? const Color(0xFFE2E8F0)
            : const Color(0xFF94A3B8);

    final Widget tile = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      height: 46,
      margin: const EdgeInsets.only(bottom: 3),
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? 0 : AppSpacing.md + 2,
      ),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.accent.withValues(alpha: 0.16)
            : _hovered
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.transparent,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.32)
              : Colors.transparent,
        ),
      ),
      child: widget.collapsed
          ? Center(
              child: Icon(
                widget.item.icon,
                size: 21,
                color: selected ? AppColors.accent : fg,
              ),
            )
          : Row(
              children: <Widget>[
                Icon(
                  widget.item.icon,
                  size: 20,
                  color: selected ? AppColors.accent : fg,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    widget.item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: fg,
                      height: 1.3,
                    ),
                  ),
                ),
                if (selected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
    );

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: widget.collapsed
            ? Tooltip(message: widget.item.label, child: tile)
            : tile,
      ),
    );
  }
}

class _SidebarIconButton extends StatefulWidget {
  const _SidebarIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;

  /// null معناها الزرار متعطّل.
  final VoidCallback? onTap;

  static const double size = 34;

  @override
  State<_SidebarIconButton> createState() => _SidebarIconButtonState();
}

class _SidebarIconButtonState extends State<_SidebarIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: _SidebarIconButton.size,
            height: _SidebarIconButton.size,
            decoration: BoxDecoration(
              color: _hovered
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: AppRadius.smAll,
            ),
            child: Icon(
              widget.icon,
              size: 17,
              color: _hovered ? Colors.white : const Color(0xFF94A3B8),
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Top Bar
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.title,
    required this.branch,
    required this.onBranchChanged,
  });

  final String title;
  final Branch branch;
  final ValueChanged<Branch> onBranchChanged;

  @override
  Widget build(BuildContext context) {
    final Employee user = MockData.currentUser;

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          // على الشاشات الضيقة بنختصر العناصر بدل ما تتزحلق برّه
          final bool compact = constraints.maxWidth < 900;
          final bool minimal = constraints.maxWidth < 640;

          return Row(
            children: <Widget>[
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.pageTitle.copyWith(fontSize: 19),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      Fmt.date(DateTime(2026, 8, 13)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.caption.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              const Spacer(),
              _BranchSelector(
                branch: branch,
                onChanged: onBranchChanged,
                showLabel: !minimal,
                maxLabelWidth: compact ? 120 : 190,
              ),
              const SizedBox(width: AppSpacing.md),
              const _NotificationsButton(count: MockData.unreadNotifications),
              const SizedBox(width: AppSpacing.md),
              Container(width: 1, height: 32, color: AppColors.border),
              const SizedBox(width: AppSpacing.md),
              _UserChip(user: user, showDetails: !compact),
            ],
          );
        },
      ),
    );
  }
}

class _BranchSelector extends StatelessWidget {
  const _BranchSelector({
    required this.branch,
    required this.onChanged,
    this.showLabel = true,
    this.maxLabelWidth = 190,
  });

  final Branch branch;
  final ValueChanged<Branch> onChanged;
  final bool showLabel;
  final double maxLabelWidth;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<Branch>(
      tooltip: 'تغيير الفرع',
      offset: const Offset(0, 48),
      onSelected: onChanged,
      itemBuilder: (BuildContext context) => <PopupMenuEntry<Branch>>[
        for (final Branch b in MockData.branches)
          PopupMenuItem<Branch>(
            value: b,
            height: 52,
            child: Row(
              children: <Widget>[
                Icon(
                  b.id == branch.id
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: b.id == branch.id
                      ? AppColors.accent
                      : AppColors.textMuted,
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(b.name, style: AppText.bodyMedium),
                    Text(
                      b.address,
                      style: AppText.caption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md + 2),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.store_rounded,
              size: 17,
              color: AppColors.textSecondary,
            ),
            if (showLabel) ...<Widget>[
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxLabelWidth),
                child: Text(
                  branch.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.bodyMedium.copyWith(fontSize: 13),
                ),
              ),
            ],
            const SizedBox(width: AppSpacing.xs),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationsButton extends StatefulWidget {
  const _NotificationsButton({required this.count});

  final int count;

  @override
  State<_NotificationsButton> createState() => _NotificationsButtonState();
}

class _NotificationsButtonState extends State<_NotificationsButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'الإشعارات',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: () {},
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _hovered ? AppColors.surfaceAlt : Colors.transparent,
              borderRadius: AppRadius.mdAll,
              border: Border.all(
                color: _hovered ? AppColors.border : Colors.transparent,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                const Icon(
                  Icons.notifications_none_rounded,
                  size: 22,
                  color: AppColors.textSecondary,
                ),
                if (widget.count > 0)
                  PositionedDirectional(
                    top: 8,
                    end: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.danger,
                        borderRadius:
                            BorderRadius.circular(AppRadius.pill),
                        border: Border.all(color: AppColors.surface, width: 2),
                      ),
                      child: Text(
                        widget.count > 9 ? '9+' : '${widget.count}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _UserChip extends StatefulWidget {
  const _UserChip({required this.user, this.showDetails = true});

  final Employee user;
  final bool showDetails;

  @override
  State<_UserChip> createState() => _UserChipState();
}

class _UserChipState extends State<_UserChip> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.surfaceAlt : Colors.transparent,
          borderRadius: AppRadius.mdAll,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: <Color>[AppColors.primaryLight, AppColors.primary],
                ),
              ),
              child: Text(
                widget.user.initials,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            if (widget.showDetails) ...<Widget>[
              const SizedBox(width: AppSpacing.md - 2),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    widget.user.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.bodyMedium.copyWith(fontSize: 13.5),
                  ),
                  Text(
                    widget.user.role,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
