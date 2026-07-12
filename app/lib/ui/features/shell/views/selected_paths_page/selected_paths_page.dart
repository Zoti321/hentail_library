import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/shell/view_models/selected_paths_page_notifier.dart';

import 'widgets/widgets.dart';

class SelectedPathsPage extends ConsumerStatefulWidget {
  const SelectedPathsPage({super.key});

  @override
  ConsumerState<SelectedPathsPage> createState() => _SelectedPathsPageState();
}

class _SelectedPathsPageState extends ConsumerState<SelectedPathsPage> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
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

        final Widget headerSection = SelectedPathsPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          contentMaxWidth: innerMaxWidth,
        );
        final Widget header = KeyedSubtree(
          key: _headerMeasureKey,
          child: headerSection,
        );

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_headerExtent == null)
              SliverToBoxAdapter(child: header)
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: SelectedPathsPinnedHeaderDelegate(
                  extent: _headerExtent!,
                  child: header,
                ),
              ),
            SliverToBoxAdapter(
              child: PageContentWidthAlign(
                horizontalPadding: horizontalPadding,
                maxWidth: innerMaxWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: tokens.layout.contentVerticalPadding,
                    bottom: tokens.layout.contentAreaPadding.bottom,
                  ),
                  child: asyncState.when(
                    data: (_) => const SelectedPathsListCard(),
                    loading: () => const SelectedPathsLoadingCard(),
                    error: (Object error, StackTrace _) =>
                        SelectedPathsErrorCard(error: error),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
