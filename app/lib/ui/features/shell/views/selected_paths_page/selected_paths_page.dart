import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/view_models/selected_paths_page_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/selected_paths_page/selected_paths_layout_constants.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';

import 'widgets/widgets.dart';

class SelectedPathsPage extends ConsumerWidget {
  const SelectedPathsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final AsyncValue<SelectedPathsPageState> asyncState = ref.watch(
      selectedPathsPageProvider,
    );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final SelectedPathsLayoutTier layoutTier =
            selectedPathsLayoutTierForWidth(viewportWidth);
        final double horizontalPadding = selectedPathsContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = selectedPathsInnerContentMaxWidth(
          layoutTier,
          viewportWidth,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            tokens.layout.contentAreaPadding.top,
            horizontalPadding,
            tokens.layout.contentAreaPadding.bottom,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: innerMaxWidth),
              child: Column(
                spacing: 20,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SelectedPathsPageHeader(
                    layoutTier: layoutTier,
                    onOpenNavigation: appShellPageNavigationOpener(context),
                  ),
                  asyncState.when(
                    data: (_) => const SelectedPathsListCard(),
                    loading: () => const SelectedPathsLoadingCard(),
                    error: (Object error, StackTrace _) =>
                        SelectedPathsErrorCard(error: error),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
