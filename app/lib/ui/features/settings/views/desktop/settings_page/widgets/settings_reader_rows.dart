import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/reading/reading_mode.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/settings/views/desktop/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/ui/features/settings/views/desktop/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ReaderModeRow extends ConsumerWidget {
  const ReaderModeRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ReadingMode mode = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.readingMode ?? kDefaultReadingMode,
      ),
    );
    return SettingsRow(
      icon: Icon(
        LucideIcons.bookOpen,
        size: 20,
        color: Theme.of(context).colorScheme.hentai.iconDefault,
      ),
      label: '默认阅读模式',
      description: mode.labelZh,
      action: SizedBox(
        width: 180,
        child: DropdownButton<ReadingMode>(
          isExpanded: true,
          value: mode,
          items: ReadingMode.values
              .map(
                (ReadingMode value) => DropdownMenuItem<ReadingMode>(
                  value: value,
                  child: Text(value.labelZh, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(growable: false),
          onChanged: (ReadingMode? value) {
            if (value == null) {
              return;
            }
            ref.read(settingsProvider.notifier).setReadingMode(value);
          },
        ),
      ),
    );
  }
}

class ReaderAutoPlayIntervalRow extends ConsumerWidget {
  const ReaderAutoPlayIntervalRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final int seconds = ref.watch(
      settingsProvider.select(
        (AsyncValue<AppSetting> async) =>
            async.asData?.value.readerAutoPlayIntervalSeconds ?? 5,
      ),
    );
    return SettingsRow(
      icon: Icon(
        LucideIcons.timer,
        size: 20,
        color: Theme.of(context).colorScheme.hentai.iconDefault,
      ),
      label: '自动播放间隔',
      description: '$seconds 秒',
      action: IntervalAdjuster(
        value: seconds,
        min: readerAutoPlayIntervalMin,
        max: readerAutoPlayIntervalMax,
        onDecrease: () {
          ref
              .read(settingsProvider.notifier)
              .setReaderAutoPlayIntervalSeconds(seconds - 1);
        },
        onIncrease: () {
          ref
              .read(settingsProvider.notifier)
              .setReaderAutoPlayIntervalSeconds(seconds + 1);
        },
      ),
    );
  }
}
