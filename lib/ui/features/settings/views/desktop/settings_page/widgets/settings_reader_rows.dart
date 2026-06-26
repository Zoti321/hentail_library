import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/model/app_setting.dart';
import 'package:hentai_library/ui/providers.dart';
import 'package:hentai_library/ui/features/settings/views/desktop/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/ui/features/settings/views/desktop/settings_page/widgets/settings_page_primitives.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
