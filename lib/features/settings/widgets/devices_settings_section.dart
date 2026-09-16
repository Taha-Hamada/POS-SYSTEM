import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';

import '../../../core/models/store_settings.dart';
import '../../../core/printing/pdf_kit.dart';
import '../../../core/printing/print_job.dart';
import '../../../core/printing/print_preferences.dart';
import '../../../core/printing/test_print_pdf.dart';
import '../../../core/widgets/async_state_views.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/secondary_button.dart';
import '../../../theme/app_theme.dart';
import 'settings_panel.dart';

/// قسم الأجهزة: طابعات الويندوز الحقيقية واختيار طابعة الإيصالات.
class DevicesSettingsSection extends StatefulWidget {
  const DevicesSettingsSection({super.key});

  @override
  State<DevicesSettingsSection> createState() => _DevicesSettingsSectionState();
}

class _DevicesSettingsSectionState extends State<DevicesSettingsSection> {
  List<Printer>? _printers;
  String? _selectedUrl;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // على منصة من غير طابعات الطلب ممكن ميرجعش خالص، فبنقطعه بدل ما
      // القسم يفضل بيلف على الفاضي.
      final List<Printer> printers = await Printing.listPrinters().timeout(
        const Duration(seconds: 5),
        onTimeout: () => <Printer>[],
      );
      final ({String url, String name})? saved =
          await PrintPreferences.receiptPrinter();

      if (!mounted) return;
      setState(() {
        _printers = printers;
        _selectedUrl = saved?.url;
        _loading = false;
      });
    } on MissingPluginException {
      if (!mounted) return;
      setState(() {
        _error = 'قراءة الطابعات مش مدعومة على الجهاز ده';
        _loading = false;
      });
    } on PlatformException catch (exception) {
      if (!mounted) return;
      setState(() {
        _error = exception.message ?? 'مقدرناش نقرا الطابعات';
        _loading = false;
      });
    }
  }

  Future<void> _select(Printer? printer) async {
    await PrintPreferences.setReceiptPrinter(
      url: printer?.url,
      name: printer?.name,
    );
    if (!mounted) return;
    setState(() => _selectedUrl = printer?.url);
  }

  Future<void> _testPrint() async {
    final StoreSettings store = storeSettingsOf(context);

    await printDocument(
      context,
      name: 'اختبار الطباعة',
      format: PdfKit.rollFormat(store.receiptWidthMm),
      build: (format) => buildTestPrintPdf(store: store, format: format),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SettingsPanel(
      children: <Widget>[
        Row(
          children: <Widget>[
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.textMuted,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'دي طابعات الجهاز ده. لما تختار طابعة إيصالات، الإيصالات '
                'هتطبع عليها على طول من غير حوار طباعة.',
                style: AppText.caption.copyWith(fontSize: 12),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            SecondaryButton(
              label: 'تحديث',
              icon: Icons.refresh_rounded,
              size: AppButtonSize.small,
              onPressed: _load,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
            child: LoadingView(message: 'بندوّر على الطابعات…'),
          )
        else if (_error != null)
          Text(
            _error!,
            style: AppText.caption.copyWith(color: AppColors.danger),
          )
        else ...<Widget>[
          // الـListTile بيرسم خلفيته على أقرب Material، وبطاقة الإعدادات
          // مجرد DecoratedBox — فبنديله Material شفاف.
          Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                RadioListTile<String?>(
                  contentPadding: EdgeInsets.zero,
                  value: null,
                  // ignore: deprecated_member_use — RadioGroup لسه مش في النسخة دي
                  groupValue: _selectedUrl,
                  // ignore: deprecated_member_use
                  onChanged: (_) => _select(null),
                  title: Text(
                    'اسأل كل مرة (حوار الطباعة)',
                    style: AppText.body,
                  ),
                  subtitle: Text(
                    'مناسب لجهاز المدير اللي مش متوصل بطابعة إيصالات',
                    style: AppText.caption,
                  ),
                ),
                for (final Printer printer in _printers ?? <Printer>[])
                  RadioListTile<String?>(
                    contentPadding: EdgeInsets.zero,
                    value: printer.url,
                    // ignore: deprecated_member_use
                    groupValue: _selectedUrl,
                    // ignore: deprecated_member_use
                    onChanged: (_) => _select(printer),
                    title: Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(printer.name, style: AppText.body),
                        ),
                        if (printer.isDefault) ...<Widget>[
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'طابعة الويندوز الافتراضية',
                            style: AppText.caption,
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(
                      <String>[
                        if ((printer.model ?? '').isNotEmpty) printer.model!,
                        if ((printer.location ?? '').isNotEmpty)
                          printer.location!,
                        if (!printer.isAvailable) 'غير متاحة',
                      ].join(' | '),
                      style: AppText.caption,
                    ),
                  ),
              ],
            ),
          ),
          if ((_printers ?? <Printer>[]).isEmpty)
            Text('مفيش طابعات متسطبة على الجهاز', style: AppText.caption),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SecondaryButton(
              label: 'طباعة صفحة اختبار',
              icon: Icons.print_outlined,
              tone: SecondaryButtonTone.accent,
              onPressed: _testPrint,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.xl),
        Text(
          'قارئ الباركود والميزان بيتوصلوا كلوحة مفاتيح أو منفذ سيريال، '
          'فمش بيظهروا هنا. درج الكاش بيفتح من طابعة الإيصالات نفسها.',
          style: AppText.caption.copyWith(fontSize: 11.5),
        ),
      ],
    );
  }
}
