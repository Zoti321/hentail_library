import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_list_item.dart';
import 'package:hentai_library/md3e/layout/md3e_reading_history_list_layout.dart';
import 'package:hentai_library/md3e/widgets/history/md3e_reading_history_list_item.dart';
import 'package:hentai_library/md3e/patterns/comic_detail/md3e_comic_detail_metadata_tags_section.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell.dart';
import 'package:hentai_library/md3e/patterns/desktop/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/pages/md3e_history_browse_page.dart';
import 'package:hentai_library/md3e/pages/md3e_library_browse_page.dart';
import 'package:hentai_library/md3e/pages/md3e_management_browse_page.dart';
import 'package:hentai_library/md3e/pages/md3e_settings_page.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_detail_page.dart';
import 'package:hentai_library/md3e/pages/md3e_comic_metadata_edit_page.dart';
import 'package:hentai_library/md3e/pages/md3e_series_detail_page.dart';
import 'package:hentai_library/md3e/pages/md3e_series_metadata_edit_page.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_comic_metadata_edit_form.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_metadata_edit_navigation.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_draft.dart';
import 'package:hentai_library/md3e/patterns/metadata_edit/md3e_series_metadata_edit_form.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_filter_sort_side_sheet.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_management_create_interaction.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/management/md3e_managed_named_facet_ui.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/repositories/named_facet_management_repository.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_tag_input_field.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_widgetbook_desktop_gate.dart';
import 'md3e_widgetbook_scope.dart';

List<WidgetbookNode> buildMd3eWidgetbookDirectories() {
  return <WidgetbookNode>[
    WidgetbookFolder(
      name: 'MD3E (Lab)',
      children: <WidgetbookNode>[
        WidgetbookFolder(
          name: 'widgets',
          children: <WidgetbookNode>[
            WidgetbookComponent(
              name: 'Md3eComicCard',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Interactive',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: _md3eComicCardKnobsPreview(
                        context,
                        cover: _demoCover(context),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eSegmentedCapsuleBar',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Management facets',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Center(child: _Md3eSegmentedCapsuleBarPreview()),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eCatalogViewModeButtonGroup',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Grid · List toggle',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Center(child: _Md3eCatalogViewModeButtonGroupPreview()),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicListItem',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Interactive',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: _md3eComicListItemKnobsPreview(
                          context,
                          cover: _demoCover(context),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eReadingHistoryListItem',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Md3eReadingHistoryListLayout(
                          itemCount: 6,
                          itemBuilder: (BuildContext context, int index) {
                            return _Md3eReadingHistoryListItemPreview(
                              title: _demoReadingHistoryTitles[index % 3],
                              cover: _demoCover(context),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eDesktopTitleBar',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Collapsed rail · 1024',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Md3eWidgetbookDesktopExpandedGate(
                      child: Md3eDesktopTitleBar(
                        railWidth: Md3eNavigationRailMetrics.collapsedWidth,
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Expanded rail · 1440',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Md3eWidgetbookDesktopExpandedGate(
                      child: Md3eDesktopTitleBar(
                        railWidth: Md3eNavigationRailMetrics.expandedWidth,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eNavigationRail',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: '600h · menu toggles width',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        height: 600,
                        child: const _Md3eNavigationRailPreview(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3ePagination',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Interactive',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: _md3ePaginationKnobsPreview(context),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eTagInputField',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eTagInputFieldPreview(),
                  ),
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'patterns',
          children: <WidgetbookNode>[
            WidgetbookComponent(
              name: 'Md3eDesktopShell',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: '1024×768 · surface + surfaceContainer (M3 roles)',
                  builder: (BuildContext context) {
                    final M3EColorScheme scheme =
                        M3ETheme.of(context).colorScheme;
                    return Md3eWidgetbookScope(
                      child: Md3eWidgetbookDesktopExpandedGate(
                        child: Md3eDesktopShell(
                          width: Md3eBreakpoints.previewWidthExpanded,
                          height: 768,
                          initialRailExtended: false,
                          surfaceRoles:
                              Md3eDesktopShellSurfaceRoles.toneBased(scheme),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eLibraryFilterSortSideSheet',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Modal side sheet · viewport addon',
                  builder: (BuildContext context) =>
                      const Md3eWidgetbookScope(
                    child: _Md3eLibraryFilterSortSideSheetPreview(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicDetailMetadataTagsSection',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Tag section',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eComicDetailMetadataTagsSection(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicMetadataEditForm',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'From preview data',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: _Md3eComicMetadataEditFormPreview(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eSeriesMetadataEditForm',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'From preview data',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: _Md3eSeriesMetadataEditFormPreview(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'pages',
          children: <WidgetbookNode>[
            WidgetbookComponent(
              name: 'Md3eLibraryBrowsePage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: _Md3eLibraryBrowsePagePreview(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eManagementBrowsePage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: _Md3eManagementBrowsePagePreview(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eHistoryBrowsePage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: _Md3eHistoryBrowsePagePreview(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eSettingsPage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eSettingsPage(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicDetailPage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: _md3eComicDetailPageKnobsPreview(context),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eSeriesDetailPage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: _md3eSeriesDetailPageKnobsPreview(context),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicMetadataEditPage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eComicMetadataEditPage(),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eSeriesMetadataEditPage',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eSeriesMetadataEditPage(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}

/// Sample read progress on Md3eComicCard / Md3eComicListItem Widgetbook examples.
const double kMd3eWidgetbookComicReadProgress = 0.42;

const List<String> _demoReadingHistoryTitles = <String>[
  '只有神知道的世界',
  '葬送的芙莉莲',
  '迷宫饭',
];

class _Md3eReadingHistoryListItemPreview extends StatelessWidget {
  const _Md3eReadingHistoryListItemPreview({
    required this.cover,
    this.title = '只有神知道的世界',
    this.lastReadTime,
  });

  final Widget cover;
  final String title;
  final DateTime? lastReadTime;

  @override
  Widget build(BuildContext context) {
    final DateTime resolvedLastReadTime = lastReadTime ??
        DateTime.now().subtract(const Duration(hours: 2));
    return Md3eReadingHistoryListItem(
      title: title,
      cover: cover,
      currentPage: 42,
      totalPages: 208,
      lastReadTime: resolvedLastReadTime,
      onTap: () {},
      onContinueReading: () {},
      moreMenuEntries: _demoReadingHistoryMoreMenu(),
    );
  }
}

List<Md3eReadingHistoryMoreMenuEntry> _demoReadingHistoryMoreMenu() {
  return const <Md3eReadingHistoryMoreMenuEntry>[
    Md3eReadingHistoryMoreMenuEntry(label: '删除记录'),
    Md3eReadingHistoryMoreMenuEntry(label: '在资源管理器中显示'),
  ];
}

List<Md3eComicListMoreMenuEntry> _demoComicListMoreMenu() {
  return const <Md3eComicListMoreMenuEntry>[
    Md3eComicListMoreMenuEntry(label: '继续阅读'),
    Md3eComicListMoreMenuEntry(label: '编辑元数据'),
    Md3eComicListMoreMenuEntry(label: '在资源管理器中显示'),
    Md3eComicListMoreMenuEntry(label: '删除'),
  ];
}

Widget _demoCover(BuildContext context) {
  return ColoredBox(
    color: Theme.of(context).colorScheme.surfaceContainerHigh,
    child: Icon(
      Icons.image_outlined,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

Widget _md3eComicDetailPageKnobsPreview(BuildContext context) {
  final bool showAgeRestriction = context.knobs.boolean(
    label: '年龄限制',
    description: '控制摘要区 R18 年龄限制 chip 是否显示。',
    initialValue: true,
  );
  return Md3eComicDetailPage(
    entry: Md3eComicDetailPagePreviewData.sample().copyWith(
      showAgeRestrictionChip: showAgeRestriction,
    ),
    onEdit: () {
      showMd3eComicMetadataEdit(
        context: context,
        initialDraft: Md3eComicMetadataEditDraft.fromEntry(
          Md3eComicDetailPagePreviewData.sample().copyWith(
            showAgeRestrictionChip: showAgeRestriction,
          ),
        ),
      );
    },
  );
}

Widget _md3eSeriesDetailPageKnobsPreview(BuildContext context) {
  final bool showAgeRestriction = context.knobs.boolean(
    label: '年龄限制',
    description: '控制摘要区 R18 chip 是否显示。',
    initialValue: true,
  );
  final bool showMetadata = context.knobs.boolean(
    label: '元数据区',
    description: '控制 Parody / Author / Tag 等 chip 区块。',
    initialValue: true,
  );
  return Md3eSeriesDetailPage(
    entry: Md3eSeriesDetailPagePreviewData.sample().copyWith(
      showAgeRestrictionChip: showAgeRestriction,
      showMetadataBlock: showMetadata,
    ),
    onEdit: () {
      showMd3eSeriesMetadataEdit(
        context: context,
        initialDraft: Md3eSeriesMetadataEditDraft.fromEntry(
          Md3eSeriesDetailPagePreviewData.sample().copyWith(
            showAgeRestrictionChip: showAgeRestriction,
            showMetadataBlock: showMetadata,
          ),
        ),
      );
    },
  );
}

Widget _md3eComicCardKnobsPreview(
  BuildContext context, {
  required Widget cover,
}) {
  final bool disabled = context.knobs.boolean(
    label: '禁用',
    initialValue: false,
  );
  final bool selectionMode = disabled
      ? false
      : context.knobs.boolean(
          label: '选择模式',
          description: '开启后点击卡片或复选框切换选中。',
          initialValue: false,
        );

  return _Md3eComicCardKnobsHost(
    cover: cover,
    disabled: disabled,
    selectionMode: selectionMode,
  );
}

class _Md3eComicCardKnobsHost extends StatefulWidget {
  const _Md3eComicCardKnobsHost({
    required this.cover,
    required this.disabled,
    required this.selectionMode,
  });

  final Widget cover;
  final bool disabled;
  final bool selectionMode;

  @override
  State<_Md3eComicCardKnobsHost> createState() => _Md3eComicCardKnobsHostState();
}

class _Md3eComicCardKnobsHostState extends State<_Md3eComicCardKnobsHost> {
  bool _selected = false;

  @override
  void didUpdateWidget(covariant _Md3eComicCardKnobsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled || !widget.selectionMode) {
      _selected = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: Md3eComicCard(
        title: '深海图书馆',
        subtitle: '128 页',
        readProgress: kMd3eWidgetbookComicReadProgress,
        cover: widget.cover,
        enabled: !widget.disabled,
        selectionMode: widget.selectionMode,
        selected: _selected,
        onTap: widget.selectionMode ? null : () {},
        onSelectionChanged: widget.selectionMode
            ? (bool value) => setState(() => _selected = value)
            : null,
      ),
    );
  }
}

Widget _md3eComicListItemKnobsPreview(
  BuildContext context, {
  required Widget cover,
}) {
  final bool disabled = context.knobs.boolean(
    label: '禁用',
    initialValue: false,
  );
  final bool selectionMode = disabled
      ? false
      : context.knobs.boolean(
          label: '选择模式',
          description: '开启后点击行或复选框切换选中。',
          initialValue: false,
        );

  return _Md3eComicListItemKnobsHost(
    cover: cover,
    disabled: disabled,
    selectionMode: selectionMode,
  );
}

class _Md3eComicListItemKnobsHost extends StatefulWidget {
  const _Md3eComicListItemKnobsHost({
    required this.cover,
    required this.disabled,
    required this.selectionMode,
  });

  final Widget cover;
  final bool disabled;
  final bool selectionMode;

  @override
  State<_Md3eComicListItemKnobsHost> createState() =>
      _Md3eComicListItemKnobsHostState();
}

class _Md3eComicListItemKnobsHostState extends State<_Md3eComicListItemKnobsHost> {
  bool _selected = false;

  @override
  void didUpdateWidget(covariant _Md3eComicListItemKnobsHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.disabled || !widget.selectionMode) {
      _selected = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      child: Md3eComicListItem(
        title: '深海图书馆',
        author: '示例作者',
        pageLabel: '128 页',
        readProgress: kMd3eWidgetbookComicReadProgress,
        moreMenuEntries: _demoComicListMoreMenu(),
        cover: widget.cover,
        enabled: !widget.disabled,
        selectionMode: widget.selectionMode,
        selected: _selected,
        onTap: widget.selectionMode ? null : () {},
        onSelectionChanged: widget.selectionMode
            ? (bool value) => setState(() => _selected = value)
            : null,
      ),
    );
  }
}

const int _kMd3eWidgetbookPaginationTotalPages = 12;

Widget _md3ePaginationKnobsPreview(BuildContext context) {
  final int page = context.knobs.int.slider(
    label: '当前页',
    description: '紧凑/标准由 Viewport addon 窗口宽度决定（与漫画库页一致）。',
    initialValue: 5,
    min: 1,
    max: _kMd3eWidgetbookPaginationTotalPages,
    divisions: _kMd3eWidgetbookPaginationTotalPages - 1,
  );

  return Md3ePagination(
    page: page,
    totalPages: _kMd3eWidgetbookPaginationTotalPages,
    totalItems: 120,
    pageSize: 10,
    onPageChanged: (_) {},
  );
}

class _Md3eHistoryBrowsePagePreview extends StatefulWidget {
  const _Md3eHistoryBrowsePagePreview();

  @override
  State<_Md3eHistoryBrowsePagePreview> createState() =>
      _Md3eHistoryBrowsePagePreviewState();
}

class _Md3eHistoryBrowsePagePreviewState
    extends State<_Md3eHistoryBrowsePagePreview> {
  late List<Md3eHistoryBrowseEntry> _entries =
      Md3eHistoryBrowsePagePreviewData.sampleEntries();

  @override
  Widget build(BuildContext context) {
    return Md3eHistoryBrowsePage(
      entries: _entries,
      onClearAll: () => setState(() => _entries = <Md3eHistoryBrowseEntry>[]),
      itemBuilder: (BuildContext context, Md3eHistoryBrowseEntry entry) {
        final int index = _entries.indexOf(entry);
        final String title = Md3eHistoryBrowsePagePreviewData.sampleTitles[
            index % Md3eHistoryBrowsePagePreviewData.sampleTitles.length];
        return _Md3eReadingHistoryListItemPreview(
          title: title,
          cover: _demoCover(context),
          lastReadTime: entry.lastReadTime,
        );
      },
    );
  }
}

class _Md3eManagementBrowsePagePreview extends StatefulWidget {
  const _Md3eManagementBrowsePagePreview();

  @override
  State<_Md3eManagementBrowsePagePreview> createState() =>
      _Md3eManagementBrowsePagePreviewState();
}

class _Md3eManagementBrowsePagePreviewState
    extends State<_Md3eManagementBrowsePagePreview> {
  ManagedNamedFacetKind _facet = ManagedNamedFacetKind.author;
  late final Map<ManagedNamedFacetKind, List<String>> _labelsByFacet =
      <ManagedNamedFacetKind, List<String>>{
        for (final ManagedNamedFacetKind facet in kManagedNamedFacetTabOrder)
          facet: Md3eManagementBrowsePagePreviewData.sampleChipsFor(facet),
      };

  void _addEntity(String name) {
    final List<String> list = _labelsByFacet[_facet]!;
    if (list.contains(name)) {
      return;
    }
    setState(() => list.add(name));
  }

  @override
  Widget build(BuildContext context) {
    final String interactionKnob = context.knobs.list(
      label: '新建交互',
      options: <String>['自动', '移动端 Dialog', '桌面端内联'],
      initialOption: '自动',
    );
    final Md3eManagementCreateInteraction? interactionOverride =
        switch (interactionKnob) {
          '移动端 Dialog' => Md3eManagementCreateInteraction.mobileDialog,
          '桌面端内联' => Md3eManagementCreateInteraction.desktopInline,
          _ => null,
        };

    final List<String> chips = _labelsByFacet[_facet]!;

    return Md3eManagementBrowsePage(
      facet: _facet,
      facetCount: chips.length,
      chipLabels: chips,
      createInteractionOverride: interactionOverride,
      onEntityCreated: _addEntity,
      onFacetChanged: (ManagedNamedFacetKind value) {
        setState(() => _facet = value);
      },
    );
  }
}

class _Md3eLibraryBrowsePagePreview extends StatefulWidget {
  const _Md3eLibraryBrowsePagePreview();

  @override
  State<_Md3eLibraryBrowsePagePreview> createState() =>
      _Md3eLibraryBrowsePagePreviewState();
}

class _Md3eLibraryBrowsePagePreviewState
    extends State<_Md3eLibraryBrowsePagePreview> {
  LibraryDisplayTarget _target = LibraryDisplayTarget.comics;
  Md3eCatalogViewMode _viewMode = Md3eCatalogViewMode.grid;
  Md3eLibraryFilterSortState _filterSort = Md3eLibraryFilterSortState.defaults;
  int _pageSize = 50;
  int _page = 1;
  static const int _totalPages = 8;

  @override
  Widget build(BuildContext context) {
    return Md3eLibraryFilterSortDrawerHost(
      initialState: _filterSort,
      useRootNavigator: false,
      onStateChanged: (Md3eLibraryFilterSortState value) {
        setState(() => _filterSort = value);
      },
      body: Builder(
        builder: (BuildContext hostContext) {
          return Md3eLibraryBrowsePage(
            displayTarget: _target,
            viewMode: _viewMode,
            filterSortActive: _filterSort.isCustomized,
            page: _page,
            totalPages: _totalPages,
            onPageChanged: (int value) => setState(() => _page = value),
            pageSize: _pageSize,
            onPageSizeChanged: (int value) => setState(() => _pageSize = value),
            overflowMenuEntries: <M3EMenuEntry>[
              M3EMenuEntry(
                label: '刷新目录',
                leading: const Icon(Icons.refresh),
                onPressed: () {},
              ),
            ],
            onDisplayTargetChanged: (LibraryDisplayTarget value) {
              setState(() => _target = value);
            },
            onViewModeChanged: (Md3eCatalogViewMode value) {
              setState(() => _viewMode = value);
            },
            onFilterSort: () =>
                Md3eLibraryFilterSortDrawerHost.openDrawer(hostContext),
          );
        },
      ),
    );
  }
}

class _Md3eSegmentedCapsuleBarPreview extends StatefulWidget {
  const _Md3eSegmentedCapsuleBarPreview();

  @override
  State<_Md3eSegmentedCapsuleBarPreview> createState() =>
      _Md3eSegmentedCapsuleBarPreviewState();
}

class _Md3eSegmentedCapsuleBarPreviewState
    extends State<_Md3eSegmentedCapsuleBarPreview> {
  ManagedNamedFacetKind _facet = ManagedNamedFacetKind.author;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Md3eSegmentedCapsuleBar(
        segments: Md3eManagedNamedFacetUi.capsuleSegments(l10n),
        selectedIndex: Md3eManagedNamedFacetUi.indexOf(_facet),
        onSelected: (int index) {
          setState(() => _facet = Md3eManagedNamedFacetUi.facetAt(index));
        },
      ),
    );
  }
}

class _Md3eCatalogViewModeButtonGroupPreview extends StatefulWidget {
  const _Md3eCatalogViewModeButtonGroupPreview();

  @override
  State<_Md3eCatalogViewModeButtonGroupPreview> createState() =>
      _Md3eCatalogViewModeButtonGroupPreviewState();
}

class _Md3eCatalogViewModeButtonGroupPreviewState
    extends State<_Md3eCatalogViewModeButtonGroupPreview> {
  Md3eCatalogViewMode _mode = Md3eCatalogViewMode.grid;

  @override
  Widget build(BuildContext context) {
    return Md3eCatalogViewModeButtonGroup(
      mode: _mode,
      onModeChanged: (Md3eCatalogViewMode value) {
        setState(() => _mode = value);
      },
    );
  }
}

class _Md3eLibraryFilterSortSideSheetPreview extends StatefulWidget {
  const _Md3eLibraryFilterSortSideSheetPreview();

  @override
  State<_Md3eLibraryFilterSortSideSheetPreview> createState() =>
      _Md3eLibraryFilterSortSideSheetPreviewState();
}

class _Md3eLibraryFilterSortSideSheetPreviewState
    extends State<_Md3eLibraryFilterSortSideSheetPreview> {
  Md3eLibraryFilterSortState _state = Md3eLibraryFilterSortState.defaults;

  @override
  Widget build(BuildContext context) {
    return Md3eLibraryFilterSortDrawerHost(
      initialState: _state,
      openSideSheetOnMount: true,
      useRootNavigator: false,
      onStateChanged: (Md3eLibraryFilterSortState value) {
        setState(() => _state = value);
      },
      body: Builder(
        builder: (BuildContext hostContext) {
          return Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 24),
              child: M3EButton(
                onPressed: () =>
                    Md3eLibraryFilterSortDrawerHost.openDrawer(hostContext),
                style: M3EButtonStyle.filled,
                size: M3EButtonSize.sm,
                shape: M3EButtonShape.round,
                label: const Text('打开筛选与排序'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Md3eComicMetadataEditFormPreview extends StatefulWidget {
  @override
  State<_Md3eComicMetadataEditFormPreview> createState() =>
      _Md3eComicMetadataEditFormPreviewState();
}

class _Md3eComicMetadataEditFormPreviewState
    extends State<_Md3eComicMetadataEditFormPreview> {
  late Md3eComicMetadataEditDraft _draft =
      Md3eComicMetadataEditDraft.fromEntry(Md3eComicDetailPagePreviewData.sample());

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 640),
      child: Md3eComicMetadataEditForm(
        draft: _draft,
        onDraftChanged: (Md3eComicMetadataEditDraft value) {
          setState(() => _draft = value);
        },
      ),
    );
  }
}

class _Md3eSeriesMetadataEditFormPreview extends StatefulWidget {
  const _Md3eSeriesMetadataEditFormPreview();

  @override
  State<_Md3eSeriesMetadataEditFormPreview> createState() =>
      _Md3eSeriesMetadataEditFormPreviewState();
}

class _Md3eSeriesMetadataEditFormPreviewState
    extends State<_Md3eSeriesMetadataEditFormPreview> {
  late Md3eSeriesMetadataEditDraft _draft =
      Md3eSeriesMetadataEditDraft.fromEntry(
        Md3eSeriesDetailPagePreviewData.sample(),
      );

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Md3eSeriesMetadataEditForm(
        draft: _draft,
        onDraftChanged: (Md3eSeriesMetadataEditDraft value) {
          setState(() => _draft = value);
        },
      ),
    );
  }
}

class _Md3eNavigationRailPreview extends StatefulWidget {
  const _Md3eNavigationRailPreview();

  @override
  State<_Md3eNavigationRailPreview> createState() =>
      _Md3eNavigationRailPreviewState();
}

class _Md3eNavigationRailPreviewState extends State<_Md3eNavigationRailPreview> {
  bool _extended = false;
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Md3eNavigationRail(
      destinations: md3eDefaultNavigationRailDestinations(context.l10n),
      selectedIndex: _selectedIndex,
      extended: _extended,
      onMenuPressed: () => setState(() => _extended = !_extended),
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
    );
  }
}
