import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_client.dart';
import '../../../core/models/category.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/screen_header.dart';
import '../../../core/widgets/stat_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/formatters.dart';
import '../controllers/categories_controller.dart';
import '../data/categories_repository.dart';
import '../widgets/category_form_dialog.dart';

enum _CategoryAction { edit, toggleActive, remove }

/// إدارة أقسام المنتجات.
class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  /// الشاشة بتتفتح فوق قايمة المنتجات، فالرجوع بيقفلها عشان القايمة تتحمّل.
  void _back(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/products');
    }
  }

  Future<void> _openForm(BuildContext context, {Category? existing}) async {
    final CategoriesController categories = context
        .read<CategoriesController>();

    final bool? saved = await showCategoryFormDialog(
      context,
      roots: categories.roots,
      initial: existing,
      onSubmit: (CategoryInput input) =>
          categories.save(input, existing: existing),
    );

    if (saved != true || !context.mounted) return;
    showAppSnackBar(context, existing == null ? 'اتضاف القسم' : 'اتحفظ القسم');
  }

  Future<void> _onAction(
    BuildContext context,
    Category category,
    _CategoryAction action,
  ) async {
    final CategoriesController categories = context
        .read<CategoriesController>();

    switch (action) {
      case _CategoryAction.edit:
        await _openForm(context, existing: category);

      case _CategoryAction.toggleActive:
        final String? error = await categories.setActive(
          category,
          isActive: !category.isActive,
        );
        if (!context.mounted) return;
        showAppSnackBar(
          context,
          error ??
              (category.isActive
                  ? 'اتعطّل «${category.name}»'
                  : 'اتفعّل «${category.name}»'),
          isError: error != null,
        );

      case _CategoryAction.remove:
        final bool? confirmed = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: const Text('حذف القسم'),
            content: Text(
              category.productsCount > 0
                  ? '«${category.name}» عليه ${category.productsCount} منتج، '
                        'فهيتعطّل بدل ما يتمسح عشان المنتجات تفضل مربوطة بيه.'
                  : 'هيتمسح «${category.name}» نهائيًا.',
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.danger,
                ),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('تأكيد'),
              ),
            ],
          ),
        );
        if (confirmed != true || !context.mounted) return;

        final ({String message, bool isError}) result = await categories.remove(
          category,
        );
        if (!context.mounted) return;
        showAppSnackBar(context, result.message, isError: result.isError);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canManage = context.read<SessionController>().can(
      'category:manage',
    );

    return ChangeNotifierProvider<CategoriesController>(
      create: (_) => CategoriesController(
        CategoriesRepository(context.read<ApiClient>()),
        canManage: canManage,
      )..load(),
      child: Builder(
        builder: (BuildContext context) {
          final CategoriesController categories = context
              .watch<CategoriesController>();

          return Padding(
            padding: AppSpacing.page,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                ScreenHeader(
                  title: 'أقسام المنتجات',
                  subtitle: 'الأقسام بتظهر كتبويبات في شاشة البيع',
                  leading: BackCircleButton(
                    onTap: () => _back(context),
                    tooltip: 'رجوع للمنتجات',
                  ),
                  actions: <Widget>[
                    if (canManage)
                      PrimaryButton(
                        label: 'قسم جديد',
                        icon: Icons.add_rounded,
                        onPressed: () => _openForm(context),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                if (categories.isFirstLoad)
                  const Expanded(child: LoadingView(message: 'بنجيب الأقسام…'))
                else if (categories.hasFailed && categories.rows.isEmpty)
                  Expanded(
                    child: ErrorView(
                      message: categories.errorMessage!,
                      onRetry: categories.retry,
                    ),
                  )
                else ...<Widget>[
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: StatCard(
                          title: 'عدد الأقسام',
                          value: Fmt.count(categories.rows.length),
                          icon: Icons.category_outlined,
                          iconColor: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: StatCard(
                          title: 'أقسام نشطة',
                          value: Fmt.count(categories.activeCount),
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: AppColors.success,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: StatCard(
                          title: 'منتجات في الأقسام',
                          value: Fmt.count(categories.productsCount),
                          icon: Icons.inventory_2_outlined,
                          iconColor: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Expanded(
                    child: categories.rows.isEmpty
                        ? const EmptyView(
                            title: 'مفيش أقسام لسه',
                            icon: Icons.category_outlined,
                          )
                        : GridView.builder(
                            gridDelegate:
                                const SliverGridDelegateWithMaxCrossAxisExtent(
                                  maxCrossAxisExtent: 320,
                                  mainAxisExtent: 96,
                                  mainAxisSpacing: AppSpacing.md,
                                  crossAxisSpacing: AppSpacing.md,
                                ),
                            itemCount: categories.rows.length,
                            itemBuilder: (BuildContext context, int i) =>
                                _CategoryTile(
                                  category: categories.rows[i],
                                  parentName: categories.nameOf(
                                    categories.rows[i].parentId,
                                  ),
                                  onAction: canManage
                                      ? (_CategoryAction a) => _onAction(
                                          context,
                                          categories.rows[i],
                                          a,
                                        )
                                      : null,
                                ),
                          ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.parentName,
    required this.onAction,
  });

  final Category category;
  final String? parentName;
  final ValueChanged<_CategoryAction>? onAction;

  @override
  Widget build(BuildContext context) {
    final Category c = category;

    return Opacity(
      opacity: c.isActive ? 1 : 0.6,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: AppDecorations.card(),
        child: Row(
          children: <Widget>[
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: c.color.withValues(alpha: 0.14),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(c.icon, color: c.color, size: 24),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    c.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.cardTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${parentName == null ? 'قسم رئيسي' : 'تابع لـ $parentName'}'
                    ' • ${Fmt.count(c.productsCount)} منتج',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            if (!c.isActive)
              const StatusBadge(
                label: 'معطّل',
                tone: StatusTone.neutral,
                compact: true,
              ),
            if (onAction != null)
              PopupMenuButton<_CategoryAction>(
                tooltip: 'إجراءات القسم',
                icon: const Icon(
                  Icons.more_vert_rounded,
                  size: 20,
                  color: AppColors.textMuted,
                ),
                onSelected: onAction,
                itemBuilder: (BuildContext context) =>
                    <PopupMenuEntry<_CategoryAction>>[
                      const PopupMenuItem<_CategoryAction>(
                        value: _CategoryAction.edit,
                        child: Text('تعديل'),
                      ),
                      PopupMenuItem<_CategoryAction>(
                        value: _CategoryAction.toggleActive,
                        child: Text(c.isActive ? 'تعطيل' : 'تفعيل'),
                      ),
                      const PopupMenuItem<_CategoryAction>(
                        value: _CategoryAction.remove,
                        child: Text(
                          'حذف',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ),
                    ],
              ),
          ],
        ),
      ),
    );
  }
}
