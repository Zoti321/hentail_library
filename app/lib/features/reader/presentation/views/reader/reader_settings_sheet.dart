import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/app_settings/public/providers/app_settings_providers.dart';
import 'package:hentai_library/features/reader/application/reading_preferences_acl.dart';
import 'package:hentai_library/features/reader/domain/auto_play_interval.dart';
import 'package:hentai_library/features/reader/domain/auto_play_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_mode.dart';
import 'package:hentai_library/features/reader/domain/reading_preferences.dart';
import 'package:hentai_library/features/reader/presentation/l10n/reading_preference_l10n.dart';
import 'package:hentai_library/features/reader/presentation/patterns/reader/reader_adaptive_panel.dart';
import 'package:hentai_library/features/reader/presentation/providers/reading_preferences_providers.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 阅读设置面板（MD3E）：与设置页「阅读」分类共用唯一写入口
/// [readingPreferencesControllerProvider]（ADR-0046）。
abstract final class ReaderSettingsSheet {
  ReaderSettingsSheet._();

  static Future<void> show(
    BuildContext context, {
    bool seriesAutoPlayModes = true,
  }) {
    return ReaderAdaptivePanel.show<void>(
      context,
      // expanded+ side sheet 仍需 title（dialog 名）；关闭钮与 bottom 全屏头关闭。
      title: context.l10n.readerSettingsTitle,
      expandToFullScreen: false,
      showCloseButton: false,
      scrollable: false,
      body: _ReaderSettingsBody(seriesAutoPlayModes: seriesAutoPlayModes),
    );
  }
}

/// 条漫边距可选值（百分比），步长 5。
final List<int> _kWebtoonMarginOptions = List<int>.generate(
  9,
  (int i) => i * 5,
);

class _ReaderSettingsBody extends ConsumerWidget {
  const _ReaderSettingsBody({this.seriesAutoPlayModes = true});

  final bool seriesAutoPlayModes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData m3e = M3ETheme.of(context);
    final M3ESpacing spacing = m3e.spacing;
    final ReadingPreferences prefs = ref.watch(readingPreferencesProvider);
    final ReadingPreferencesController controller = ref.read(
      readingPreferencesControllerProvider,
    );
    final List<AutoPlayMode> autoPlayOptions = seriesAutoPlayModes
        ? AutoPlayMode.values
        : const <AutoPlayMode>[AutoPlayMode.comicOnce, AutoPlayMode.comicLoop];

    final ReadingMode mode = prefs.readingMode;
    final ReaderModeCategory category = mode.category;
    final PagedLayout pagedLayout = mode.pagedLayout ?? PagedLayout.single;
    final int interval = prefs.autoPlayIntervalSeconds;
    final bool marginEnabled =
        prefs.webtoonZoomMode == WebtoonZoomMode.fitWidth;
    final AutoPlayMode selectedAutoPlay =
        autoPlayOptions.contains(prefs.autoPlayMode)
        ? prefs.autoPlayMode
        : AutoPlayMode.comicOnce;

    void applyReadingMode(ReadingMode value) {
      unawaited(
        controller.setReadingModeId(
          ReadingPreferencesAcl.encode(prefs.copyWith(readingMode: value))
              .readingModeId,
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        spacing.md,
        spacing.sm,
        spacing.md,
        spacing.lg,
      ),
      children: <Widget>[
        _ReaderSettingSection(
          title: l10n.readerSettingsReadingMode,
          child: _ReaderSettingChipGroup<ReaderModeCategory>(
            options: ReaderModeCategory.values,
            selected: category,
            labelOf: l10n.readerModeCategoryLabel,
            onSelected: (ReaderModeCategory value) {
              applyReadingMode(switch (value) {
                ReaderModeCategory.paged => pagedLayout.toReadingMode(),
                ReaderModeCategory.webtoon => ReadingMode.webtoon,
              });
            },
          ),
        ),
        SizedBox(height: spacing.lg),
        _ReaderSettingSection(
          title: l10n.readerSettingsAutoPlay,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ReaderSettingChipGroup<AutoPlayMode>(
                options: autoPlayOptions,
                selected: selectedAutoPlay,
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
              SizedBox(height: spacing.md),
              _AutoPlayIntervalRow(
                label: l10n.readerSettingsPlayInterval,
                interval: interval,
                secondsSuffix: l10n.readerSettingsSecondsSuffix,
                onDecrement: interval <= kReaderAutoPlayIntervalMin
                    ? null
                    : () => unawaited(
                        controller.setAutoPlayIntervalSeconds(interval - 1),
                      ),
                onIncrement: interval >= kReaderAutoPlayIntervalMax
                    ? null
                    : () => unawaited(
                        controller.setAutoPlayIntervalSeconds(interval + 1),
                      ),
              ),
            ],
          ),
        ),
        SizedBox(height: spacing.lg),
        _ReaderSettingSection(
          title: l10n.readerSettingsPagedOptions,
          child: _ReaderSettingChipGroup<PagedLayout>(
            options: PagedLayout.values,
            selected: pagedLayout,
            labelOf: l10n.pagedLayoutLabel,
            onSelected: (PagedLayout value) {
              applyReadingMode(value.toReadingMode());
            },
          ),
        ),
        SizedBox(height: spacing.lg),
        _ReaderSettingSection(
          title: l10n.readerSettingsWebtoonMode,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _ReaderSettingSubheader(
                title: l10n.readerSettingsHorizontalMargin,
              ),
              SizedBox(height: spacing.sm),
              _ReaderSettingChipGroup<int>(
                options: _kWebtoonMarginOptions,
                selected: prefs.webtoonMarginPercent,
                labelOf: l10n.readerWebtoonMarginLabel,
                enabled: marginEnabled,
                onSelected: (int value) {
                  unawaited(controller.setWebtoonMarginPercent(value));
                },
              ),
              SizedBox(height: spacing.md),
              _ReaderSettingSubheader(title: l10n.readerSettingsZoomMode),
              SizedBox(height: spacing.sm),
              _ReaderSettingChipGroup<WebtoonZoomMode>(
                options: WebtoonZoomMode.values,
                selected: prefs.webtoonZoomMode,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _ReaderSettingSection extends StatelessWidget {
  const _ReaderSettingSection({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            title,
            style: m3e.typeScale.titleSmall.copyWith(
              color: m3e.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: m3e.spacing.sm),
        child,
      ],
    );
  }
}

class _ReaderSettingSubheader extends StatelessWidget {
  const _ReaderSettingSubheader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    return Text(
      title,
      style: m3e.typeScale.bodyMedium.copyWith(
        color: m3e.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ReaderSettingChipGroup<T> extends StatelessWidget {
  const _ReaderSettingChipGroup({
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
    this.enabled = true,
  });

  final List<T> options;
  final T selected;
  final String Function(T value) labelOf;
  final ValueChanged<T> onSelected;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final M3ESpacing spacing = M3ETheme.of(context).spacing;
    return Wrap(
      spacing: spacing.sm,
      runSpacing: spacing.sm,
      children: <Widget>[
        for (final T option in options)
          M3EChip(
            label: labelOf(option),
            type: M3EChipType.filter,
            selected: option == selected,
            onPressed: enabled ? () => onSelected(option) : null,
          ),
      ],
    );
  }
}

class _AutoPlayIntervalRow extends StatelessWidget {
  const _AutoPlayIntervalRow({
    required this.label,
    required this.interval,
    required this.secondsSuffix,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final int interval;
  final String secondsSuffix;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData m3e = M3ETheme.of(context);
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: m3e.typeScale.bodyLarge.copyWith(
              color: m3e.colorScheme.onSurface,
            ),
          ),
        ),
        IconButton(icon: const Icon(Symbols.remove), onPressed: onDecrement),
        Text(
          '$interval $secondsSuffix',
          style: m3e.typeScale.bodyLarge.copyWith(
            color: m3e.colorScheme.onSurface,
          ),
        ),
        IconButton(icon: const Icon(Symbols.add), onPressed: onIncrement),
      ],
    );
  }
}
