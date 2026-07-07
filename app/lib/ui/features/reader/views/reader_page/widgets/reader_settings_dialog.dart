import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hentai_library/domain/models/models.dart' show AppSetting;
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

Future<void> showReaderSettingsDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (BuildContext context) => const ReaderSettingsDialog(),
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
  int _webtoonMarginPercent = 0;
  WebtoonZoomMode _webtoonZoomMode = WebtoonZoomMode.fitWidth;
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
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

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ReaderSettingsDialogHeader(
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: Material(
                  color: cs.hentai.readerBackground,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      spacing: 16,
                      children: <Widget>[
                        _ReaderSettingsSection(
                          title: '常规',
                          children: <Widget>[
                            _ReaderSettingsDropdownRow<ReaderModeCategory>(
                              label: '阅读模式',
                              value: category,
                              items: ReaderModeCategory.values,
                              itemLabel: (ReaderModeCategory value) =>
                                  value.labelZh,
                              onChanged: (ReaderModeCategory? value) {
                                if (value == null) {
                                  return;
                                }
                                final ReadingMode nextMode = switch (value) {
                                  ReaderModeCategory.paged =>
                                    readingMode.pagedLayout?.toReadingMode() ??
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
                            title: '自动播放',
                            children: <Widget>[
                              _ReaderSettingsNumberRow(
                                label: '播放间隔',
                                suffix: '秒',
                                controller: _intervalController,
                                onCommit: (int value) {
                                  ref
                                      .read(settingsProvider.notifier)
                                      .setReaderAutoPlayIntervalSeconds(value);
                                },
                              ),
                            ],
                          ),
                        _ReaderSettingsSection(
                          title: readingMode.isWebtoon
                              ? 'Webtoon 模式'
                              : '分页阅读器选项',
                          children: readingMode.isWebtoon
                              ? <Widget>[
                                  _ReaderSettingsDropdownRow<int>(
                                    label: '左右边距',
                                    value: _webtoonMarginPercent,
                                    items: List<int>.generate(
                                      9,
                                      (int index) => index * 5,
                                    ),
                                    itemLabel: (int value) =>
                                        value == 0 ? '无 (0%)' : '$value%',
                                    onChanged: (int? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _webtoonMarginPercent = value;
                                      });
                                    },
                                  ),
                                  _ReaderSettingsDropdownRow<WebtoonZoomMode>(
                                    label: '缩放模式',
                                    value: _webtoonZoomMode,
                                    items: WebtoonZoomMode.values,
                                    itemLabel: (WebtoonZoomMode value) =>
                                        value.labelZh,
                                    onChanged: (WebtoonZoomMode? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      setState(() {
                                        _webtoonZoomMode = value;
                                      });
                                    },
                                  ),
                                ]
                              : <Widget>[
                                  _ReaderSettingsDropdownRow<PagedLayout>(
                                    label: '页面布局',
                                    value: pagedLayout,
                                    items: PagedLayout.values,
                                    itemLabel: (PagedLayout value) =>
                                        value.labelZh,
                                    onChanged: (PagedLayout? value) {
                                      if (value == null) {
                                        return;
                                      }
                                      _applyReadingMode(value.toReadingMode());
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
  const _ReaderSettingsDialogHeader({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      child: SizedBox(
        height: 48,
        child: Row(
          children: <Widget>[
            IconButton(
              onPressed: onClose,
              tooltip: '关闭',
              icon: const Icon(LucideIcons.x, size: 18, color: Colors.white),
            ),
            const Expanded(
              child: Text(
                '阅读设置',
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

class _ReaderSettingsDropdownRow<T> extends StatelessWidget {
  const _ReaderSettingsDropdownRow({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> items;
  final String Function(T value) itemLabel;
  final ValueChanged<T?> onChanged;

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
          width: 180,
          child: DropdownButtonFormField<T>(
            value: value,
            isExpanded: true,
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: cs.hentai.inputBackground,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide.none,
              ),
            ),
            dropdownColor: cs.hentai.inputBackground,
            style: TextStyle(
              fontSize: 13,
              color: cs.hentai.readerTextIconPrimary,
            ),
            items: items
                .map(
                  (T item) => DropdownMenuItem<T>(
                    value: item,
                    child: Text(itemLabel(item)),
                  ),
                )
                .toList(),
            onChanged: onChanged,
          ),
        ),
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
