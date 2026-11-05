import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_comics_section.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_page_header.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail_md3e/author_detail_md3e_header.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/shared/md3e_page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 作者资料 Lab：顶栏随滚动 + 窄列英雄区与作品 tonal 区块。
class Md3eAuthorDetailPage extends StatefulWidget {
  const Md3eAuthorDetailPage({
    super.key,
    required this.detail,
    this.onBack,
    this.scrollController,
  });

  final AuthorDetail detail;
  final VoidCallback? onBack;
  final ScrollController? scrollController;

  @override
  State<Md3eAuthorDetailPage> createState() => _Md3eAuthorDetailPageState();
}

class _Md3eAuthorDetailPageState extends State<Md3eAuthorDetailPage> {
  late final ScrollController _scrollController;
  late final bool _ownsScrollController;

  @override
  void initState() {
    super.initState();
    _ownsScrollController = widget.scrollController == null;
    _scrollController = widget.scrollController ?? ScrollController();
  }

  @override
  void dispose() {
    if (_ownsScrollController) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Md3ePageLayoutSpec layout = Md3ePageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;
    final M3EThemeData theme = M3ETheme.of(context);
    final double contentGap = theme.spacing.xxl;

    final Widget header = Md3eAuthorDetailPageHeader(onBack: widget.onBack);

    final Widget body = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthorDetailMd3eHeader(detail: widget.detail),
          SizedBox(height: contentGap),
          Md3eAuthorDetailComicsSection(detail: widget.detail),
        ],
      ),
    );

    return ColoredBox(
      color: md3eLabBrowseCanvasColor(scheme),
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: Md3ePageHeaderChrome(
                  layout: layout,
                  child: header,
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  layout.headerToBodyGap,
                  horizontalPadding,
                  layout.bodyBottomInset,
                ),
                sliver: SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(
                        maxWidth: kMd3eAuthorDetailContentMaxWidth,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Md3eLibraryScrollToTopButton(
            scrollController: _scrollController,
            horizontalPadding: horizontalPadding,
          ),
        ],
      ),
    );
  }
}
