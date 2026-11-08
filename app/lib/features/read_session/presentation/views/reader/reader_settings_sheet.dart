import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/read_session/public/reading_preference_l10n.dart';
import 'package:hentai_library/features/read_session/presentation/patterns/reader/reader_adaptive_panel.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hentai_library/shared/di/app_settings_providers.dart';
import 'package:hentai_library/features/app_settings/public.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_interval.dart';
import 'package:hentai_library/features/read_session/domain/auto_play_mode.dart';
import 'package:hentai_library/features/read_session/domain/reading_mode.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读设置面板（MD3E，#393 第三批）：绑定真实应用设置，写入经 [ReaderSettingsCommandPort]。
abstract final class ReaderSettingsSheet {
  ReaderSettingsSheet._();

  static Future<void> show(BuildContext context) {
    return ReaderAdaptivePanel.show<void>(
      context,
      title: context.l10n.readerSettingsTitle,
      body: const _ReaderSettingsBody(),
    );
  }
}

/// 条漫边距可选值（百分比），步长 5。
final List<int> _kWebtoonMarginOptions = List<int>.generate(
  9,
  (int i) => i * 5,
);

class _ReaderSettingsBody extends ConsumerWidget {
  const _ReaderSettingsBody();

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
    final int interval = settings.readerAutoPlayIntervalSeconds;

    void applyReadingMode(ReadingMode value) {
      unawaited(port.setReadingMode(value));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ContentSection.group(
          title: l10n.readerSettingsReadingMode,
          children: <Widget>[
            SettingsNavigationTile(
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
        ContentSection.group(
          title: l10n.readerSettingsAutoPlay,
          children: <Widget>[
            SettingsNavigationTile(
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
            SettingsNavigationTile(
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
        ContentSection.group(
          title: l10n.readerSettingsPagedOptions,
          children: <Widget>[
            SettingsNavigationTile(
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
        ContentSection.group(
          title: l10n.readerSettingsWebtoonMode,
          children: <Widget>[
            SettingsNavigationTile(
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
            SettingsNavigationTile(
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
  return ReaderAdaptivePanel.show<void>(
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
