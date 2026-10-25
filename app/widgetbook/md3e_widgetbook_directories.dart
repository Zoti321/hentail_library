import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_list_detail_adaptive_layout.dart';
import 'package:hentai_library/md3e/patterns/settings_grouped_list_pattern.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:hentai_library/md3e/views/library_browse_preview_view.dart';
import 'package:material_expressive/theme.dart';
import 'package:widgetbook/widgetbook.dart';

List<WidgetbookNode> buildMd3eWidgetbookDirectories() {
  return <WidgetbookNode>[
    WidgetbookFolder(
      name: 'MD3E (Lab)',
      children: <WidgetbookNode>[
        WidgetbookComponent(
          name: 'Theme',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Lab purple swatch',
              builder: (BuildContext context) => _Md3eWidgetbookScope(
                child: Builder(
                  builder: (BuildContext context) {
                    final ColorScheme scheme = Theme.of(context).colorScheme;
                    return Padding(
                      padding: const EdgeInsets.all(24),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: <Widget>[
                          _ColorChip(label: 'primary', color: scheme.primary),
                          _ColorChip(
                            label: 'secondary',
                            color: scheme.secondary,
                          ),
                          _ColorChip(
                            label: 'surface',
                            color: scheme.surface,
                          ),
                        ],
                      ),
                    );
                  },
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
              builder: (BuildContext context) => _Md3eWidgetbookScope(
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
        WidgetbookComponent(
          name: 'SettingsGroupedListPattern',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Grouped sections',
              builder: (BuildContext context) => _Md3eWidgetbookScope(
                child: Md3eSettingsGroupedListPattern(
                  sections: <({String header, List<Md3eSettingsRow> rows})>[
                    (
                      header: '外观',
                      rows: <Md3eSettingsRow>[
                        const Md3eSettingsRow(
                          title: '主题',
                          subtitle: '跟随系统',
                        ),
                        Md3eSettingsRow(
                          title: '动态取色',
                          trailing: Switch(value: false, onChanged: (_) {}),
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
          name: 'LibraryBrowsePreview',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Fake grid',
              builder: (BuildContext context) => const _Md3eWidgetbookScope(
                child: Md3eLibraryBrowsePreviewView(),
              ),
            ),
          ],
        ),
      ],
    ),
  ];
}

class _Md3eWidgetbookScope extends StatelessWidget {
  const _Md3eWidgetbookScope({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Md3eDynamicTheme(
      builder:
          (
            BuildContext context,
            ExpressiveThemeData expressive,
            ThemeData theme,
            ThemeData darkTheme,
          ) {
            final bool isDark =
                MediaQuery.platformBrightnessOf(context) == Brightness.dark;
            return Theme(
              data: isDark ? darkTheme : theme,
              child: child,
            );
          },
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 72,
          height: 48,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
