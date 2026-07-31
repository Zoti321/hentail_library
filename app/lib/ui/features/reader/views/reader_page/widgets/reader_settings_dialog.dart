import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/form/fluent_select_field.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showReaderSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) {
      // 阅读页沉浸式：设置对话框始终深色，不跟随应用浅色主题。
      return Theme(
        data: buildAppTheme(Brightness.dark),
        child: const ReaderSettingsDialog(),
      );
    },
  );
}

class ReaderSettingsDialog extends ConsumerStatefulWidget {
  const ReaderSettingsDialog({super.key});

  @override
  ConsumerState<ReaderSettingsDialog> createState() =>
      _ReaderSettingsDialogState();
}

class _ReaderSettingsDialogState extends ConsumerState<ReaderSettingsDialog> {
  late final TextEditingController _intervalController;
  bool _intervalInitialized = false;

  @override
  void initState() {
    super.initState();
    _intervalController = TextEditingController();
  }

  @override
  void dispose() {
    _intervalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    final AppSetting? settings = settingsAsync.asData?.value;
    if (settings == null) {
      return const SizedBox.shrink();
    }

    if (!_intervalInitialized) {
      _intervalController.text = '${settings.readerAutoPlayIntervalSeconds}';
      _intervalInitialized = true;
    }

    final ReadingMode readingMode = settings.readingMode;
    final ReaderModeCategory category = readingMode.category;
    final PagedLayout pagedLayout =
        readingMode.pagedLayout ?? PagedLayout.single;
    final int webtoonMarginPercent = settings.webtoonMarginPercent;
    final WebtoonZoomMode webtoonZoomMode = settings.webtoonZoomMode;
    final bool marginEnabled = webtoonZoomMode == WebtoonZoomMode.fitWidth;

    // 阅读页沉浸式：始终深色，不跟随应用浅色主题。
    final ThemeData darkTheme = Theme.of(context).brightness == Brightness.dark
        ? Theme.of(context)
        : buildAppTheme(Brightness.dark);
    final ColorScheme darkCs = darkTheme.colorScheme;
    final AppThemeTokens darkTokens = darkTheme.extension<AppThemeTokens>()!;

    return Theme(
      data: darkTheme,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(darkTokens.radius.md),
          child: SizedBox(
            width: 420,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                _ReaderSettingsDialogHeader(
                  l10n: l10n,
                  onClose: () => Navigator.of(context).pop(),
                ),
                Flexible(
                  child: Material(
                    color: darkCs.hentai.readerBackground,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 16,
                        children: <Widget>[
                          _ReaderSettingsSection(
                            title: l10n.readerSettingsGeneral,
                            children: <Widget>[
                              FluentSelectField<ReaderModeCategory>(
                                labelText: l10n.readerSettingsReadingMode,
                                labelLayout: FluentSelectLabelLayout.inline,
                                value: category,
                                items: ReaderModeCategory.values,
                                itemLabel: (ReaderModeCategory value) =>
                                    l10n.readerModeCategoryLabel(value),
                                onChanged: (ReaderModeCategory? value) {
                                  if (value == null) {
                                    return;
                                  }
                                  final ReadingMode nextMode = switch (value) {
                                    ReaderModeCategory.paged =>
                                      readingMode.pagedLayout
                                              ?.toReadingMode() ??
                                          ReadingMode.paged,
                                    ReaderModeCategory.webtoon =>
                                      ReadingMode.webtoon,
                                  };
                                  _applyReadingMode(nextMode);
                                },
                              ),
                            ],
                          ),
                          if (!readingMode.isWebtoon)
                            _ReaderSettingsSection(
                              title: l10n.readerSettingsAutoPlay,
                              children: <Widget>[
                                _ReaderSettingsNumberRow(
                                  label: l10n.readerSettingsPlayInterval,
                                  suffix: l10n.readerSettingsSecondsSuffix,
                                  controller: _intervalController,
                                  onCommit: (int value) {
                                    ref
                                        .read(settingsProvider.notifier)
                                        .setReaderAutoPlayIntervalSeconds(
                                          value,
                                        );
                                  },
                                ),
                              ],
                            ),
                          _ReaderSettingsSection(
                            title: readingMode.isWebtoon
                                ? l10n.readerSettingsWebtoonMode
                                : l10n.readerSettingsPagedOptions,
                            children: readingMode.isWebtoon
                                ? <Widget>[
                                    FluentSelectField<int>(
                                      labelText:
                                          l10n.readerSettingsHorizontalMargin,
                                      labelLayout:
                                          FluentSelectLabelLayout.inline,
                                      value: webtoonMarginPercent,
                                      items: List<int>.generate(
                                        9,
                                        (int index) => index * 5,
                                      ),
                                      itemLabel: (int value) =>
                                          l10n.readerWebtoonMarginLabel(value),
                                      enabled: marginEnabled,
                                      onChanged: (int? value) {
                                        if (value == null) {
                                          return;
                                        }
                                        ref
                                            .read(settingsProvider.notifier)
                                            .setWebtoonMarginPercent(value);
                                      },
                                    ),
                                    FluentSelectField<WebtoonZoomMode>(
                                      labelText: l10n.readerSettingsZoomMode,
                                      labelLayout:
                                          FluentSelectLabelLayout.inline,
                                      value: webtoonZoomMode,
                                      items: WebtoonZoomMode.values,
                                      itemLabel: (WebtoonZoomMode value) =>
                                          l10n.webtoonZoomModeLabel(value),
                                      onChanged: (WebtoonZoomMode? value) {
                                        if (value == null) {
                                          return;
                                        }
                                        ref
                                            .read(settingsProvider.notifier)
                                            .setWebtoonZoomMode(value);
                                      },
                                    ),
                                  ]
                                : <Widget>[
                                    FluentSelectField<PagedLayout>(
                                      labelText: l10n.readerSettingsPageLayout,
                                      labelLayout:
                                          FluentSelectLabelLayout.inline,
                                      value: pagedLayout,
                                      items: PagedLayout.values,
                                      itemLabel: (PagedLayout value) =>
                                          l10n.pagedLayoutLabel(value),
                                      onChanged: (PagedLayout? value) {
                                        if (value == null) {
                                          return;
                                        }
                                        _applyReadingMode(
                                          value.toReadingMode(),
                                        );
                                      },
                                    ),
                                  ],
                          ),
                        ],
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

  Future<void> _applyReadingMode(ReadingMode mode) async {
    final SettingsNotifier notifier = ref.read(settingsProvider.notifier);
    await notifier.setReadingMode(mode);
    if (mode.isWebtoon) {
      final AppSetting? current = ref.read(settingsProvider).asData?.value;
      if (current?.readerAutoPlayEnabled == true) {
        await notifier.setReaderAutoPlayEnabled(false);
      }
    }
  }
}

class _ReaderSettingsDialogHeader extends StatelessWidget {
  const _ReaderSettingsDialogHeader({
    required this.l10n,
    required this.onClose,
  });

  final AppLocalizations l10n;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      child: SizedBox(
        height: 36,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: onClose,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              icon: const Icon(LucideIcons.x, size: 18, color: Colors.white),
            ),
            Expanded(
              child: Text(
                l10n.readerSettingsTitle,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReaderSettingsSection extends StatelessWidget {
  const _ReaderSettingsSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 8,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: cs.hentai.readerTextIconPrimary,
          ),
        ),
        ...children,
      ],
    );
  }
}

class _ReaderSettingsNumberRow extends StatelessWidget {
  const _ReaderSettingsNumberRow({
    required this.label,
    required this.suffix,
    required this.controller,
    required this.onCommit,
  });

  final String label;
  final String suffix;
  final TextEditingController controller;
  final ValueChanged<int> onCommit;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: cs.hentai.readerTextSecondary,
            ),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
            ],
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: cs.hentai.readerTextIconPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.hentai.inputBackground,
              suffixText: suffix,
              suffixStyle: TextStyle(
                fontSize: 12,
                color: cs.hentai.readerTextSecondary,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            onSubmitted: (String value) => _commit(value),
            onEditingComplete: () => _commit(controller.text),
          ),
        ),
      ],
    );
  }

  void _commit(String raw) {
    final int? parsed = int.tryParse(raw);
    if (parsed == null) {
      return;
    }
    final int clamped = parsed.clamp(1, 60);
    controller.text = '$clamped';
    onCommit(clamped);
  }
}
