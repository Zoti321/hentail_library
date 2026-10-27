import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/widgets/actions/md3e_catalog_view_mode_button_group.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/catalog/md3e_comic_list_item.dart';
import 'package:hentai_library/md3e/patterns/md3e_comic_detail_meta_chip_row.dart';
import 'package:hentai_library/md3e/patterns/md3e_desktop_shell.dart';
import 'package:hentai_library/md3e/patterns/md3e_desktop_shell_surfaces.dart';
import 'package:hentai_library/md3e/layout/md3e_library_browse_page_metrics.dart';
import 'package:hentai_library/md3e/pages/md3e_library_browse_page.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_filter_sort_side_sheet.dart';
import 'package:hentai_library/md3e/patterns/md3e_management_named_facet.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/widgets/selection/md3e_segmented_capsule_bar.dart';
import 'package:material_3_expressive/foundations/foundations.dart';
import 'package:hentai_library/md3e/widgets/inputs/md3e_tag_input_field.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/desktop/md3e_navigation_rail.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_styles_widgetbook.dart';
import 'md3e_widgetbook_desktop_gate.dart';
import 'md3e_widgetbook_scope.dart';

List<WidgetbookNode> buildMd3eWidgetbookDirectories() {
  return <WidgetbookNode>[
    WidgetbookFolder(
      name: 'MD3E (Lab)',
      children: <WidgetbookNode>[
        ...buildMd3eStylesWidgetbookNodes(),
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
                    child: Center(
                      child: _md3eComicListItemKnobsPreview(
                        context,
                        cover: _demoCover(context),
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
              name: 'Md3eLibraryPageHeader',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Responsive · viewport addon',
                  builder: (BuildContext context) {
                    final double width = MediaQuery.sizeOf(context).width;
                    final Md3eWindowSizeClass sizeClass =
                        Md3eWindowSizeClass.fromWidth(width);
                    final double horizontal =
                        Md3eLibraryBrowsePageMetrics.contentHorizontalPadding(
                          sizeClass,
                        );
                    return Md3eWidgetbookScope(
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(
                            horizontal,
                            24,
                            horizontal,
                            0,
                          ),
                          child: const _Md3eLibraryPageHeaderPreview(),
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
              name: 'ComicDetailMetadataTags',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Tag section',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eComicDetailMetadataTagsSection(),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Single row',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Md3eComicDetailMetaChipRow(
                        label: '标签',
                        items: const <String>[
                          '奇幻',
                          '冒险',
                          '校园',
                        ],
                        onItemTap: (_) {},
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
          ],
        ),
      ],
    ),
  ];
}

/// Sample read progress on Md3eComicCard / Md3eComicListItem Widgetbook examples.
const double kMd3eWidgetbookComicReadProgress = 0.42;

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

class _Md3eLibraryBrowsePagePreview extends StatefulWidget {
  const _Md3eLibraryBrowsePagePreview();

  @override
  State<_Md3eLibraryBrowsePagePreview> createState() =>
      _Md3eLibraryBrowsePagePreviewState();
}

class _Md3eLibraryBrowsePagePreviewState
    extends State<_Md3eLibraryBrowsePagePreview> {
  Md3eLibraryDisplayTarget _target = Md3eLibraryDisplayTarget.comics;
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
            onDisplayTargetChanged: (Md3eLibraryDisplayTarget value) {
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
  Md3eManagementNamedFacet _facet = Md3eManagementNamedFacet.authors;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Md3eSegmentedCapsuleBar(
        segments: Md3eManagementNamedFacet.capsuleSegments(),
        selectedIndex: Md3eManagementNamedFacet.indexOf(_facet),
        onSelected: (int index) {
          setState(() => _facet = Md3eManagementNamedFacet.facetAt(index));
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

class _Md3eLibraryPageHeaderPreview extends StatefulWidget {
  const _Md3eLibraryPageHeaderPreview();

  @override
  State<_Md3eLibraryPageHeaderPreview> createState() =>
      _Md3eLibraryPageHeaderPreviewState();
}

class _Md3eLibraryPageHeaderPreviewState
    extends State<_Md3eLibraryPageHeaderPreview> {
  Md3eLibraryFilterSortState _filterSort = Md3eLibraryFilterSortState.defaults;
  int _pageSize = 50;

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
          return Md3eLibraryPageHeader(
            filterSortActive: _filterSort.isCustomized,
            pageSize: _pageSize,
            onPageSizeChanged: (int value) => setState(() => _pageSize = value),
            overflowMenuEntries: <M3EMenuEntry>[
              M3EMenuEntry(
                label: '刷新目录',
                leading: const Icon(Icons.refresh),
                onPressed: () {},
              ),
            ],
            onFilterSort: () => Md3eLibraryFilterSortDrawerHost.openDrawer(
              hostContext,
            ),
          );
        },
      ),
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
      destinations: md3eDefaultNavigationRailDestinations(),
      selectedIndex: _selectedIndex,
      extended: _extended,
      onMenuPressed: () => setState(() => _extended = !_extended),
      onDestinationSelected: (int index) =>
          setState(() => _selectedIndex = index),
    );
  }
}
