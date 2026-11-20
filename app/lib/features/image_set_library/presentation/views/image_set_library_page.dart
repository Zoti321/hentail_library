import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_browse_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_card.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_cover.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_page.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_library_filter_sheet.dart';
import 'package:hentai_library/features/library_admin/public.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tab_page_size_settings.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Image set 库浏览：header + paged body；会话内 card/list；同步 busy 投影。
class ImageSetLibraryPage extends ConsumerStatefulWidget {
  const ImageSetLibraryPage({
    super.key,
    required this.libraryId,
    required this.displayName,
  });

  final String libraryId;
  final String displayName;

  @override
  ConsumerState<ImageSetLibraryPage> createState() =>
      _ImageSetLibraryPageState();
}

class _ImageSetLibraryPageState extends ConsumerState<ImageSetLibraryPage> {
  final ScrollController _listScrollController = ScrollController();
  CatalogViewMode _viewMode = CatalogViewMode.grid;

  @override
  void dispose() {
    _listScrollController.dispose();
    super.dispose();
  }

  void _openDetail(ImageSet set) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            ImageSetDetailPage(libraryId: widget.libraryId, imageSet: set),
      ),
    );
  }

  void _setViewMode(CatalogViewMode mode) {
    setState(() => _viewMode = mode);
  }

  Future<void> _setPageSize(int pageSize) async {
    final ImageSetBrowsePreferences? current = ref
        .read(imageSetBrowsePreferencesProvider)
        .asData
        ?.value;
    if (current == null) {
      return;
    }
    await ref
        .read(imageSetBrowsePreferencesProvider.notifier)
        .replace(current.copyWith(pageSize: pageSize));
    ref
        .read(imageSetCatalogPageIndexProvider.notifier)
        .setPage(widget.libraryId, 1);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final bool busy = ref.watch(
      librarySyncStateProvider.select((LibrarySyncState s) {
        if (!s.running) {
          return false;
        }
        final String? targetId = s.targetLibraryId;
        return targetId == null || targetId == widget.libraryId;
      }),
    );
    final AsyncValue<ImageSetBrowsePreferences> prefsAsync = ref.watch(
      imageSetBrowsePreferencesProvider,
    );
    final AsyncValue<PagedImageSetCatalog> catalogAsync = ref.watch(
      imageSetCatalogPageProvider(widget.libraryId),
    );
    final bool filterActive =
        prefsAsync.asData?.value.hasActiveFilters ?? false;
    final int pageSize =
        prefsAsync.asData?.value.pageSize ?? kDefaultPageSize;

    return Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: theme.spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: LibraryToolbarRow(
                title: PageTitle(widget.displayName),
                trailing: <Widget>[
                  _PageSizeButton(
                    pageSize: pageSize,
                    onPageSizeChanged: _setPageSize,
                  ),
                  M3EIconButton(
                    key: const ValueKey<String>('imageSetFilterSort'),
                    icon: Icon(
                      Icons.filter_list,
                      size: LibraryPageHeaderMetrics.actionIconSize,
                      color: filterActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    variant: M3EIconButtonVariant.standard,
                    size: M3EIconButtonSize.sm,
                    tooltip: l10n.libraryFilterSortTooltip,
                    semanticLabel: l10n.libraryFilterSortSemantic,
                    onPressed: () => ImageSetLibraryFilterSheet.show(
                      context,
                      libraryId: widget.libraryId,
                    ),
                  ),
                ],
              ),
            ),
            if (busy) ...<Widget>[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: theme.spacing.sm),
                    const LinearProgressIndicator(
                      key: ValueKey<String>('imageSetSyncProgress'),
                    ),
                    SizedBox(height: theme.spacing.xs),
                    Text(
                      l10n.imageSetLibrarySyncing,
                      style: theme.typeScale.bodySmall.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            SizedBox(height: theme.spacing.md),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              child: Align(
                alignment: Alignment.centerRight,
                child: CatalogViewModeButtonGroup(
                  mode: _viewMode,
                  onModeChanged: _setViewMode,
                ),
              ),
            ),
            SizedBox(height: theme.spacing.sm),
            Expanded(
              child: catalogAsync.when(
                data: (PagedImageSetCatalog catalog) => catalog.items.isEmpty
                    ? Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalInset,
                        ),
                        child: _MessageText(l10n.imageSetListEmpty),
                      )
                    : _CatalogBody(
                        libraryId: widget.libraryId,
                        catalog: catalog,
                        viewMode: _viewMode,
                        scrollController: _listScrollController,
                        horizontalInset: horizontalInset,
                        onOpen: _openDetail,
                        onPageChanged: (int page) {
                          ref
                              .read(imageSetCatalogPageIndexProvider.notifier)
                              .setPage(widget.libraryId, page);
                        },
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) => Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: _MessageText(
                    l10n.imageSetListLoadFailed(appErrorMessage(error)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody({
    required this.libraryId,
    required this.catalog,
    required this.viewMode,
    required this.scrollController,
    required this.horizontalInset,
    required this.onOpen,
    required this.onPageChanged,
  });

  final String libraryId;
  final PagedImageSetCatalog catalog;
  final CatalogViewMode viewMode;
  final ScrollController scrollController;
  final double horizontalInset;
  final ValueChanged<ImageSet> onOpen;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final List<ImageSetCatalogItem> items = catalog.items;

    return Scrollbar(
      controller: scrollController,
      thumbVisibility: true,
      child: CustomScrollView(
        controller: scrollController,
        slivers: <Widget>[
          if (viewMode == CatalogViewMode.list)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: horizontalInset),
              sliver: SliverList.builder(
                itemCount: items.length,
                itemBuilder: (BuildContext context, int index) {
                  final ImageSetCatalogItem item = items[index];
                  final ImageSet set = item.imageSet;
                  final bool showGroupHeader =
                      index == 0 ||
                      items[index - 1].groupAuthorName != item.groupAuthorName;
                  final bool groupingActive = items.any(
                    (ImageSetCatalogItem e) => e.groupAuthorName != null,
                  );
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (groupingActive && showGroupHeader)
                        Padding(
                          padding: EdgeInsets.only(
                            top: theme.spacing.sm,
                            bottom: theme.spacing.xs,
                          ),
                          child: Text(
                            item.groupAuthorName == null
                                ? l10n.imageSetGroupUnassignedAuthor
                                : l10n.imageSetGroupAuthorLabel(
                                    item.groupAuthorName!,
                                  ),
                            style: theme.typeScale.titleSmall,
                          ),
                        ),
                      ListTile(
                        key: ValueKey<String>('imageSet-${set.imageSetId}'),
                        leading: SizedBox(
                          width: 48,
                          height: 48,
                          child: ImageSetCover(
                            libraryId: libraryId,
                            imageSetId: set.imageSetId,
                          ),
                        ),
                        title: Text(
                          set.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => onOpen(set),
                      ),
                    ],
                  );
                },
              ),
            )
          else
            CatalogGridSliver(
              itemCount: items.length,
              hasSubtitle: false,
              itemBuilder:
                  (BuildContext context, int index, CatalogGridLayout _) {
                    final ImageSet set = items[index].imageSet;
                    return ImageSetCard(
                      key: ValueKey<String>('imageSet-${set.imageSetId}'),
                      libraryId: libraryId,
                      imageSetId: set.imageSetId,
                      title: set.name,
                      onTap: () => onOpen(set),
                    );
                  },
            ),
          if (catalog.totalPages > 1)
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalInset,
                theme.spacing.md,
                horizontalInset,
                theme.spacing.lg,
              ),
              sliver: SliverToBoxAdapter(
                child: Pagination(
                  page: catalog.page,
                  totalPages: catalog.totalPages,
                  totalItems: catalog.totalCount,
                  onPageChanged: onPageChanged,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PageSizeButton extends StatelessWidget {
  const _PageSizeButton({
    required this.pageSize,
    required this.onPageSizeChanged,
  });

  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    return AnchoredMenu(
      position: M3EMenuAnchorPosition.bottomEnd,
      children: <M3EMenuNode>[
        for (final int option in kLibraryPageSizeOptions)
          M3EMenuSelectable(
            label: '$option',
            value: option,
            selected: option == pageSize,
            onPressed: () => onPageSizeChanged(option),
          ),
      ],
      anchorBuilder: (BuildContext context, VoidCallback open) {
        return M3EIconButton(
          icon: Icon(
            Symbols.grid_view,
            size: LibraryPageHeaderMetrics.actionIconSize,
            color: scheme.onSurfaceVariant,
          ),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: l10n.libraryPageSizeTooltip,
          semanticLabel: l10n.libraryPageSizeSemantic,
          onPressed: open,
        );
      },
    );
  }
}

class _MessageText extends StatelessWidget {
  const _MessageText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.typeScale.bodyMedium.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
