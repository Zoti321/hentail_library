import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_catalog_query.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_library_gates.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_copy_images_action.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_mutation_section.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_mutation_dialogs.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_facets.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_image.dart';
import 'package:hentai_library/features/image_set_library/domain/image_set_reader_entry.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_header.dart';
import 'package:hentai_library/features/image_set_library/presentation/patterns/metadata_edit/image_set_metadata_edit_present.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_row_grid_sliver.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submissions_section.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Client-side page size for the detail image grid (button pager).
const int kImageSetDetailImagePageSize = 24;

/// Image set 详情：顶栏（标题/张数）+ 无标题按行顶对齐图流；可进入工作区管理。
class ImageSetDetailPage extends ConsumerStatefulWidget {
  const ImageSetDetailPage({
    super.key,
    required this.libraryId,
    required this.imageSet,
    this.carrierShape = ImageSetCarrierShape.directory,
  });

  final String libraryId;
  final ImageSet imageSet;
  final ImageSetCarrierShape carrierShape;

  @override
  ConsumerState<ImageSetDetailPage> createState() => _ImageSetDetailPageState();
}

class _ImageSetDetailPageState extends ConsumerState<ImageSetDetailPage> {
  bool _manageMode = false;
  bool _copying = false;
  int _imagePage = 1;
  final ScrollController _browseScrollController = ScrollController();
  final Set<String> _selectedIds = <String>{};
  late ImageSet _imageSet;

  @override
  void dispose() {
    _browseScrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _imageSet = widget.imageSet;
  }

  bool get _canCopyIn {
    final ImageSetLibraryGates? gates = ref
        .watch(imageSetLibraryGatesProvider(widget.libraryId))
        .asData
        ?.value;
    return gates?.resourceMutation == true &&
        widget.carrierShape == ImageSetCarrierShape.directory;
  }

  Future<void> _copyImagesIn() async {
    if (_copying || !_canCopyIn) {
      return;
    }
    final List<String> paths = await pickImageSetCopySourcePaths(context);
    if (paths.isEmpty || !mounted) {
      return;
    }
    setState(() => _copying = true);
    try {
      await ref.read(imageSetCopyImagesInCommandProvider)(
        widget.libraryId,
        _imageSet.imageSetId,
        paths,
      );
    } finally {
      if (mounted) {
        setState(() => _copying = false);
      }
    }
  }

  ImageSetImagesKey get _imagesKey => (
    libraryId: widget.libraryId,
    imageSetId: _imageSet.imageSetId,
  );

  Future<void> _openMetadataEdit() async {
    final ImageSetFacets facets = await ref.read(
      imageSetFacetsQueryProvider,
    )(_imageSet.imageSetId);
    if (!mounted) {
      return;
    }
    final ImageSet? updated = await showImageSetMetadataEditSheet(
      context: context,
      imageSet: _imageSet,
      initialFacets: facets,
    );
    if (updated != null && mounted) {
      setState(() => _imageSet = updated);
    }
  }

  void _exitManage() {
    setState(() {
      _manageMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String imageId) {
    setState(() {
      if (_selectedIds.contains(imageId)) {
        _selectedIds.remove(imageId);
      } else {
        _selectedIds.add(imageId);
      }
    });
  }

  Future<void> _setExcluded(bool excluded) async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final List<String> ids = _selectedIds.toList(growable: false);
    await ref.read(imageSetSetImagesExcludedCommandProvider)(
      widget.libraryId,
      _imageSet.imageSetId,
      ids,
      excluded: excluded,
    );
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
  }

  Future<void> _persistReorder(List<ImageSetImage> ordered) async {
    await ref.read(imageSetReorderImagesCommandProvider)(
      widget.libraryId,
      _imageSet.imageSetId,
      ordered.map((ImageSetImage i) => i.imageSetImageId).toList(),
    );
  }

  Future<void> _deleteOnDisk() async {
    if (_selectedIds.isEmpty) {
      return;
    }
    final int count = _selectedIds.length;
    final bool confirmed = await confirmDeleteImageSetImagesOnDisk(
      context,
      count: count,
    );
    if (!confirmed || !mounted) {
      return;
    }
    final List<String> ids = _selectedIds.toList(growable: false);
    await ref.read(imageSetDeleteImagesOnDiskCommandProvider)(
      widget.libraryId,
      _imageSet.imageSetId,
      ids,
    );
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final AsyncValue<List<ImageSetImage>> images = ref.watch(
      _manageMode
          ? imageSetWorkspaceImagesProvider(_imagesKey)
          : imageSetImagesProvider(_imagesKey),
    );
    final String title = _imageSet.name;
    final AsyncValue<ImageSetLibraryGates> gates = ref.watch(
      imageSetLibraryGatesProvider(widget.libraryId),
    );
    final bool showDiskDelete = _manageMode &&
        gates.asData?.value.resourceMutation == true &&
        widget.carrierShape == ImageSetCarrierShape.directory;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalInset,
                vertical: theme.spacing.sm,
              ),
              child: _manageMode
                  ? _ManageToolbar(
                      selectedCount: _selectedIds.length,
                      hasSelection: _selectedIds.isNotEmpty,
                      allIds: images.asData?.value
                              .map((ImageSetImage i) => i.imageSetImageId)
                              .toList() ??
                          const <String>[],
                      showDeleteOnDisk: showDiskDelete,
                      onExit: _exitManage,
                      onExclude: () => _setExcluded(true),
                      onInclude: () => _setExcluded(false),
                      onDeleteOnDisk: _deleteOnDisk,
                      onSelectAll: (List<String> ids) =>
                          setState(() => _selectedIds.addAll(ids)),
                      onClearSelection: () =>
                          setState(_selectedIds.clear),
                    )
                  : Row(
                      children: <Widget>[
                        DetailHeaderBackButton(
                          onBack: () => Navigator.of(context).maybePop(),
                        ),
                        const Spacer(),
                        DetailHeaderIconButton(
                          icon: Symbols.edit,
                          tooltip: l10n.imageSetMetadataEditEnter,
                          semanticLabel: l10n.imageSetMetadataEditEnter,
                          onPressed: _openMetadataEdit,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        DetailHeaderIconButton(
                          icon: Symbols.tune,
                          tooltip: l10n.imageSetDetailManageEnter,
                          semanticLabel: l10n.imageSetDetailManageEnter,
                          onPressed: images.asData?.value.isNotEmpty == true
                              ? () => setState(() => _manageMode = true)
                              : null,
                          iconColor: theme.colorScheme.onSurfaceVariant,
                        ),
                        if (_canCopyIn) ...<Widget>[
                          SizedBox(width: theme.spacing.sm),
                          M3EButton(
                            key: const Key('imageSetDetailAdd'),
                            onPressed: _copying ? null : _copyImagesIn,
                            style: M3EButtonStyle.tonal,
                            label: _copying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(l10n.imageSetMutationCopyImages),
                          ),
                        ],
                      ],
                    ),
            ),
            Expanded(
              child: images.when(
                data: (List<ImageSetImage> list) => _manageMode
                    ? _ManageImageList(
                        libraryId: widget.libraryId,
                        imageSet: _imageSet,
                        images: list,
                        selectedIds: _selectedIds,
                        horizontalInset: horizontalInset,
                        onToggleSelection: _toggleSelection,
                        onReorder: _persistReorder,
                      )
                    : _buildBrowseScroll(
                        l10n: l10n,
                        theme: theme,
                        horizontalInset: horizontalInset,
                        title: title,
                        list: list,
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (Object error, StackTrace _) =>
                    Center(child: Text(appErrorMessage(error))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBrowseScroll({
    required AppLocalizations l10n,
    required M3EThemeData theme,
    required double horizontalInset,
    required String title,
    required List<ImageSetImage> list,
  }) {
    final int totalPages = list.isEmpty
        ? 1
        : ((list.length + kImageSetDetailImagePageSize - 1) ~/
              kImageSetDetailImagePageSize);
    final int page = _imagePage.clamp(1, totalPages);
    if (page != _imagePage) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() => _imagePage = page);
        }
      });
    }
    final int start = (page - 1) * kImageSetDetailImagePageSize;
    final List<ImageSetImage> pageItems = list
        .skip(start)
        .take(kImageSetDetailImagePageSize)
        .toList(growable: false);

    return CustomScrollView(
      controller: _browseScrollController,
      slivers: <Widget>[
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            horizontalInset,
            0,
            horizontalInset,
            theme.spacing.md,
          ),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ImageSetDetailHeader(
                  libraryId: widget.libraryId,
                  imageSetId: _imageSet.imageSetId,
                  title: title,
                  imageCount: list.length,
                ),
                SizedBox(height: theme.spacing.sm),
                ImageSetDetailMutationSection(
                  libraryId: widget.libraryId,
                  imageSet: _imageSet,
                  carrierShape: widget.carrierShape,
                ),
              ],
            ),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text(l10n.imageSetDetailEmpty)),
          )
        else ...<Widget>[
          ImageSetRowGridSliver(
            itemCount: pageItems.length,
            itemBuilder: (BuildContext context, int index) {
              final ImageSetImage image = pageItems[index];
              final int workspaceIndex = start + index;
              return ImageSetImageTile(
                key: ValueKey<String>(image.imageSetImageId),
                libraryId: widget.libraryId,
                image: image,
                onTap: () => ref.read(imageSetReaderEntryCommandProvider)(
                  ImageSetReaderEntry(
                    libraryId: widget.libraryId,
                    imageSetId: _imageSet.imageSetId,
                    imageSetImageId: image.imageSetImageId,
                    index: workspaceIndex,
                  ),
                ),
              );
            },
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              horizontalInset,
              theme.spacing.md,
              horizontalInset,
              theme.spacing.sm,
            ),
            sliver: SliverToBoxAdapter(
              child: Pagination(
                key: const Key('imageSetDetailPager'),
                page: page,
                totalPages: totalPages,
                totalItems: list.length,
                pageSize: kImageSetDetailImagePageSize,
                onPageChanged: (int next) {
                  setState(() => _imagePage = next);
                  if (_browseScrollController.hasClients) {
                    _browseScrollController.jumpTo(0);
                  }
                },
              ),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: ImageSetSubmissionsSection(
            libraryId: widget.libraryId,
            imageSet: _imageSet,
            horizontalInset: horizontalInset,
          ),
        ),
        SliverToBoxAdapter(child: SizedBox(height: theme.spacing.lg)),
      ],
    );
  }
}

class _ManageToolbar extends StatelessWidget {
  const _ManageToolbar({
    required this.selectedCount,
    required this.hasSelection,
    required this.allIds,
    required this.showDeleteOnDisk,
    required this.onExit,
    required this.onExclude,
    required this.onInclude,
    required this.onDeleteOnDisk,
    required this.onSelectAll,
    required this.onClearSelection,
  });

  final int selectedCount;
  final bool hasSelection;
  final List<String> allIds;
  final bool showDeleteOnDisk;
  final VoidCallback onExit;
  final VoidCallback onExclude;
  final VoidCallback onInclude;
  final VoidCallback onDeleteOnDisk;
  final void Function(List<String> ids) onSelectAll;
  final VoidCallback onClearSelection;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
  final TextTheme textTheme = Theme.of(context).textTheme;

    return PinnedToolbarChrome(
      child: Row(
        children: <Widget>[
          IconButton(
            icon: const Icon(Icons.close),
            tooltip: l10n.imageSetDetailManageExit,
            onPressed: onExit,
          ),
          TextButton(
            onPressed: hasSelection
                ? onClearSelection
                : allIds.isEmpty
                ? null
                : () => onSelectAll(allIds),
            child: Text(
              hasSelection
                  ? l10n.imageSetDetailManageClearSelection
                  : l10n.imageSetDetailManageSelectAll,
            ),
          ),
          TextButton(
            onPressed: hasSelection ? onExclude : null,
            child: Text(l10n.imageSetDetailManageExclude),
          ),
          TextButton(
            onPressed: hasSelection ? onInclude : null,
            child: Text(l10n.imageSetDetailManageInclude),
          ),
          if (showDeleteOnDisk)
            TextButton(
              onPressed: hasSelection ? onDeleteOnDisk : null,
              child: Text(
                l10n.imageSetMutationDeleteOnDiskAction,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          const Spacer(),
          Text(
            l10n.imageSetDetailManageSelectedCount(selectedCount),
            style: textTheme.titleSmall,
          ),
        ],
      ),
    );
  }
}

class _ManageImageList extends StatefulWidget {
  const _ManageImageList({
    required this.libraryId,
    required this.imageSet,
    required this.images,
    required this.selectedIds,
    required this.horizontalInset,
    required this.onToggleSelection,
    required this.onReorder,
  });

  final String libraryId;
  final ImageSet imageSet;
  final List<ImageSetImage> images;
  final Set<String> selectedIds;
  final double horizontalInset;
  final void Function(String imageId) onToggleSelection;
  final Future<void> Function(List<ImageSetImage> ordered) onReorder;

  @override
  State<_ManageImageList> createState() => _ManageImageListState();
}

class _ManageImageListState extends State<_ManageImageList> {
  late List<ImageSetImage> _ordered;

  @override
  void initState() {
    super.initState();
    _ordered = List<ImageSetImage>.of(widget.images);
  }

  @override
  void didUpdateWidget(covariant _ManageImageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameOrder(widget.images, _ordered)) {
      _ordered = List<ImageSetImage>.of(widget.images);
    }
  }

  bool _sameOrder(List<ImageSetImage> a, List<ImageSetImage> b) {
    if (a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i].imageSetImageId != b[i].imageSetImageId) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onReorder(int oldIndex, int newIndex) async {
    final List<ImageSetImage> next = applyReorder(
      _ordered,
      oldIndex,
      newIndex,
    );
    setState(() => _ordered = next);
    await widget.onReorder(next);
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);

    if (_ordered.isEmpty) {
      return Center(child: Text(l10n.imageSetDetailEmpty));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.fromLTRB(
            widget.horizontalInset,
            0,
            widget.horizontalInset,
            theme.spacing.md,
          ),
          child: ImageSetDetailHeader(
            libraryId: widget.libraryId,
            imageSetId: widget.imageSet.imageSetId,
            title: widget.imageSet.name,
            imageCount: _ordered.length,
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: EdgeInsets.symmetric(horizontal: widget.horizontalInset),
            itemCount: _ordered.length,
            onReorder: (int oldIndex, int newIndex) {
              // ignore: discarded_futures
              _onReorder(oldIndex, newIndex);
            },
            itemBuilder: (BuildContext context, int index) {
              final ImageSetImage image = _ordered[index];
              final bool selected = widget.selectedIds.contains(
                image.imageSetImageId,
              );
              return ReorderableDragStartListener(
                key: ValueKey<String>(image.imageSetImageId),
                index: index,
                child: Padding(
                  padding: EdgeInsets.only(bottom: theme.spacing.sm),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      ReorderExclude(
                        child: Icon(
                          Icons.drag_handle,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(width: theme.spacing.sm),
                      ImageSetImageTile(
                        libraryId: widget.libraryId,
                        image: image,
                        compactWidth: 72,
                        selectionMode: true,
                        selected: selected,
                        onTap: () =>
                            widget.onToggleSelection(image.imageSetImageId),
                      ),
                      SizedBox(width: theme.spacing.md),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: theme.spacing.xs),
                          child: Text(
                            image.name,
                            style: theme.typeScale.bodyMedium.copyWith(
                              color: image.excluded
                                  ? theme.colorScheme.onSurfaceVariant
                                  : theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}