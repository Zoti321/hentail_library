import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/reader/domain/auto_play_interval.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_adaptive_panel.dart';
import 'package:hentai_library/features/reader/presentation/l10n/reading_preference_l10n.dart';
import 'package:hentai_library/features/reader/application/reading_preferences_acl.dart';
import 'package:hentai_library/features/reader/presentation/providers/reading_preferences_providers.dart';
import 'package:hentai_library/shared/ui/widgets/settings/content_section.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读设置面板（MD3E，#393 第三批）：与设置页「阅读」分类共用唯一写入口
/// [readingPreferencesControllerProvider]（ADR-0046）。
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
    final ReadingPreferences prefs = ref.watch(readingPreferencesProvider);
    final ReadingPreferencesController controller = ref.read(
      readingPreferencesControllerProvider,
    );

    final ReadingMode mode = prefs.readingMode;
    final ReaderModeCategory category = mode.category;
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    final int interval = prefs.autoPlayIntervalSeconds;

    void applyReadingMode(ReadingMode value) {
      unawaited(
        controller.setReadingModeId(
          ReadingPreferencesAcl.encode(prefs.copyWith(readingMode: value))
              .readingModeId,
        ),
      );
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
              value: Text(l10n.autoPlayModeLabel(prefs.autoPlayMode)),
              onTap: () => _pickOption<AutoPlayMode>(
                context,
                title: l10n.readerSettingsAutoPlayMode,
                options: AutoPlayMode.values,
                current: prefs.autoPlayMode,
                labelOf: l10n.autoPlayModeLabel,
                onSelected: (AutoPlayMode value) {
                  unawaited(
                    controller.setAutoPlayModeId(
                      ReadingPreferencesAcl.encode(
                        prefs.copyWith(autoPlayMode: value),
                      ).autoPlayModeId,
                    ),
                  );
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
                            controller.setAutoPlayIntervalSeconds(interval - 1),
                          ),
                  ),
                  Text('$interval ${l10n.readerSettingsSecondsSuffix}'),
                  IconButton(
                    icon: const Icon(Symbols.add),
                    onPressed: interval >= kReaderAutoPlayIntervalMax
                        ? null
                        : () => unawaited(
                            controller.setAutoPlayIntervalSeconds(interval + 1),
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
              enabled: prefs.webtoonZoomMode == WebtoonZoomMode.fitWidth,
              value: Text(
                l10n.readerWebtoonMarginLabel(prefs.webtoonMarginPercent),
              ),
              onTap: () => _pickOption<int>(
                context,
                title: l10n.readerSettingsHorizontalMargin,
                options: _kWebtoonMarginOptions,
                current: prefs.webtoonMarginPercent,
                labelOf: l10n.readerWebtoonMarginLabel,
                onSelected: (int value) {
                  unawaited(controller.setWebtoonMarginPercent(value));
                },
              ),
            ),
            SettingsNavigationTile(
              leading: Symbols.zoom_in,
              title: Text(l10n.readerSettingsZoomMode),
              value: Text(l10n.webtoonZoomModeLabel(prefs.webtoonZoomMode)),
              onTap: () => _pickOption<WebtoonZoomMode>(
                context,
                title: l10n.readerSettingsZoomMode,
                options: WebtoonZoomMode.values,
                current: prefs.webtoonZoomMode,
                labelOf: l10n.webtoonZoomModeLabel,
                onSelected: (WebtoonZoomMode value) {
                  unawaited(
                    controller.setWebtoonZoomModeId(
                      ReadingPreferencesAcl.encode(
                        prefs.copyWith(webtoonZoomMode: value),
                      ).webtoonZoomModeId,
                    ),
                  );
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
