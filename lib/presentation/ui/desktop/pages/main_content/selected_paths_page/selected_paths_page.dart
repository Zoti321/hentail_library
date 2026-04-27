import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/presentation/providers/pages/selected_paths/selected_paths_page_notifier.dart';
import 'package:hentai_library/presentation/ui/desktop/theme_token/token.dart';

import 'widgets/widgets.dart';

class SelectedPathsPage extends ConsumerWidget {
  const SelectedPathsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<SelectedPathsPageState> asyncState = ref.watch(
      selectedPathsPageProvider,
    );

    return SingleChildScrollView(
      padding: mainContentPadding,
      child: Column(
        spacing: 20,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const SelectedPathsPageHeader(),
          asyncState.when(
            data: (_) => const SelectedPathsListCard(),
            loading: () => const SelectedPathsLoadingCard(),
            error: (Object error, StackTrace _) =>
                SelectedPathsErrorCard(error: error),
          ),
        ],
      ),
    );
  }
}
