import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/api/api_config.dart';
import '../../../core/widgets/app_snack_bar.dart';
import '../../../core/widgets/dashed_border_painter.dart';
import '../../../theme/app_theme.dart';
import '../controllers/product_form_controller.dart';

/// صورة المنتج: اختيار ومعاينة وإزالة. بترتفع مع حفظ المنتج.
class ProductImageDropZone extends StatefulWidget {
  const ProductImageDropZone({super.key});

  @override
  State<ProductImageDropZone> createState() => _ProductImageDropZoneState();
}

class _ProductImageDropZoneState extends State<ProductImageDropZone> {
  bool _hovered = false;

  static const XTypeGroup _images = XTypeGroup(
    label: 'صور',
    extensions: <String>['png', 'jpg', 'jpeg', 'webp'],
    mimeTypes: <String>['image/png', 'image/jpeg', 'image/webp'],
    uniformTypeIdentifiers: <String>['public.image'],
  );

  Future<void> _pick() async {
    final ProductFormController form = context.read<ProductFormController>();

    try {
      final XFile? file = await openFile(
        acceptedTypeGroups: <XTypeGroup>[_images],
      );
      if (file == null) return;

      form.setImage(await file.readAsBytes(), file.name);
    } on PlatformException catch (e) {
      if (mounted) {
        showAppSnackBar(
          context,
          e.message ?? 'مقدرناش نفتح الصور',
          isError: true,
        );
      }
    } on MissingPluginException {
      if (mounted) {
        showAppSnackBar(
          context,
          'اختيار الصور مش مدعوم على الجهاز ده',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ProductFormController form = context.watch<ProductFormController>();
    final ({Uint8List bytes, String name})? pending = form.pendingImage;
    final String? remote = ApiConfig.mediaUrl(form.imageUrl);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _pick,
            child: CustomPaint(
              painter: DashedBorderPainter(
                color: _hovered ? AppColors.accent : AppColors.borderStrong,
                radius: AppRadius.lg,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 168,
                decoration: BoxDecoration(
                  color: _hovered ? AppColors.accentSoft : AppColors.surfaceAlt,
                  borderRadius: AppRadius.lgAll,
                ),
                child: pending != null || remote != null
                    ? _preview(form, pending, remote)
                    : _empty(),
              ),
            ),
          ),
        ),
        if (form.imageError != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Text(
            form.imageError!,
            style: AppText.caption.copyWith(color: AppColors.danger),
          ),
        ],
      ],
    );
  }

  Widget _preview(
    ProductFormController form,
    ({Uint8List bytes, String name})? pending,
    String? remote,
  ) {
    return Row(
      children: <Widget>[
        const SizedBox(width: AppSpacing.lg),
        ClipRRect(
          borderRadius: AppRadius.mdAll,
          child: SizedBox(
            width: 136,
            height: 136,
            child: pending != null
                ? Image.memory(pending.bytes, fit: BoxFit.cover)
                : Image.network(
                    remote!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.broken_image_outlined,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: AppSpacing.xl),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                pending == null ? 'صورة المنتج' : pending.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.cardTitle.copyWith(fontSize: 14),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                pending == null
                    ? 'محفوظة على السيرفر'
                    : 'هترتفع لما تحفظ المنتج',
                style: AppText.caption,
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                children: <Widget>[
                  TextButton.icon(
                    onPressed: _pick,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('تغيير'),
                  ),
                  TextButton.icon(
                    onPressed: form.clearImage,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('إزالة'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.accent
                : AppColors.accent.withValues(alpha: 0.10),
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(
            Icons.add_photo_alternate_outlined,
            size: 26,
            color: _hovered ? Colors.white : AppColors.accent,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'اضغط لاختيار صورة المنتج',
          style: AppText.cardTitle.copyWith(fontSize: 14),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'PNG أو JPG أو WEBP — الحد الأقصى 2 ميجابايت',
          style: AppText.caption.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}
