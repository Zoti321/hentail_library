import 'package:flutter/material.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_comics_section.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_page_header.dart';
import 'package:hentai_library/features/library_browse/presentation/author/patterns/author_detail/author_detail_page_metrics.dart';
import 'package:hentai_library/features/library_browse/presentation/author/views/author_detail/author_detail_header.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author_detail.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_header.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:hentai_library/shared/ui/widgets/navigation/expressive_library_scroll_to_top_button.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 作者资料 Lab：顶栏随滚动 + 窄列英雄区与作品 tonal 区块。
class AuthorDetailLayout extends StatefulWidget {
  const AuthorDetailLayout({
    super.key,
    required this.detail,
    this.onBack,
    this.scrollController,
  });

  final AuthorDetail detail;
  final VoidCallback? onBack;
  final ScrollController? scrollController;

  @override
  State<AuthorDetailLayout> createState() => _AuthorDetailPageState();
}

class _AuthorDetailPageState extends State<AuthorDetailLayout> {
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
    final PageLayoutSpec layout = PageLayoutSpec.of(context);
    final double horizontalPadding = layout.horizontalInset;
    final M3EThemeData theme = M3ETheme.of(context);
    final double contentGap = theme.spacing.xxl;

    final Widget header = AuthorDetailPageHeader(onBack: widget.onBack);

    final Widget body = Padding(
      padding: EdgeInsets.symmetric(horizontal: theme.spacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          AuthorDetailHeader(detail: widget.detail),
          SizedBox(height: contentGap),
          AuthorDetailComicsSection(detail: widget.detail),
        ],
      ),
    );

    return ColoredBox(
      color: labBrowseCanvasColor(scheme),
      child: Stack(
        children: <Widget>[
          CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: <Widget>[
              SliverToBoxAdapter(
                child: PageHeaderChrome(layout: layout, child: header),
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
                        maxWidth: kAuthorDetailContentMaxWidth,
                      ),
                      child: body,
                    ),
                  ),
                ),
              ),
            ],
          ),
          ExpressiveLibraryScrollToTopButton(
            scrollController: _scrollController,
            horizontalPadding: horizontalPadding,
          ),
        ],
      ),
    );
  }
}
