import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/views/library_browse_list_preview_view.dart';
import 'package:hentai_library/md3e/views/library_browse_preview_view.dart';
import 'package:hentai_library/md3e/widgets/md3e_comic_card.dart';
import 'package:hentai_library/md3e/widgets/md3e_comic_list_item.dart';
import 'package:hentai_library/md3e/patterns/md3e_comic_detail_meta_chip_row.dart';
import 'package:hentai_library/md3e/widgets/md3e_tag_input_field.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/md3e_desktop_title_bar.dart';
import 'package:hentai_library/md3e/widgets/md3e_navigation_rail.dart';
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
                  name: 'Default',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: SizedBox(
                        width: 160,
                        child: Md3eComicCard(
                          title: '深海图书馆',
                          subtitle: '128 页',
                          readProgress: kMd3eWidgetbookComicReadProgress,
                          cover: _demoCover(context),
                          onTap: () {},
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Elevated card states',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: <Widget>[
                          for (final Md3eComicCardVisualState state
                              in Md3eComicCardVisualState.values)
                            SizedBox(
                              width: 140,
                              child: Md3eComicCard(
                                title: _stateLabel(state),
                                subtitle: '96 页',
                                readProgress: kMd3eWidgetbookComicReadProgress,
                                visualState: state,
                                cover: _demoCover(context),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Selection mode',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: Wrap(
                        spacing: 24,
                        children: <Widget>[
                          SizedBox(
                            width: 160,
                            child: Md3eComicCard(
                              title: '未选中',
                              subtitle: '128 页',
                              readProgress: kMd3eWidgetbookComicReadProgress,
                              selectionMode: true,
                              selected: false,
                              cover: _demoCover(context),
                              onSelectionChanged: (_) {},
                            ),
                          ),
                          SizedBox(
                            width: 160,
                            child: Md3eComicCard(
                              title: '已选中',
                              subtitle: '128 页',
                              readProgress: kMd3eWidgetbookComicReadProgress,
                              selectionMode: true,
                              selected: true,
                              cover: _demoCover(context),
                              onSelectionChanged: (_) {},
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Md3eComicListItem',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: SizedBox(
                      width: 400,
                      child: Md3eComicListItem(
                        title: '深海图书馆',
                        author: '示例作者',
                        pageLabel: '128 页',
                        readProgress: kMd3eWidgetbookComicReadProgress,
                        moreMenuEntries: _demoComicListMoreMenu(),
                        cover: _demoCover(context),
                        onTap: () {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'List item states',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          for (final Md3eComicListItemVisualState state
                              in Md3eComicListItemVisualState.values)
                            Md3eComicListItem(
                              title: _listItemStateLabel(state),
                              author: '示例作者',
                              pageLabel: '96 页',
                              readProgress: kMd3eWidgetbookComicReadProgress,
                              moreMenuEntries: _demoComicListMoreMenu(),
                              visualState: state,
                              cover: _demoCover(context),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Selection mode',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: SizedBox(
                      width: 400,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Md3eComicListItem(
                            title: '未选中',
                            author: '示例作者',
                            pageLabel: '128 页',
                            readProgress: kMd3eWidgetbookComicReadProgress,
                            moreMenuEntries: _demoComicListMoreMenu(),
                            selectionMode: true,
                            selected: false,
                            cover: _demoCover(context),
                            onSelectionChanged: (_) {},
                          ),
                          Md3eComicListItem(
                            title: '已选中',
                            author: '示例作者',
                            pageLabel: '128 页',
                            readProgress: kMd3eWidgetbookComicReadProgress,
                            moreMenuEntries: _demoComicListMoreMenu(),
                            selectionMode: true,
                            selected: true,
                            cover: _demoCover(context),
                            onSelectionChanged: (_) {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'M3EChip',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Filter',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          M3EChip(
                            label: '未读',
                            type: M3EChipType.filter,
                            onPressed: () {},
                          ),
                          M3EChip(
                            label: '已收藏',
                            type: M3EChipType.filter,
                            selected: true,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Input',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: M3EChip(
                        label: '深海图书馆',
                        type: M3EChipType.input,
                        onPressed: () {},
                        onDeleted: () {},
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Assist & Suggestion',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        alignment: WrapAlignment.center,
                        children: <Widget>[
                          M3EChip(
                            label: '添加到标签',
                            type: M3EChipType.assist,
                            leading: Icon(
                              Icons.add,
                              size: 18,
                              color: M3ETheme.of(context).colorScheme.primary,
                            ),
                            onPressed: () {},
                          ),
                          M3EChip(
                            label: '深海图书馆',
                            type: M3EChipType.suggestion,
                            onPressed: () {},
                          ),
                        ],
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
                  name: 'Collapsed',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        height: 600,
                        child: _Md3eNavigationRailPreview(
                          initialExtended: false,
                        ),
                      ),
                    ),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Expanded',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        height: 600,
                        child: _Md3eNavigationRailPreview(
                          initialExtended: true,
                        ),
                      ),
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
          name: 'views',
          children: <WidgetbookNode>[
            WidgetbookComponent(
              name: 'LibraryBrowsePreview',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Fake grid',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eLibraryBrowsePreviewView(),
                  ),
                ),
                WidgetbookUseCase(
                  name: 'Fake list',
                  builder: (BuildContext context) => const Md3eWidgetbookScope(
                    child: Md3eLibraryBrowseListPreviewView(),
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

String _stateLabel(Md3eComicCardVisualState state) {
  switch (state) {
    case Md3eComicCardVisualState.normal:
      return 'Normal';
    case Md3eComicCardVisualState.hovered:
      return 'Hovered';
    case Md3eComicCardVisualState.focused:
      return 'Focused';
    case Md3eComicCardVisualState.pressed:
      return 'Pressed';
    case Md3eComicCardVisualState.dragged:
      return 'Dragged';
    case Md3eComicCardVisualState.disabled:
      return 'Disabled';
    case Md3eComicCardVisualState.selectionUnselected:
      return 'Selection off';
    case Md3eComicCardVisualState.selectionSelected:
      return 'Selection on';
  }
}

class _Md3eNavigationRailPreview extends StatefulWidget {
  const _Md3eNavigationRailPreview({required this.initialExtended});

  final bool initialExtended;

  @override
  State<_Md3eNavigationRailPreview> createState() =>
      _Md3eNavigationRailPreviewState();
}

class _Md3eNavigationRailPreviewState extends State<_Md3eNavigationRailPreview> {
  late bool _extended = widget.initialExtended;
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

String _listItemStateLabel(Md3eComicListItemVisualState state) {
  switch (state) {
    case Md3eComicListItemVisualState.normal:
      return 'Normal';
    case Md3eComicListItemVisualState.hovered:
      return 'Hovered';
    case Md3eComicListItemVisualState.focused:
      return 'Focused';
    case Md3eComicListItemVisualState.pressed:
      return 'Pressed';
    case Md3eComicListItemVisualState.disabled:
      return 'Disabled';
    case Md3eComicListItemVisualState.selectionUnselected:
      return 'Selection off';
    case Md3eComicListItemVisualState.selectionSelected:
      return 'Selection on';
  }
}
