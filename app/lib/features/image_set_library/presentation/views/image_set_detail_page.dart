import 'dart:async';

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
import 'package:hentai_library/features/image_set_library/domain/image_set_submission.dart';
import 'package:hentai_library/features/image_set_library/presentation/providers/image_set_library_providers.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_detail_header.dart';
import 'package:hentai_library/features/image_set_library/presentation/patterns/metadata_edit/image_set_metadata_edit_present.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_image_tile.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_row_grid_sliver.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submission_dialogs.dart';
import 'package:hentai_library/features/image_set_library/presentation/views/image_set_submissions_section.dart';
import 'package:hentai_library/l10n/app_localizations.dart';
import 'package:hentai_library/shared/application/errors/error_message.dart';
import 'package:hentai_library/shared/ui/l10n/app_localizations_x.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// Client-side page size for the detail image grid (button pager).
const int kImageSetDetailImagePageSize = 24;

/// imageId → indexes into [submissions] (one membership load, no N+1).
Map<String, List<int>> imageSetSubmissionAffinityByImageId(
  List<ImageSetSubmission> submissions,
) {
  final Map<String, List<int>> byImage = <String, List<int>>{};
  for (int i = 0; i < submissions.length; i++) {
    for (final String imageId in submissions[i].memberImageIds) {
      (byImage[imageId] ??= <int>[]).add(i);
    }
  }
  return byImage;
}

/// Image set 详情：顶栏 + 分页图流；长按进入选择，右键/次要点打开上下文菜单。
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
  bool _selectionMode = false;
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

  bool get _canMutateDisk {
    final ImageSetLibraryGates? gates = ref
        .watch(imageSetLibraryGatesProvider(widget.libraryId))
        .asData
        ?.value;
    return gates?.resourceMutation == true &&
        widget.carrierShape == ImageSetCarrierShape.directory;
  }

  bool get _canCopyIn => _canMutateDisk;

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

  void _exitSelection() {
    setState(() {
      _selectionMode = false;
      _selectedIds.clear();
    });
  }

  void _enterSelection(String imageId) {
    setState(() {
      _selectionMode = true;
      _selectedIds.add(imageId);
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

  List<String> _targetsFor(String imageId) {
    if (_selectedIds.contains(imageId) && _selectedIds.isNotEmpty) {
      return _selectedIds.toList(growable: false);
    }
    return <String>[imageId];
  }

  Future<void> _setExcluded(List<String> ids, {required bool excluded}) async {
    if (ids.isEmpty) {
      return;
    }
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

  Future<void> _deleteOnDisk(List<String> ids) async {
    if (ids.isEmpty || !_canMutateDisk) {
      return;
    }
    final bool confirmed = await confirmDeleteImageSetImagesOnDisk(
      context,
      count: ids.length,
    );
    if (!confirmed || !mounted) {
      return;
    }
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

  Future<void> _createSubmissionFrom(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final AppLocalizations l10n = context.l10n;
    final String? name = await showImageSetSubmissionNameDialog(
      context: context,
      title: l10n.imageSetSubmissionCreateTitle,
      fieldLabel: l10n.imageSetSubmissionNameLabel,
    );
    if (name == null || !mounted) {
      return;
    }
    final ImageSetSubmission created = await ref.read(
      imageSetCreateSubmissionCommandProvider,
    )(widget.libraryId, _imageSet.imageSetId, name);
    await ref.read(imageSetAddSubmissionMembersCommandProvider)(
      widget.libraryId,
      created.submissionId,
      ids,
    );
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
  }

  Future<void> _addToExistingSubmission(List<String> ids) async {
    if (ids.isEmpty) {
      return;
    }
    final List<ImageSetSubmission> submissions =
        await ref.read(imageSetSubmissionsProvider(_imagesKey).future);
    if (!mounted) {
      return;
    }
    if (submissions.isEmpty) {
      return;
    }
    final ImageSetSubmission? picked = await showImageSetPickSubmissionDialog(
      context: context,
      submissions: submissions,
    );
    if (picked == null || !mounted) {
      return;
    }
    await ref.read(imageSetAddSubmissionMembersCommandProvider)(
      widget.libraryId,
      picked.submissionId,
      ids,
    );
    if (!mounted) {
      return;
    }
    setState(_selectedIds.clear);
  }

  void _showImageContextMenu({
    required ImageSetImage image,
    required Offset globalPosition,
  }) {
    final AppLocalizations l10n = context.l10n;
    final List<String> targets = _targetsFor(image.imageSetImageId);
    final bool showDiskDelete = _canMutateDisk;
    unawaited(
      showPointerContextMenu<void>(
        context: context,
        globalPosition: globalPosition,
        children: <M3EMenuNode>[
          M3EMenuEntry(
            label: l10n.imageSetDetailContextSelect,
            onPressed: () => _enterSelection(image.imageSetImageId),
          ),
          M3EMenuEntry(
            label: l10n.imageSetDetailManageExclude,
            onPressed: () => unawaited(
              _setExcluded(targets, excluded: true),
            ),
          ),
          M3EMenuEntry(
            label: l10n.imageSetDetailManageInclude,
            onPressed: () => unawaited(
              _setExcluded(targets, excluded: false),
            ),
          ),
          M3EMenuEntry(
            label: l10n.imageSetDetailContextCreateSubmission,
            onPressed: () => unawaited(_createSubmissionFrom(targets)),
          ),
          M3EMenuEntry(
            label: l10n.imageSetDetailContextAddToSubmission,
            onPressed: () => unawaited(_addToExistingSubmission(targets)),
          ),
          if (showDiskDelete)
            M3EMenuEntry(
              label: l10n.imageSetMutationDeleteOnDiskAction,
              isDestructive: true,
              onPressed: () => unawaited(_deleteOnDisk(targets)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EThemeData theme = M3ETheme.of(context);
    final double horizontalInset = PageLayoutSpec.of(context).horizontalInset;
    final AsyncValue<List<ImageSetImage>> images = ref.watch(
      _selectionMode
          ? imageSetWorkspaceImagesProvider(_imagesKey)
          : imageSetImagesProvider(_imagesKey),
    );
    final String title = _imageSet.name;
    final bool showDiskDelete = _selectionMode && _canMutateDisk;
    final AsyncValue<List<ImageSetSubmission>> submissionsAsync = ref.watch(
      imageSetSubmissionsProvider(_imagesKey),
    );
    final Map<String, List<int>> affinityByImage =
        imageSetSubmissionAffinityByImageId(
      submissionsAsync.asData?.value ?? const <ImageSetSubmission>[],
    );

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
              child: _selectionMode
                  ? _SelectionToolbar(
                      selectedCount: _selectedIds.length,
                      hasSelection: _selectedIds.isNotEmpty,
                      allIds: images.asData?.value
                              .map((ImageSetImage i) => i.imageSetImageId)
                              .toList() ??
                          const <String>[],
                      showDeleteOnDisk: showDiskDelete,
                      onExit: _exitSelection,
                      onExclude: () => unawaited(
                        _setExcluded(
                          _selectedIds.toList(growable: false),
                          excluded: true,
                        ),
                      ),
                      onInclude: () => unawaited(
                        _setExcluded(
                          _selectedIds.toList(growable: false),
                          excluded: false,
                        ),
                      ),
                      onDeleteOnDisk: () => unawaited(
                        _deleteOnDisk(_selectedIds.toList(growable: false)),
                      ),
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
                data: (List<ImageSetImage> list) => _buildBrowseScroll(
                  l10n: l10n,
                  theme: theme,
                  horizontalInset: horizontalInset,
                  title: title,
                  list: list,
                  affinityByImage: affinityByImage,
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
    required Map<String, List<int>> affinityByImage,
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
              final bool selected = _selectedIds.contains(image.imageSetImageId);
              return ImageSetImageTile(
                key: ValueKey<String>(image.imageSetImageId),
                libraryId: widget.libraryId,
                image: image,
                selectionMode: _selectionMode,
                selected: selected,
                affinitySubmissionIndexes:
                    affinityByImage[image.imageSetImageId] ?? const <int>[],
                onTap: () {
                  if (_selectionMode) {
                    _toggleSelection(image.imageSetImageId);
                    return;
                  }
                  ref.read(imageSetReaderEntryCommandProvider)(
                    ImageSetReaderEntry(
                      libraryId: widget.libraryId,
                      imageSetId: _imageSet.imageSetId,
                      imageSetImageId: image.imageSetImageId,
                      index: workspaceIndex,
                    ),
                  );
                },
                onLongPress: () => _enterSelection(image.imageSetImageId),
                onSecondaryTapDown: (TapDownDetails details) =>
                    _showImageContextMenu(
                      image: image,
                      globalPosition: details.globalPosition,
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

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
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
