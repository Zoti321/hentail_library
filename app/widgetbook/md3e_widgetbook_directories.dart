import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_list_detail_adaptive_layout.dart';
import 'package:hentai_library/md3e/patterns/settings_grouped_list_pattern.dart';
import 'package:hentai_library/md3e/views/library_browse_preview_view.dart';
import 'package:hentai_library/md3e/widgets/md3e_filled_button.dart';
import 'package:widgetbook/widgetbook.dart';

import 'md3e_styles_widgetbook.dart';
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
              name: 'Md3eFilledButton',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Label',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Center(
                      child: Md3eFilledButton(
                        label: '继续',
                        onPressed: () {},
                      ),
                    ),
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
              name: 'SettingsGroupedListPattern',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Grouped sections',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Md3eSettingsGroupedListPattern(
                      sections:
                          <({String header, List<Md3eSettingsRow> rows})>[
                        (
                          header: '外观',
                          rows: <Md3eSettingsRow>[
                            const Md3eSettingsRow(
                              title: '主题',
                              subtitle: '跟随系统',
                            ),
                            Md3eSettingsRow(
                              title: '动态取色',
                              trailing: Switch(
                                value: false,
                                onChanged: (_) {},
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'ListDetailAdaptiveLayout',
              useCases: <WidgetbookUseCase>[
                WidgetbookUseCase(
                  name: 'Settings list + detail',
                  builder: (BuildContext context) => Md3eWidgetbookScope(
                    child: Md3eListDetailAdaptiveLayout(
                      listPane: ListView(
                        children: const <Widget>[
                          ListTile(title: Text('通用')),
                          ListTile(title: Text('外观')),
                        ],
                      ),
                      detailPane: const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text('详情 pane（宽屏并排）'),
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
              ],
            ),
          ],
        ),
      ],
    ),
  ];
}
