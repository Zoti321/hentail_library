import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/actions/ghost_button.dart';
import 'package:hentai_library/shared/ui/widgets/chrome/capsule_tab_bar.dart';
import 'package:hentai_library/shared/ui/widgets/element/card/catalog_cover_card_shell.dart';
import 'package:hentai_library/shared/ui/widgets/overlays/dialog/hentai_dialog.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';

List<WidgetbookNode> buildWidgetbookDirectories() {
  return <WidgetbookNode>[
    WidgetbookFolder(
      name: 'Tokens',
      children: <WidgetbookNode>[
        WidgetbookComponent(
          name: 'Spacing & Radius',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Swatch',
              builder: (BuildContext context) => const _TokenSpacingSwatch(),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'Typography',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Scale',
              builder: (BuildContext context) => const _TokenTypographyScale(),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'Shadows',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Presets',
              builder: (BuildContext context) => const _TokenShadowPresets(),
            ),
          ],
        ),
      ],
    ),
    WidgetbookFolder(
      name: 'Catalog',
      children: <WidgetbookNode>[
        WidgetbookComponent(
          name: 'GhostButton',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Icon + Text',
              builder: (BuildContext context) => GhostButton.iconText(
                icon: LucideIcons.settings,
                text: '设置',
                onPressed: () {},
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'HentaiDialog',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Confirm',
              builder: (BuildContext context) => Center(
                child: HentaiDialog(
                  title: '示例对话框',
                  content: const Text('用于预览 token 与阴影分层。'),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () {},
                      child: const Text('取消'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: () {},
                      child: const Text('确定'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'CatalogCoverCardShell',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Default',
              builder: (BuildContext context) => SizedBox(
                width: 160,
                child: CatalogCoverCardShell(
                  cover: ColoredBox(
                    color: context.hentai.imagePlaceholder,
                  ),
                  info: (bool _) => Text(
                    '示例标题',
                    style: TextStyle(
                      fontSize: context.tokens.text.labelXs,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'CapsuleTabBar',
          useCases: <WidgetbookUseCase>[
            WidgetbookUseCase(
              name: 'Three tabs',
              builder: (BuildContext context) => _CapsuleTabBarDemo(),
            ),
          ],
        ),
      ],
    ),
  ];
}

class _CapsuleTabBarDemo extends StatefulWidget {
  @override
  State<_CapsuleTabBarDemo> createState() => _CapsuleTabBarDemoState();
}

class _CapsuleTabBarDemoState extends State<_CapsuleTabBarDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return CapsuleTabBar(
      items: const <CapsuleTabItem>[
        CapsuleTabItem(label: '作者'),
        CapsuleTabItem(label: '标签'),
        CapsuleTabItem(label: '系列'),
      ],
      selectedIndex: _index,
      onSelected: (int value) => setState(() => _index = value),
    );
  }
}

class _TokenSpacingSwatch extends StatelessWidget {
  const _TokenSpacingSwatch();

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final AppSpacingTokens spacing = tokens.spacing;
    final AppRadiusTokens radius = tokens.radius;
    return Padding(
      padding: tokens.layout.contentAreaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _TokenBar(label: 'xs ${spacing.xs}', width: spacing.xs * 8),
          _TokenBar(label: 'md ${spacing.md}', width: spacing.md * 8),
          _TokenBar(label: 'xl ${spacing.xl}', width: spacing.xl * 8),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              _RadiusChip('xs', radius.xs),
              _RadiusChip('md', radius.md),
              _RadiusChip('pill', radius.pill),
            ],
          ),
        ],
      ),
    );
  }
}

class _TokenTypographyScale extends StatelessWidget {
  const _TokenTypographyScale();

  @override
  Widget build(BuildContext context) {
    final AppTextTokens text = context.tokens.text;
    return Padding(
      padding: context.tokens.layout.contentAreaPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('labelXs', style: TextStyle(fontSize: text.labelXs)),
          Text('bodyMd', style: TextStyle(fontSize: text.bodyMd)),
          Text('titleLg', style: TextStyle(fontSize: text.titleLg)),
        ],
      ),
    );
  }
}

class _TokenShadowPresets extends StatelessWidget {
  const _TokenShadowPresets();

  @override
  Widget build(BuildContext context) {
    final AppShadowTokens shadows = context.shadows;
    return Padding(
      padding: context.tokens.layout.contentAreaPadding,
      child: Row(
        children: <Widget>[
          _ShadowCard(shadows: shadows.catalogCard(highlighted: false)),
          const SizedBox(width: 24),
          _ShadowCard(shadows: shadows.catalogCard(highlighted: true)),
        ],
      ),
    );
  }
}

class _TokenBar extends StatelessWidget {
  const _TokenBar({required this.label, required this.width});

  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(width: 72, child: Text(label)),
          Container(
            width: width,
            height: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  const _RadiusChip(this.label, this.radius);

  final String label;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: <Widget>[
          Container(
            width: 48,
            height: 32,
            decoration: BoxDecoration(
              color: context.hentai.subtleTagBackground,
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: context.hentai.borderSubtle),
            ),
          ),
          Text(label),
        ],
      ),
    );
  }
}

class _ShadowCard extends StatelessWidget {
  const _ShadowCard({required this.shadows});

  final List<BoxShadow> shadows;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 120,
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(context.tokens.radius.xs),
        boxShadow: shadows,
      ),
    );
  }
}
