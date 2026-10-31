import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/md3e/patterns/reader/md3e_reader_adaptive_panel.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_content_section.dart';
import 'package:hentai_library/md3e/widgets/settings/md3e_settings_tile.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/shared/domain/models/models.dart'
    show AppSetting;
import 'package:hentai_library/shared/domain/ports/reader_settings_command_port.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_interval.dart';
import 'package:hentai_library/shared/domain/reading/auto_play_mode.dart';
import 'package:hentai_library/shared/domain/reading/reading_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读设置面板（MD3E，#393 第三批）：绑定真实应用设置，写入经 [ReaderSettingsCommandPort]。
abstract final class ReaderMd3eSettingsSheet {
  ReaderMd3eSettingsSheet._();

  static Future<void> show(BuildContext context) {
    return Md3eReaderAdaptivePanel.show<void>(
      context,
      title: context.l10n.readerSettingsTitle,
      body: const _ReaderMd3eSettingsBody(),
    );
  }
}

/// 条漫边距可选值（百分比），步长 5。
final List<int> _kWebtoonMarginOptions = List<int>.generate(
  9,
  (int i) => i * 5,
);

class _ReaderMd3eSettingsBody extends ConsumerWidget {
  const _ReaderMd3eSettingsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AppSetting? settings = ref
        .watch(appSettingsStateProvider)
        .asData
        ?.value;
    if (settings == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final ReaderSettingsCommandPort port = ref.read(
      readerSettingsCommandPortProvider,
    );
    final ReadingMode mode = settings.readingMode;
    final ReaderModeCategory category = mode.category;
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    final bool isWebtoon = mode.isWebtoon;
    final int interval = settings.readerAutoPlayIntervalSeconds;

    void applyReadingMode(ReadingMode value) {
      unawaited(port.setReadingMode(value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Md3eContentSection.group(
          title: l10n.readerSettingsReadingMode,
          children: <Widget>[
            Md3eSettingsNavigationTile(
              leading: Symbols.menu_book,
              title: Text(l10n.readerSettingsReadingMode),
              value: Text(l10n.readerModeCategoryLabel(category)),
              onTap: () => _pickOption<ReaderModeCategory>(
                context,
                title: l10n.readerSettingsReadingMode,
                options: ReaderModeCategory.values,
                current: category,
                labelOf: l10n.readerModeCategoryLabel,
                onSelected: (ReaderModeCategory value) {
                  applyReadingMode(switch (value) {
                    ReaderModeCategory.paged => pagedLayout.toReadingMode(),
                    ReaderModeCategory.webtoon => ReadingMode.webtoon,
                  });
                },
              ),
            ),
          ],
        ),
        if (!isWebtoon)
          Md3eContentSection.group(
            title: l10n.readerSettingsPagedOptions,
            children: <Widget>[
              Md3eSettingsNavigationTile(
                leading: Symbols.view_day,
                title: Text(l10n.readerSettingsPageLayout),
                value: Text(l10n.pagedLayoutLabel(pagedLayout)),
                onTap: () => _pickOption<PagedLayout>(
                  context,
                  title: l10n.readerSettingsPageLayout,
                  options: PagedLayout.values,
                  current: pagedLayout,
                  labelOf: l10n.pagedLayoutLabel,
                  onSelected: (PagedLayout value) {
                    applyReadingMode(value.toReadingMode());
                  },
                ),
              ),
            ],
          ),
        if (isWebtoon)
          Md3eContentSection.group(
            title: l10n.readerSettingsWebtoonMode,
            children: <Widget>[
              Md3eSettingsNavigationTile(
                leading: Symbols.width_normal,
                title: Text(l10n.readerSettingsHorizontalMargin),
                enabled: settings.webtoonZoomMode == WebtoonZoomMode.fitWidth,
                value: Text(
                  l10n.readerWebtoonMarginLabel(settings.webtoonMarginPercent),
                ),
                onTap: () => _pickOption<int>(
                  context,
                  title: l10n.readerSettingsHorizontalMargin,
                  options: _kWebtoonMarginOptions,
                  current: settings.webtoonMarginPercent,
                  labelOf: l10n.readerWebtoonMarginLabel,
                  onSelected: (int value) {
                    unawaited(port.setWebtoonMarginPercent(value));
                  },
                ),
              ),
              Md3eSettingsNavigationTile(
                leading: Symbols.zoom_in,
                title: Text(l10n.readerSettingsZoomMode),
                value: Text(
                  l10n.webtoonZoomModeLabel(settings.webtoonZoomMode),
                ),
                onTap: () => _pickOption<WebtoonZoomMode>(
                  context,
                  title: l10n.readerSettingsZoomMode,
                  options: WebtoonZoomMode.values,
                  current: settings.webtoonZoomMode,
                  labelOf: l10n.webtoonZoomModeLabel,
                  onSelected: (WebtoonZoomMode value) {
                    unawaited(port.setWebtoonZoomMode(value));
                  },
                ),
              ),
            ],
          ),
        Md3eContentSection.group(
          title: l10n.readerSettingsAutoPlay,
          children: <Widget>[
            Md3eSettingsNavigationTile(
              leading: Symbols.repeat,
              title: Text(l10n.readerSettingsAutoPlayMode),
              value: Text(l10n.autoPlayModeLabel(settings.autoPlayMode)),
              onTap: () => _pickOption<AutoPlayMode>(
                context,
                title: l10n.readerSettingsAutoPlayMode,
                options: AutoPlayMode.values,
                current: settings.autoPlayMode,
                labelOf: l10n.autoPlayModeLabel,
                onSelected: (AutoPlayMode value) {
                  unawaited(port.setAutoPlayMode(value));
                },
              ),
            ),
            Md3eSettingsNavigationTile(
              leading: Symbols.timer,
              title: Text(l10n.readerSettingsPlayInterval),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Symbols.remove),
                    onPressed: interval <= kReaderAutoPlayIntervalMin
                        ? null
                        : () => unawaited(
                            port.setReaderAutoPlayIntervalSeconds(
                              clampReaderAutoPlayInterval(interval - 1),
                            ),
                          ),
                  ),
                  Text('$interval ${l10n.readerSettingsSecondsSuffix}'),
                  IconButton(
                    icon: const Icon(Symbols.add),
                    onPressed: interval >= kReaderAutoPlayIntervalMax
                        ? null
                        : () => unawaited(
                            port.setReaderAutoPlayIntervalSeconds(
                              clampReaderAutoPlayInterval(interval + 1),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// 二级选项列表：选中后关闭自身并回调。
Future<void> _pickOption<T>(
  BuildContext context, {
  required String title,
  required List<T> options,
  required T current,
  required String Function(T value) labelOf,
  required ValueChanged<T> onSelected,
}) {
  return Md3eReaderAdaptivePanel.show<void>(
    context,
    title: title,
    body: Builder(
      builder: (BuildContext sheetContext) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (final T option in options)
              ListTile(
                title: Text(labelOf(option)),
                trailing: option == current ? const Icon(Symbols.check) : null,
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  onSelected(option);
                },
              ),
          ],
        );
      },
    ),
  );
}
