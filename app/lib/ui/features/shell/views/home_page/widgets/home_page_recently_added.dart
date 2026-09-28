import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/read_models/home_page_read_models.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/image/comic_cover_content.dart';
import 'package:hentai_library/ui/core/widgets/foundation/horizontal_wheel_scroll_listener.dart';
import 'package:hentai_library/ui/features/shell/view_models/home_page_dashboard_notifier.dart';
import 'package:hentai_library/ui/features/shell/views/home_page/widgets/home_page_constants.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';
import 'package:hentai_library/ui/features/shell/views/routing/reader_route_args.dart';

class HomeRecentlyAddedSection extends ConsumerStatefulWidget {
  const HomeRecentlyAddedSection({
    super.key,
    required this.layoutTier,
    required this.enabled,
  });

  final HomePageLayoutTier layoutTier;
  final bool enabled;

  @override
  ConsumerState<HomeRecentlyAddedSection> createState() =>
      _HomeRecentlyAddedSectionState();
}

class _HomeRecentlyAddedSectionState
    extends ConsumerState<HomeRecentlyAddedSection> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme colorScheme = theme.colorScheme;
    final l10n = context.l10n;
    if (!widget.enabled) {
      return const SizedBox.shrink();
    }
    final AsyncValue<List<HomeRecentlyAddedEntry>> entriesAsync = ref.watch(
      homeRecentlyAddedStreamProvider,
    );
    return entriesAsync.when(
      data: (List<HomeRecentlyAddedEntry> entries) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l10n.homeRecentlyAdded,
              style: TextStyle(
                fontSize: tokens.text.titleSm,
                fontWeight: FontWeight.w600,
                color: colorScheme.hentai.textPrimary,
              ),
            ),
            SizedBox(height: tokens.spacing.sm),
            SizedBox(
              height: continueReadingStripHeight + 8,
              child: HorizontalWheelScrollListener(
                controller: _scrollController,
                child: ListView.separated(
                  controller: _scrollController,
                  scrollDirection: Axis.horizontal,
                  itemCount: entries.length,
                  separatorBuilder: (_, _) =>
                      SizedBox(width: tokens.spacing.md),
                  itemBuilder: (BuildContext context, int index) {
                    final HomeRecentlyAddedEntry entry = entries[index];
                    return SizedBox(
                      width: continueReadingItemWidthFor(widget.layoutTier),
                      height: continueReadingStripHeight,
                      child: _RecentlyAddedCard(entry: entry, index: index),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _RecentlyAddedCard extends StatelessWidget {
  const _RecentlyAddedCard({required this.entry, required this.index});

  final HomeRecentlyAddedEntry entry;
  final int index;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return Material(
      color: cs.surface,
      borderRadius: BorderRadius.circular(tokens.radius.xs),
      child: InkWell(
        borderRadius: BorderRadius.circular(tokens.radius.xs),
        onTap: () => appRouter.pushNamed(
          ReaderRouteArgs.readerRouteName,
          queryParameters: ReaderRouteArgs(
            comicId: entry.comicId,
          ).toQueryParameters(),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.xs),
            border: Border.all(color: cs.hentai.borderSubtle),
          ),
          child: Row(
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(tokens.radius.md),
                  bottomRight: Radius.circular(tokens.radius.md),
                ),
                child: SizedBox(
                  width: continueReadingStripHeight * 2 / 3,
                  height: double.infinity,
                  child: ComicCoverContent(
                    comicId: entry.comicId,
                    gridIndex: index,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(tokens.spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: tokens.text.bodySm,
                          fontWeight: FontWeight.w600,
                          color: cs.hentai.textPrimary,
                        ),
                      ),
                      SizedBox(height: tokens.spacing.xs),
                      Text(
                        entry.libraryDisplayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: tokens.text.labelXs,
                          color: cs.hentai.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
