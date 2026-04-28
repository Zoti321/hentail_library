import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/app_setting.dart';
import 'package:hentai_library/presentation/providers/providers.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/widgets.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    return settingsAsync.when(
      data: (_) => const SettingsView(),

      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace _) {
        return Center(
          child: Text(
            error.toString(),
            style: TextStyle(color: theme.colorScheme.error),
          ),
        );
      },
    );
  }
}
