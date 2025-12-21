import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/view_models/selected_paths_page_notifier.dart';

import 'widgets/widgets.dart';

class SelectedPathsPage extends ConsumerWidget {
  const SelectedPathsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<SelectedPathsPageState> asyncState = ref.watch(
      selectedPathsPageProvider,
    );

    return SingleChildScrollView(
      padding: tokens.layout.contentAreaPadding,
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
