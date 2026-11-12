import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/app_settings/public/reading_preferences_schema.dart';
import 'package:hentai_library/features/reader/domain/auto_play_interval.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/presentation/l10n/reading_preference_l10n.dart';
import 'package:hentai_library/features/reader/application/reading_preferences_acl.dart';
import 'package:hentai_library/features/reader/presentation/providers/reading_preferences_providers.dart';
import 'package:hentai_library/design-system/components/menu/anchored_option_picker.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_list.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_tile.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 设置页「阅读」分类的分区（owner = `reader`，ADR-0046 §6）。
///
/// 与阅读器内面板共用同一读入口（[readingPreferencesProvider]）与唯一写入口
/// （[readingPreferencesControllerProvider]）；外观独立，不合并 UI。
List<Widget> readerSettingsSections(BuildContext context) {
  return const <Widget>[
    SettingsSection(
      title: _ReadingModeSectionTitle(),
      tiles: <Widget>[_ReadingModeCategoryTile()],
    ),
    SettingsSection(
      title: _AutoPlaySectionTitle(),
      tiles: <Widget>[_AutoPlayModeTile(), _AutoPlayIntervalTile()],
    ),
    SettingsSection(
      title: _PagedOptionsSectionTitle(),
      tiles: <Widget>[_PagedLayoutTile()],
    ),
    SettingsSection(
      title: _WebtoonModeSectionTitle(),
      tiles: <Widget>[_WebtoonMarginTile(), _WebtoonZoomModeTile()],
    ),
  ];
}

/// 条漫边距可选值（百分比），步长 5。
final List<int> _kWebtoonMarginOptions = List<int>.generate(
  ReadingPreferenceSchema.maxWebtoonMarginPercent ~/
          ReadingPreferenceSchema.webtoonMarginPercentStep +
      1,
  (int i) => i * ReadingPreferenceSchema.webtoonMarginPercentStep,
);

class _ReadingModeSectionTitle extends StatelessWidget {
  const _ReadingModeSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.readerSettingsReadingMode);
  }
}

class _AutoPlaySectionTitle extends StatelessWidget {
  const _AutoPlaySectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.readerSettingsAutoPlay);
  }
}

class _PagedOptionsSectionTitle extends StatelessWidget {
  const _PagedOptionsSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.readerSettingsPagedOptions);
  }
}

class _WebtoonModeSectionTitle extends StatelessWidget {
  const _WebtoonModeSectionTitle();

  @override
  Widget build(BuildContext context) {
    return Text(context.l10n.readerSettingsWebtoonMode);
  }
}

/// 把「改成某领域值」编码为持久化原语后经唯一写入口落库。
void _writeReadingMode(WidgetRef ref, ReadingMode mode) {
  ref
      .read(readingPreferencesControllerProvider)
      .setReadingModeId(
        ReadingPreferencesAcl.encode(
          ref.read(readingPreferencesProvider).copyWith(readingMode: mode),
        ).readingModeId,
      );
}

void _writeWebtoonZoomMode(WidgetRef ref, WebtoonZoomMode mode) {
  ref
      .read(readingPreferencesControllerProvider)
      .setWebtoonZoomModeId(
        ReadingPreferencesAcl.encode(
          ref.read(readingPreferencesProvider).copyWith(webtoonZoomMode: mode),
        ).webtoonZoomModeId,
      );
}

void _writeAutoPlayMode(WidgetRef ref, AutoPlayMode mode) {
  ref
      .read(readingPreferencesControllerProvider)
      .setAutoPlayModeId(
        ReadingPreferencesAcl.encode(
          ref.read(readingPreferencesProvider).copyWith(autoPlayMode: mode),
        ).autoPlayModeId,
      );
}

class _ReadingModeCategoryTile extends ConsumerWidget {
  const _ReadingModeCategoryTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ReadingMode mode = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => p.readingMode,
      ),
    );
    final ReaderModeCategory category = mode.category;
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    return SettingsNavigationTile(
      leading: Symbols.menu_book,
      title: Text(l10n.readerSettingsReadingMode),
      value: Text(l10n.readerModeCategoryLabel(category)),
      onTap: () => pickAnchoredOption<ReaderModeCategory>(
        context,
        options: ReaderModeCategory.values,
        selected: category,
        labelOf: l10n.readerModeCategoryLabel,
        onSelected: (ReaderModeCategory value) {
          _writeReadingMode(ref, switch (value) {
            ReaderModeCategory.paged => pagedLayout.toReadingMode(),
            ReaderModeCategory.webtoon => ReadingMode.webtoon,
          });
        },
      ),
    );
  }
}

class _PagedLayoutTile extends ConsumerWidget {
  const _PagedLayoutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ReadingMode mode = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => p.readingMode,
      ),
    );
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    return SettingsNavigationTile(
      leading: Symbols.view_day,
      title: Text(l10n.readerSettingsPageLayout),
      value: Text(l10n.pagedLayoutLabel(pagedLayout)),
      onTap: () => pickAnchoredOption<PagedLayout>(
        context,
        options: PagedLayout.values,
        selected: pagedLayout,
        labelOf: l10n.pagedLayoutLabel,
        onSelected: (PagedLayout value) {
          _writeReadingMode(ref, value.toReadingMode());
        },
      ),
    );
  }
}

class _WebtoonMarginTile extends ConsumerWidget {
  const _WebtoonMarginTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final ({int marginPercent, WebtoonZoomMode zoomMode}) state = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => (
          marginPercent: p.webtoonMarginPercent,
          zoomMode: p.webtoonZoomMode,
        ),
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.width_normal,
      title: Text(l10n.readerSettingsHorizontalMargin),
      enabled: state.zoomMode == WebtoonZoomMode.fitWidth,
      value: Text(l10n.readerWebtoonMarginLabel(state.marginPercent)),
      onTap: () => pickAnchoredOption<int>(
        context,
        options: _kWebtoonMarginOptions,
        selected: state.marginPercent,
        labelOf: l10n.readerWebtoonMarginLabel,
        onSelected: ref
            .read(readingPreferencesControllerProvider)
            .setWebtoonMarginPercent,
      ),
    );
  }
}

class _WebtoonZoomModeTile extends ConsumerWidget {
  const _WebtoonZoomModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final WebtoonZoomMode zoomMode = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => p.webtoonZoomMode,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.zoom_in,
      title: Text(l10n.readerSettingsZoomMode),
      value: Text(l10n.webtoonZoomModeLabel(zoomMode)),
      onTap: () => pickAnchoredOption<WebtoonZoomMode>(
        context,
        options: WebtoonZoomMode.values,
        selected: zoomMode,
        labelOf: l10n.webtoonZoomModeLabel,
        onSelected: (WebtoonZoomMode value) {
          _writeWebtoonZoomMode(ref, value);
        },
      ),
    );
  }
}

class _AutoPlayModeTile extends ConsumerWidget {
  const _AutoPlayModeTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final AutoPlayMode mode = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => p.autoPlayMode,
      ),
    );
    return SettingsNavigationTile(
      leading: Symbols.repeat,
      title: Text(l10n.readerSettingsAutoPlayMode),
      value: Text(l10n.autoPlayModeLabel(mode)),
      onTap: () => pickAnchoredOption<AutoPlayMode>(
        context,
        options: AutoPlayMode.values,
        selected: mode,
        labelOf: l10n.autoPlayModeLabel,
        onSelected: (AutoPlayMode value) {
          _writeAutoPlayMode(ref, value);
        },
      ),
    );
  }
}

class _AutoPlayIntervalTile extends ConsumerWidget {
  const _AutoPlayIntervalTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final int interval = ref.watch(
      readingPreferencesProvider.select(
        (ReadingPreferences p) => p.autoPlayIntervalSeconds,
      ),
    );
    final ReadingPreferencesController controller = ref.read(
      readingPreferencesControllerProvider,
    );
    return SettingsNavigationTile(
      leading: Symbols.timer,
      title: Text(l10n.readerSettingsPlayInterval),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
            icon: const Icon(Symbols.remove),
            onPressed: interval <= kReaderAutoPlayIntervalMin
                ? null
                : () => controller.setAutoPlayIntervalSeconds(interval - 1),
          ),
          Text('$interval ${l10n.readerSettingsSecondsSuffix}'),
          IconButton(
            icon: const Icon(Symbols.add),
            onPressed: interval >= kReaderAutoPlayIntervalMax
                ? null
                : () => controller.setAutoPlayIntervalSeconds(interval + 1),
          ),
        ],
      ),
    );
  }
}
